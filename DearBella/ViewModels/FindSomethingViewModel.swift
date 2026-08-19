import Foundation

/// Runs one "tell me what you love → here's your next film" round.
///
/// Keeps every title it has offered this session, so "Try again" genuinely
/// tries again rather than circling the same two films.
@MainActor
final class FindSomethingViewModel: ObservableObject {
    @Published private(set) var pick: RecommendedFilm?
    @Published private(set) var isThinking = false
    @Published private(set) var error: String?

    private var alreadyOffered: [String] = []
    private let engine = RecommendationEngine.shared

    var hasPick: Bool { pick != nil }

    func find(taste: TasteProfile, context: TasteContext) async {
        guard !isThinking else { return }
        isThinking = true
        error = nil
        defer { isThinking = false }

        do {
            guard let film = try await engine.findSomething(
                taste: taste,
                context: context,
                exclude: alreadyOffered
            ) else {
                error = "Bella couldn't find one right now — try again."
                return
            }
            alreadyOffered.append(film.title)
            pick = film
        } catch {
            self.error = "Couldn't reach Bella right now. Check your connection and try again."
        }
    }

    /// Clears the pick but keeps the offered list, so reopening the flow
    /// doesn't start recommending the same films over again.
    func reset() {
        pick = nil
        error = nil
    }
}
