import Foundation

/// A movie shown on a swipe card. Built from a TMDB popular-list entry;
/// `runtime` is filled in lazily (the list endpoint doesn't include it).
struct SwipeMovie: Identifiable, Equatable {
    let id: Int                 // TMDB id
    let title: String
    let year: Int?
    let genres: [String]
    let rating: Double?         // TMDB vote average
    let overview: String
    let posterPath: String?
    var runtime: Int?

    /// For saving a liked film to the watchlist.
    var savedFilm: SavedFilm {
        SavedFilm(
            id: String(id),
            title: title,
            year: year,
            posterPath: posterPath,
            tmdbID: id,
            genres: genres
        )
    }

    init?(from movie: TMDBMovie) {
        guard let title = movie.title else { return nil }
        id = movie.id
        self.title = title
        year = movie.releaseDate.flatMap { Int($0.prefix(4)) }
        genres = movie.genreNames
        rating = movie.voteAverage
        overview = movie.overview ?? ""
        posterPath = movie.posterPath
        runtime = movie.runtime
    }
}
