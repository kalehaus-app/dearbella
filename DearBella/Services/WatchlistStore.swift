import Foundation

/// A film the user saved to their watchlist.
struct SavedFilm: Identifiable, Codable, Equatable {
    let id: String          // stable key (TMDB id, or title-year fallback)
    let title: String
    let year: Int?
    let posterPath: String?
    let tmdbID: Int?
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
