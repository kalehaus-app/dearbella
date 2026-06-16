import Foundation

/// Genres aren't a single film, so each genre tile borrows a representative
/// film's poster from the curated list. These are loose, illustrative matches.
/// Any genre without an entry falls back to a placeholder gradient.
enum GenreArt {
    private static let representative: [String: String] = [
        "horror": "the-shining",
        "comedy": "grand-budapest",
        "rom-com": "la-la-land",
        "sci-fi": "blade-runner",
        "indie": "lady-bird",
        "drama": "moonlight",
        "superhero": "mad-max",
        "action": "mad-max",
        "thriller": "get-out",
        "animation": "spirited-away",
        "documentary": "social-network",
        "fantasy": "spirited-away",
        "mystery": "parasite",
        "musical": "la-la-land",
        "crime": "pulp-fiction",
        "western": "django",
    ]

    static func filmID(for genreID: String) -> String? {
        representative[genreID]
    }
}
