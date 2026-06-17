import Foundation

/// A cached daily pick from Bella. Codable so it can be stored for the day.
struct DailyPick: Codable, Equatable {
    let title: String
    let year: Int?
    let genres: [String]
    let reason: String
    let posterPath: String?
    let tmdbID: Int?

    /// For saving the pick to the watchlist.
    var savedFilm: SavedFilm {
        SavedFilm(
            id: tmdbID.map(String.init) ?? "\(title)-\(year ?? 0)",
            title: title,
            year: year,
            posterPath: posterPath,
            tmdbID: tmdbID,
            genres: genres
        )
    }

    init(from film: RecommendedFilm) {
        title = film.title
        year = film.year
        genres = film.genres
        reason = film.reason
        posterPath = film.posterPath
        tmdbID = film.tmdbID
    }
}

/// Decoded from Claude's `present_daily_pick` tool call.
struct DailyPickToolInput: Decodable {
    let title: String
    let year: Int?
    let reason: String
}
