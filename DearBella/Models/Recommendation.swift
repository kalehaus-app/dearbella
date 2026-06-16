import Foundation

// MARK: - Taste context (personalization)

/// What we tell Claude about the user so picks feel personal.
struct TasteContext {
    let genres: [String]
    let topFilms: [String]
}

// MARK: - Recommendation tool I/O

/// Decoded from Claude's `present_recommendations` tool call.
struct RecommendationToolInput: Decodable {
    let intro: String
    let films: [FilmSuggestion]
}

struct FilmSuggestion: Decodable {
    let title: String
    let year: Int?
    let reason: String
}

/// A suggestion after we've resolved it to real TMDB art.
struct RecommendedFilm: Identifiable {
    let id = UUID()
    let title: String
    let year: Int?
    let reason: String
    let posterPath: String?
    let tmdbID: Int?

    var savedFilm: SavedFilm {
        SavedFilm(
            id: tmdbID.map(String.init) ?? "\(title)-\(year ?? 0)",
            title: title,
            year: year,
            posterPath: posterPath,
            tmdbID: tmdbID
        )
    }
}

/// The result of one recommendation round.
struct RecommendationResult {
    let intro: String
    let films: [RecommendedFilm]
}

// MARK: - Curated home cards tool I/O

struct CuratedToolInput: Decodable {
    let cards: [CuratedCardSuggestion]
}

struct CuratedCardSuggestion: Decodable {
    let title: String      // witty card caption
    let filmTitle: String  // representative film, for the poster
    let filmYear: Int?
}

/// A curated home card after resolving its representative film to a poster.
struct ResolvedCuratedCard: Identifiable, Codable {
    var id = UUID()
    let caption: String
    let posterPath: String?
}
