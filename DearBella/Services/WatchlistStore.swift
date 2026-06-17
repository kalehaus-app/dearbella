import Foundation

/// A film the user saved to their watchlist.
struct SavedFilm: Identifiable, Codable, Equatable {
    let id: String          // stable key (TMDB id, or title-year fallback)
    let title: String
    let year: Int?
    let posterPath: String?
    let tmdbID: Int?
    let genres: [String]

    init(
        id: String,
        title: String,
        year: Int?,
        posterPath: String?,
        tmdbID: Int?,
        genres: [String] = []
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.posterPath = posterPath
        self.tmdbID = tmdbID
        self.genres = genres
    }

    // Custom decode so films saved before `genres` existed still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        year = try c.decodeIfPresent(Int.self, forKey: .year)
        posterPath = try c.decodeIfPresent(String.self, forKey: .posterPath)
        tmdbID = try c.decodeIfPresent(Int.self, forKey: .tmdbID)
        genres = try c.decodeIfPresent([String].self, forKey: .genres) ?? []
    }
}

/// Holds the user's saved films and persists them on-device, the same way
/// `OnboardingStore` saves the genre/film picks.
@MainActor
final class WatchlistStore: ObservableObject {
    @Published private(set) var films: [SavedFilm] {
        didSet { persist() }
    }

    private let key = "watchlist.films"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([SavedFilm].self, from: data) {
            films = saved
        } else {
            films = []
        }
    }

    func isSaved(_ id: String) -> Bool {
        films.contains { $0.id == id }
    }

    func toggle(_ film: SavedFilm) {
        if let index = films.firstIndex(where: { $0.id == film.id }) {
            films.remove(at: index)
        } else {
            films.insert(film, at: 0)
        }
    }

    /// Removes a film from the list (used by the My List long-press menu).
    func remove(_ film: SavedFilm) {
        films.removeAll { $0.id == film.id }
    }

    /// Adds a film if it isn't already saved (used by swipe-right). Unlike
    /// `toggle`, this never removes an already-saved film.
    func save(_ film: SavedFilm) {
        guard !isSaved(film.id) else { return }
        films.insert(film, at: 0)
    }

    /// One-time, background backfill: for saved films missing genre data
    /// (saved before genres were tracked), look them up on TMDB and update the
    /// record. Only fetches films that lack genres; TMDB failures are skipped.
    func backfillGenresIfNeeded() async {
        let missing = films.filter { $0.genres.isEmpty }
        guard !missing.isEmpty else { return }

        let client = TMDBClient.shared
        var resolved: [String: [String]] = [:]
        for film in missing {
            let movie = await client.searchMovie(title: film.title, year: film.year)
            let genres = movie?.genreNames ?? []
            if !genres.isEmpty { resolved[film.id] = genres }
        }
        guard !resolved.isEmpty else { return }

        // Re-read `films` (it may have changed during the awaits) and apply
        // resolved genres in one assignment — a single persist + UI update.
        films = films.map { film in
            guard film.genres.isEmpty, let genres = resolved[film.id] else { return film }
            return SavedFilm(
                id: film.id,
                title: film.title,
                year: film.year,
                posterPath: film.posterPath,
                tmdbID: film.tmdbID,
                genres: genres
            )
        }
    }

    /// A "where to watch" link — the TMDB watch page when we have an id, else a
    /// Google search as a fallback.
    static func watchURL(for film: SavedFilm) -> URL {
        if let id = film.tmdbID {
            return URL(string: "https://www.themoviedb.org/movie/\(id)/watch")!
        }
        let query = "where to watch \(film.title) \(film.year.map(String.init) ?? "")"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.google.com/search?q=\(encoded)")!
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(films) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
