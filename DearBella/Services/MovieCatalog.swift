import SwiftUI

/// Resolves the app's curated films to real TMDB poster images and caches the
/// results on-device.
///
/// On launch we load whatever's cached (instant, works offline), then fetch
/// any still-missing posters in the background. Views read poster paths from
/// here via `posterPath(filmID:)`.
@MainActor
final class MovieCatalog: ObservableObject {
    /// Maps a film's `id` (e.g. "godfather") to its TMDB poster path.
    @Published private(set) var posterPaths: [String: String] = [:]
    /// Maps a director's `id` (e.g. "wes-anderson") to their TMDB profile path.
    @Published private(set) var profilePaths: [String: String] = [:]
    @Published private(set) var isLoading = false

    private let client = TMDBClient.shared
    private let cacheKey = "tmdb.posterPaths"
    private let profileCacheKey = "tmdb.profilePaths"

    init() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([String: String].self, from: data) {
            posterPaths = cached
        }
        if let data = UserDefaults.standard.data(forKey: profileCacheKey),
           let cached = try? JSONDecoder().decode([String: String].self, from: data) {
            profilePaths = cached
        }
    }

    func posterPath(filmID: String?) -> String? {
        guard let filmID else { return nil }
        return posterPaths[filmID]
    }

    func profilePath(directorID: String?) -> String? {
        guard let directorID else { return nil }
        return profilePaths[directorID]
    }

    /// Fetches posters for any curated films we don't already have cached.
    func loadPostersIfNeeded() async {
        #if DEBUG
        print("[DearBella] TMDB API key present: \(client.hasAPIKey)")
        #endif
        guard client.hasAPIKey else { return }

        let missing = SampleData.films.filter { posterPaths[$0.id] == nil }
        guard !missing.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        // Capture a local copy so the background tasks don't touch the actor.
        let client = client

        let resolved = await withTaskGroup(of: (String, String?).self) { group in
            for film in missing {
                group.addTask {
                    let movie = await client.searchMovie(title: film.title, year: film.year)
                    return (film.id, movie?.posterPath)
                }
            }
            var found: [String: String] = [:]
            for await (id, path) in group {
                if let path { found[id] = path }
            }
            return found
        }

        #if DEBUG
        print("[DearBella] Resolved \(resolved.count)/\(missing.count) posters from TMDB")
        #endif

        posterPaths.merge(resolved) { _, new in new }
        persist()
    }

    /// Fetches portraits for any curated directors we don't already have.
    ///
    /// TMDB's people search ranks by overall popularity rather than by role, so
    /// a director who also acts can come back as the second hit behind an
    /// actor who shares their name. Preferring a `Directing` match first fixes
    /// that; falling back to the top result keeps the rare unlabelled entry.
    func loadDirectorPortraitsIfNeeded() async {
        guard client.hasAPIKey else { return }

        let missing = SampleData.directors.filter { profilePaths[$0.id] == nil }
        guard !missing.isEmpty else { return }

        let client = client

        let resolved = await withTaskGroup(of: (String, String?).self) { group in
            for director in missing {
                group.addTask {
                    let people = await client.searchPeople(query: director.name, limit: 5)
                    let match = people.first { $0.knownForDepartment == "Directing" && $0.profilePath != nil }
                        ?? people.first { $0.profilePath != nil }
                    return (director.id, match?.profilePath)
                }
            }
            var found: [String: String] = [:]
            for await (id, path) in group {
                if let path { found[id] = path }
            }
            return found
        }

        profilePaths.merge(resolved) { _, new in new }
        persistProfiles()
    }

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(profilePaths) {
            UserDefaults.standard.set(data, forKey: profileCacheKey)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(posterPaths) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
