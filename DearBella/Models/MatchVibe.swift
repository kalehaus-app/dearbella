import Foundation

/// What a Match deck was built from.
///
/// Two ways in, deliberately different in kind. A vibe is the thing only Bella
/// can answer, and it costs a Claude call. A genre is the familiar anchor —
/// TMDB can serve it instantly and for free, and someone who just wants horror
/// shouldn't wait on a model to agree that horror exists.
enum MatchSource: Identifiable, Hashable {
    case vibe(MatchVibe)
    case genre(id: Int, name: String)

    var id: String {
        switch self {
        case .vibe(let vibe):     return "vibe-\(vibe.id)"
        case .genre(let id, _):   return "genre-\(id)"
        }
    }

    /// What the deck header shows.
    var title: String {
        switch self {
        case .vibe(let vibe):     return vibe.title
        case .genre(_, let name): return name
        }
    }

    var vibe: MatchVibe? {
        if case .vibe(let vibe) = self { return vibe }
        return nil
    }
}

/// A way in to the Match deck: not a genre, but the kind of evening someone
/// wants to have.
///
/// Genres describe what a film contains; these describe what it does to you,
/// which is closer to how anyone actually decides. They come from the carousels
/// that already work as content — the same framing that stops a scroll is the
/// framing that starts a session.
///
/// `seeds` are hand-picked exemplars. They go to Claude as the calibration for
/// what the vibe means, so the deck inherits real editorial taste instead of
/// whatever a model free-associates from two words.
struct MatchVibe: Identifiable, Hashable {
    let id: String
    let title: String
    let tagline: String
    let symbol: String

    /// How the vibe is described to Claude.
    let brief: String

    /// Films that unmistakably are this vibe.
    let seeds: [String]

    static let all: [MatchVibe] = [
        MatchVibe(
            id: "warm-hug",
            title: "Like a warm hug",
            tagline: "Something kind. Nothing bad happens to anyone you like.",
            symbol: "cup.and.saucer.fill",
            brief: """
            Gentle, comforting films that feel like being looked after. Warm, \
            humane, low on cruelty. The kind of film you put on when you've had \
            a hard week and need the world to be soft for two hours.
            """,
            seeds: ["The Wild Robot", "Amélie", "About Time", "Kiki's Delivery Service", "Paddington 2"]
        ),
        MatchVibe(
            id: "beautiful-shots",
            title: "Beautiful to look at",
            tagline: "For the cinematography. Every frame a photograph.",
            symbol: "camera.aperture",
            brief: """
            Films celebrated for their cinematography, lighting and composition — \
            where the images alone are worth the runtime. Think of what a \
            director of photography would put on a reel.
            """,
            seeds: ["Blade Runner 2049", "In the Mood for Love", "2001: A Space Odyssey",
                    "Portrait of a Lady on Fire", "Days of Heaven"]
        ),
        MatchVibe(
            id: "mess-with-my-head",
            title: "Mess with my head",
            tagline: "Psychological, unsettling, still thinking about it at 2am.",
            symbol: "brain.head.profile",
            brief: """
            Psychological thrillers and unsettling character studies. Tense, \
            clever, morally uncomfortable — films that get under the skin and \
            stay there. Not gore; dread.
            """,
            seeds: ["Parasite", "Psycho", "The Silence of the Lambs", "Perfect Blue", "Vertigo"]
        ),
        MatchVibe(
            id: "watch-twice",
            title: "Watch it twice",
            tagline: "You'll miss half of it the first time. That's the point.",
            symbol: "arrow.triangle.2.circlepath",
            brief: """
            Films built to reward a second viewing — twists, structures or \
            details that reframe everything once you know the ending. Puzzle-box \
            storytelling, done well rather than for its own sake.
            """,
            seeds: ["Your Name.", "Pulp Fiction", "Memento", "Eternal Sunshine of the Spotless Mind",
                    "Twelve Monkeys"]
        ),
        MatchVibe(
            id: "wreck-me",
            title: "Wreck me",
            tagline: "You've been warned. Have something light lined up after.",
            symbol: "drop.fill",
            brief: """
            Devastating, emotionally heavy films that leave you hollowed out. \
            Great, but a lot. The kind people describe as "incredible, never \
            watching it again".
            """,
            seeds: ["Schindler's List", "Grave of the Fireflies", "Come and See",
                    "Requiem for a Dream", "Manchester by the Sea"]
        ),
        MatchVibe(
            id: "make-me-laugh",
            title: "Make me laugh",
            tagline: "No homework. Just funny.",
            symbol: "face.smiling.inverse",
            brief: """
            Genuinely funny films — sharp comedies, great comic performances, \
            films people quote. Not comedy-adjacent dramas; actually funny.
            """,
            seeds: ["Superbad", "The Grand Budapest Hotel", "Booksmart",
                    "What We Do in the Shadows", "Hunt for the Wilderpeople"]
        ),
        MatchVibe(
            id: "in-love",
            title: "Make me feel something",
            tagline: "Romance, longing, the ache. Happy ending optional.",
            symbol: "heart.fill",
            brief: """
            Romance and longing done properly — chemistry, yearning, films about \
            people falling for each other. Can end happily or not, but the \
            feeling has to be real rather than sentimental.
            """,
            seeds: ["Before Sunrise", "Call Me by Your Name", "Past Lives",
                    "Moonlight", "Brokeback Mountain"]
        ),
        MatchVibe(
            id: "surprise-me",
            title: "Surprise me",
            tagline: "Bella's choice. Trust her.",
            symbol: "sparkles",
            brief: """
            Anything excellent the user is unlikely to have seen — a great film \
            that isn't the obvious pick. Lean on their taste profile and reach \
            slightly outside it.
            """,
            seeds: []
        )
    ]
}
