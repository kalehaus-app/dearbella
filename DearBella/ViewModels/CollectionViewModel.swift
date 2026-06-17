import Foundation

/// Loads films for the reusable collection screen. The source decides how:
/// TMDB "similar movies" for a reference film, or the Claude engine for a theme.
/// Loads once, only when the screen appears (i.e. on tile tap) — never on home
/// load — so no surprise API costs.
@MainActor
final class CollectionViewModel: ObservableObject {

    /// Where a collection's films come from.
    enum Source: Equatable {
        case similarTo(referenceFilm: String)   // free TMDB call
        case claudeTheme(String)                // paid Claude call
    }

    @Published private(set) var films: [RecommendedFilm] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private var loaded = false

    func load(source: Source) async {
        guard !loaded else { return }
        loaded = true

        isLoading = true
        error = nil
        defer { isLoading = false }

        switch source {
        case .similarTo(let referenceFilm):
            let movies = await TMDBClient.shared.similarMovies(toTitle: referenceFilm)
            films = movies.compactMap(Self.recommended(from:))
            if films.isEmpty {
                error = "Couldn't load this collection right now. Try again later."
            }

        case .claudeTheme(let theme):
            do {
                films = try await RecommendationEngine.shared.recommendForTheme(theme).films
                if films.isEmpty {
                    error = "Couldn't load this collection right now. Try again later."
                }
            } catch {
                self.error = "Couldn't reach DearBella right now. Check your connection (or that your Claude API key is set) and try again."
            }
        }
    }

    /// Maps a raw TMDB movie into the shared `RecommendedFilm` shape (blurb =
    /// the TMDB overview).
    private static func recommended(from movie: TMDBMovie) -> RecommendedFilm? {
        guard let title = movie.title else { return nil }
        let year = movie.releaseDate.flatMap { Int($0.prefix(4)) }
        return RecommendedFilm(
            title: title,
            year: year,
            reason: movie.overview ?? "",
            posterPath: movie.posterPath,
            tmdbID: movie.id,
            genres: movie.genreNames
        )
    }
}
