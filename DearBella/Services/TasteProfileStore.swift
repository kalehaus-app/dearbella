import Foundation

/// What the user has told Bella they love, in their own words.
///
/// Onboarding already collects genres and a top five, but those describe *what*
/// someone likes. The field that matters here is `why` — "the storyline and old
/// Hollywood" says more about what to recommend next than a genre list ever
/// does, and it's the one thing a recommender can actually reason with rather
/// than filter on.
///
/// Answers persist, so returning is one tap rather than the same form again.
struct TasteProfile: Codable, Equatable {
    var director = ""
    var favouriteFilm = ""
    var why = ""

    /// Enough to ask Bella with. Any one of the three will do: "more films
    /// like Heat", "anything by Céline Sciamma" and "something with beautiful
    /// lighting" are all complete requests on their own, and demanding a
    /// favourite film would turn two of them away.
    var isUsable: Bool {
        [favouriteFilm, director, why].contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var isEmpty: Bool {
        director.isEmpty && favouriteFilm.isEmpty && why.isEmpty
    }

    /// What Home shows in the field once there's something saved — their own
    /// words back, so the field reads as a standing request rather than an
    /// empty box they've already filled in once.
    var summary: String {
        [favouriteFilm, director, why]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

@MainActor
final class TasteProfileStore: ObservableObject {
    @Published var profile: TasteProfile {
        didSet { persist() }
    }

    private let key = "taste.profile"

    init() {
        profile = (UserDefaults.standard.data(forKey: key))
            .flatMap { try? JSONDecoder().decode(TasteProfile.self, from: $0) }
            ?? TasteProfile()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
