import Foundation

/// A film the user never wants suggested again.
struct HiddenFilm: Codable, Equatable, Identifiable {
    let tmdbID: Int?
    let title: String
    let year: Int?

    /// Matches `SavedFilm`'s key scheme, so the two stores agree on identity.
    var id: String {
        tmdbID.map(String.init) ?? "\(title)-\(year ?? 0)"
    }

    var displayTitle: String {
        guard let year else { return title }
        return "\(title) (\(year))"
    }
}

/// Films the user has explicitly dismissed — "don't show me this again".
///
/// Distinct from a swipe pass, which only stops a film reappearing in the swipe
/// deck: hiding also keeps a film out of the bracket and out of everything
/// Bella recommends. It's the escape hatch for the same handful of titles
/// coming back round.
///
/// A shared singleton so the deck and bracket view models can consult it
/// without environment plumbing at init time, and an `ObservableObject` so
/// views can react when something is hidden.
@MainActor
final class HiddenFilmsStore: ObservableObject {
    static let shared = HiddenFilmsStore()

    @Published private(set) var films: [HiddenFilm] {
        didSet {
            tmdbIDs = Set(films.compactMap(\.tmdbID))
            persist()
        }
    }

    /// Derived set for O(1) checks while filtering a deck or bracket pool.
    private var tmdbIDs: Set<Int>

    private let key = "hidden.films"

    init() {
        let saved = (UserDefaults.standard.data(forKey: key))
            .flatMap { try? JSONDecoder().decode([HiddenFilm].self, from: $0) } ?? []
        films = saved
        tmdbIDs = Set(saved.compactMap(\.tmdbID))
    }

    // MARK: - Queries

    func isHidden(id: Int) -> Bool {
        tmdbIDs.contains(id)
    }

    func isHidden(title: String) -> Bool {
        films.contains { $0.title.caseInsensitiveCompare(title) == .orderedSame }
    }

    /// Titles to pass to Claude's exclude list.
    var excludeTitles: [String] {
        films.map(\.displayTitle)
    }

    var isEmpty: Bool { films.isEmpty }

    // MARK: - Mutation

    func hide(tmdbID: Int?, title: String, year: Int?) {
        let film = HiddenFilm(tmdbID: tmdbID, title: title, year: year)
        guard !films.contains(where: { $0.id == film.id }) else { return }
        films.insert(film, at: 0)
    }

    func hide(_ movie: SwipeMovie) {
        hide(tmdbID: movie.id, title: movie.title, year: movie.year)
    }

    func hide(_ film: SavedFilm) {
        hide(tmdbID: film.tmdbID, title: film.title, year: film.year)
    }

    func unhide(_ film: HiddenFilm) {
        films.removeAll { $0.id == film.id }
    }

    func unhideAll() {
        films = []
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(films) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
