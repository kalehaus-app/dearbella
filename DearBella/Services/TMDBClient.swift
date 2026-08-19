import Foundation

/// A thin wrapper around TMDB, routed through our Vercel proxy.
///
/// The proxy takes a `path` query param (the TMDB path without the leading
/// `/3/`, e.g. `search/movie`) plus the endpoint's other params, and adds the
/// API key server-side — so no key ships in the app. All calls are best-effort:
/// on any error they return `nil`/`[]` rather than throwing, so the UI can
/// quietly fall back to placeholder art.
struct TMDBClient: Sendable {
    static let shared = TMDBClient()

    private let session = URLSession.shared
    private let baseURL = "https://dearbella-proxy.vercel.app/api/tmdb"

    /// The proxy holds the key, so TMDB is always reachable from the app's side.
    var hasAPIKey: Bool { true }

    /// Searches for a movie and returns the best (first) match.
    func searchMovie(title: String, year: Int?) async -> TMDBMovie? {
        guard var components = URLComponents(string: baseURL) else { return nil }

        var queryItems = [
            URLQueryItem(name: "path", value: "search/movie"),
            URLQueryItem(name: "query", value: title),
            URLQueryItem(name: "include_adult", value: "false"),
        ]
        if let year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }
        components.queryItems = queryItems

        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode(TMDBSearchResponse.self, from: data).results.first
        } catch {
            return nil
        }
    }

    /// Recent releases for the Home "New & On Demand" row (`discover/movie`):
    /// films released in the last ~3 months, sorted by popularity, with enough
    /// votes to be real entries. Posterless results are filtered out so the row
    /// never shows blank cards. Returns `[]` on failure.
    func recentReleases(page: Int = 1) async -> [TMDBMovie] {
        guard var components = URLComponents(string: baseURL) else { return [] }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today) ?? today

        components.queryItems = [
            URLQueryItem(name: "path", value: "discover/movie"),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "vote_count.gte", value: "50"),
            URLQueryItem(name: "primary_release_date.gte", value: formatter.string(from: threeMonthsAgo)),
            URLQueryItem(name: "primary_release_date.lte", value: formatter.string(from: today)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        guard let url = components.url else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }
            return try JSONDecoder().decode(TMDBSearchResponse.self, from: data).results
                .filter { $0.posterPath?.isEmpty == false }
        } catch {
            return []
        }
    }

    /// A page of TMDB's popular movies (`movie/popular`). Returns `[]` on failure.
    func popularMovies(page: Int) async -> [TMDBMovie] {
        guard var components = URLComponents(string: baseURL) else { return [] }

        components.queryItems = [
            URLQueryItem(name: "path", value: "movie/popular"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false"),
        ]
        guard let url = components.url else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }
            return try JSONDecoder().decode(TMDBSearchResponse.self, from: data).results
        } catch {
            return []
        }
    }

    /// Popular movies in a genre (`discover/movie`, sorted by popularity,
    /// filtered to `genreID`). Returns `[]` on failure.
    func discoverMovies(genreID: Int, page: Int = 1) async -> [TMDBMovie] {
        guard var components = URLComponents(string: baseURL) else { return [] }

        components.queryItems = [
            URLQueryItem(name: "path", value: "discover/movie"),
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "vote_count.gte", value: "100"),
            URLQueryItem(name: "page", value: String(page)),
        ]
        guard let url = components.url else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }
            return try JSONDecoder().decode(TMDBSearchResponse.self, from: data).results
        } catch {
            return []
        }
    }

    /// A single movie's runtime in minutes (from `movie/{id}`). The popular
    /// list doesn't include runtime, so we fetch it lazily per surfaced card.
    func movieRuntime(id: Int) async -> Int? {
        guard var components = URLComponents(string: baseURL) else { return nil }

        components.queryItems = [URLQueryItem(name: "path", value: "movie/\(id)")]
        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            struct Detail: Decodable { let runtime: Int? }
            return try JSONDecoder().decode(Detail.self, from: data).runtime
        } catch {
            return nil
        }
    }

    /// The YouTube key for a movie's trailer (from `movie/{id}/videos`), or
    /// `nil` if there's no YouTube trailer / on failure. Considers only YouTube
    /// videos of type "Trailer", preferring an official one when flagged.
    func trailerYouTubeKey(id: Int) async -> String? {
        guard var components = URLComponents(string: baseURL) else { return nil }

        components.queryItems = [URLQueryItem(name: "path", value: "movie/\(id)/videos")]
        guard let url = components.url else { return nil }

        struct Response: Decodable { let results: [Video] }
        struct Video: Decodable {
            let key: String
            let site: String
            let type: String
            let official: Bool?
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            let videos = try JSONDecoder().decode(Response.self, from: data).results
            let trailers = videos.filter { $0.site == "YouTube" && $0.type == "Trailer" }
            return trailers.first { $0.official ?? false }?.key
                ?? trailers.first?.key
        } catch {
            return nil
        }
    }

    /// Builds a full image URL from a TMDB `poster_path` like "/abc.jpg".
    /// `size` is a TMDB bucket: w185, w342, w500, w780, original…
    static func posterURL(path: String?, size: String = "w500") -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }
}
