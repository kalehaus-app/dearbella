import Foundation

/// Live search behind the film and person fields.
///
/// Debounced, because a request per keystroke is mostly wasted work and the
/// results flicker as they race each other. Each new query cancels the one
/// before it, so what's on screen always answers what's currently typed.
@MainActor
final class TasteSearchViewModel: ObservableObject {
    @Published private(set) var films: [TMDBMovie] = []
    @Published private(set) var people: [TMDBPerson] = []

    /// Films to show before anyone types — their own list first, then popular
    /// ones to fill the wall out.
    @Published private(set) var browse: [BrowseFilm] = []

    private var filmTask: Task<Void, Never>?
    private var peopleTask: Task<Void, Never>?
    private let tmdb = TMDBClient.shared

    /// Long enough that a fast typist makes one request instead of eight.
    private let debounce: UInt64 = 300_000_000

    /// Loads the poster wall once per session. Saved films lead: a film they
    /// already chose is the likeliest one they'd start from.
    func loadBrowse(saved: [SavedFilm]) async {
        guard browse.isEmpty else { return }

        var seen = Set<String>()
        var wall: [BrowseFilm] = []

        for film in saved where film.posterPath?.isEmpty == false {
            guard seen.insert(film.title.lowercased()).inserted else { continue }
            wall.append(BrowseFilm(id: film.id, title: film.title, posterPath: film.posterPath))
        }

        for movie in await tmdb.popularMovies(page: 1) {
            guard let title = movie.title, movie.posterPath?.isEmpty == false,
                  seen.insert(title.lowercased()).inserted else { continue }
            wall.append(BrowseFilm(id: String(movie.id), title: title, posterPath: movie.posterPath))
        }

        browse = Array(wall.prefix(18))
    }

    func searchFilms(_ query: String) {
        filmTask?.cancel()
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            films = []
            return
        }
        filmTask = Task {
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            let results = await tmdb.searchMovies(query: query)
            guard !Task.isCancelled else { return }
            films = results
        }
    }

    func searchPeople(_ query: String) {
        peopleTask?.cancel()
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            people = []
            return
        }
        peopleTask = Task {
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            let results = await tmdb.searchPeople(query: query)
            guard !Task.isCancelled else { return }
            people = results
        }
    }

    /// Called once a result is chosen, so the list doesn't sit there
    /// suggesting alternatives to a decision already made.
    func clearFilms() { filmTask?.cancel(); films = [] }
    func clearPeople() { peopleTask?.cancel(); people = [] }
}
