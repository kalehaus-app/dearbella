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
    @Published private(set) var isLoading = false

    private let client = TMDBClient.shared
    private let cacheKey = "tmdb.posterPaths"

    init() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([String: String].self, from: data) {
            posterPaths = cached
        }
    }

    func posterPath(filmID: String?) -> String? {
        guard let filmID else { return nil }
        return posterPaths[filmID]
    }

    /// Fetches posters for any curated films we don't already have cached.
    func loadPostersIfNeeded() async {
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

        posterPaths.merge(resolved) { _, new in new }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(posterPaths) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
