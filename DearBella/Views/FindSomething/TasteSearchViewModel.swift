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

    private var filmTask: Task<Void, Never>?
    private var peopleTask: Task<Void, Never>?
    private let tmdb = TMDBClient.shared

    /// Long enough that a fast typist makes one request instead of eight.
    private let debounce: UInt64 = 300_000_000

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
