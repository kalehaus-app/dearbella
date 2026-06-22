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
    let genreIDs: [Int]?
    let runtime: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case genreIDs = "genre_ids"
    }

    /// Human-readable genre names resolved from TMDB's genre ids.
    var genreNames: [String] {
        (genreIDs ?? []).compactMap { TMDBGenre.name(for: $0) }
    }
}

/// Maps TMDB's fixed movie-genre ids to display names.
enum TMDBGenre {
    private static let names: [Int: String] = [
        28: "Action", 12: "Adventure", 16: "Animation", 35: "Comedy",
        80: "Crime", 99: "Documentary", 18: "Drama", 10751: "Family",
        14: "Fantasy", 36: "History", 27: "Horror", 10402: "Music",
        9648: "Mystery", 10749: "Romance", 878: "Sci-Fi", 10770: "TV Movie",
        53: "Thriller", 10752: "War", 37: "Western",
    ]

    static func name(for id: Int) -> String? { names[id] }

    /// Selectable movie genres (id + name), sorted by name — for the bracket
    /// genre picker. Excludes the non-feature "TV Movie" bucket.
    static var all: [(id: Int, name: String)] {
        names
            .filter { $0.value != "TV Movie" }
            .map { (id: $0.key, name: $0.value) }
            .sorted { $0.name < $1.name }
    }
}
