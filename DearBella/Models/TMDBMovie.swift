import Foundation

/// The envelope TMDB returns for a search query.
struct TMDBSearchResponse: Decodable {
    let results: [TMDBMovie]
}

/// A movie as returned by TMDB. Most fields are optional because the API
/// doesn't guarantee every record is complete. We map snake_case JSON keys to
/// Swift camelCase via `CodingKeys`.
struct TMDBMovie: Decodable, Identifiable, Sendable {
    let id: Int
    let title: String?
    let posterPath: String?
    let overview: String?
    let releaseDate: String?
    let voteAverage: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }
}
