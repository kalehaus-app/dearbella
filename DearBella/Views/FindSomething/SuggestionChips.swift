import SwiftUI

/// Tappable answers under an input.
///
/// Typing on a phone is work, and the questions here are ones people know the
/// answer to but can't be bothered to spell out. A chip turns a sentence into a
/// tap; the field stays editable underneath for anything not on the list.
struct SuggestionChips: View {
    let options: [String]
    let onPick: (String) -> Void

    var body: some View {
        if !options.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button { onPick(option) } label: {
                            Text(option)
                                .font(.inter(13, weight: .medium))
                                .foregroundStyle(Theme.cream.opacity(0.85))
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Theme.cream.opacity(0.16), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

/// The stock answers offered under each question.
enum TasteSuggestions {

    /// Directors and actors people can name without thinking, spread across
    /// tastes so the row isn't eight versions of the same sensibility.
    static let names = [
        "Quentin Tarantino", "Greta Gerwig", "Christopher Nolan", "Wes Anderson",
        "Bong Joon-ho", "Denis Villeneuve", "Sofia Coppola", "Jordan Peele",
        "Hayao Miyazaki", "Martin Scorsese", "Ari Aster", "Céline Sciamma",
    ]

    /// The hard question made tappable.
    ///
    /// "What do you love about it" is the most valuable field and the one
    /// people leave blank, because articulating it is real work. These are the
    /// answers they'd give if asked out loud.
    static let reasons = [
        "The cinematography", "The dialogue", "The ending", "The performances",
        "The soundtrack", "The world it builds", "How it made me feel",
        "The atmosphere", "The pacing", "It's funny", "It's devastating",
    ]

    /// Films to offer, drawn from what this person has already told us —
    /// their onboarding picks first, then their list. A suggestion in their own
    /// taste beats a famous title they don't care about, and the fallback only
    /// appears when we know nothing yet.
    static func films(onboarding: [String], saved: [String]) -> [String] {
        var seen = Set<String>()
        let personal = (onboarding + saved).filter { seen.insert($0.lowercased()).inserted }
        guard personal.isEmpty else { return Array(personal.prefix(10)) }

        return ["Parasite", "Eternal Sunshine of the Spotless Mind", "Heat",
                "Lady Bird", "In the Mood for Love", "The Godfather"]
    }
}


extension String {
    /// Lower-cases only the first character, so chips read as one sentence
    /// when joined — "The dialogue, the ending" rather than "The dialogue, The
    /// ending" — without touching names like "It's" or proper nouns further in.
    var lowercasedFirst: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
}
