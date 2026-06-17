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

    /// Movies similar to a given title (TMDB's `movie/{id}/similar`). Searches
    /// for the reference title first, then fetches its similar list. Returns an
    /// empty array on any failure.
    func similarMovies(toTitle title: String) async -> [TMDBMovie] {
        guard let match = await searchMovie(title: title, year: nil),
              var components = URLComponents(string: baseURL)
        else { return [] }

        components.queryItems = [URLQueryItem(name: "path", value: "movie/\(match.id)/similar")]
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
    /// `nil` if there's no YouTube trailer / on failure. Prefers an official
    /// trailer, then any trailer, then any YouTube clip.
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
            let youTube = videos.filter { $0.site == "YouTube" }
            return youTube.first { $0.type == "Trailer" && ($0.official ?? false) }?.key
                ?? youTube.first { $0.type == "Trailer" }?.key
                ?? youTube.first?.key
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
