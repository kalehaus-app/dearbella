import Foundation

/// A thin wrapper around TMDB's REST API.
///
/// Uses the v3 "API Key" (the 32-character key from your TMDB account) passed
/// as the `api_key` query parameter. All calls are best-effort: on any error
/// or a missing key they return `nil` rather than throwing, so the UI can
/// quietly fall back to placeholder art.
struct TMDBClient: Sendable {
    static let shared = TMDBClient()

    private let session = URLSession.shared
    private let baseURL = "https://api.themoviedb.org/3"

    /// Whether a key was provided at build time.
    var hasAPIKey: Bool { !Secrets.tmdbAPIKey.isEmpty }

    /// Searches for a movie and returns the best (first) match.
    func searchMovie(title: String, year: Int?) async -> TMDBMovie? {
        guard hasAPIKey,
              var components = URLComponents(string: "\(baseURL)/search/movie")
        else { return nil }

        var queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.tmdbAPIKey),
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

    /// Movies similar to a given title (TMDB's `/movie/{id}/similar`). Searches
    /// for the reference title first, then fetches its similar list. Returns an
    /// empty array on any failure or missing key.
    func similarMovies(toTitle title: String) async -> [TMDBMovie] {
        guard hasAPIKey,
              let match = await searchMovie(title: title, year: nil),
              var components = URLComponents(string: "\(baseURL)/movie/\(match.id)/similar")
        else { return [] }

        components.queryItems = [URLQueryItem(name: "api_key", value: Secrets.tmdbAPIKey)]
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

    /// A page of TMDB's popular movies (`/movie/popular`). Returns `[]` on
    /// failure or missing key.
    func popularMovies(page: Int) async -> [TMDBMovie] {
        guard hasAPIKey, var components = URLComponents(string: "\(baseURL)/movie/popular") else {
            return []
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.tmdbAPIKey),
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

    /// A single movie's runtime in minutes (from `/movie/{id}`). The popular
    /// list doesn't include runtime, so we fetch it lazily per surfaced card.
    func movieRuntime(id: Int) async -> Int? {
        guard hasAPIKey, var components = URLComponents(string: "\(baseURL)/movie/\(id)") else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "api_key", value: Secrets.tmdbAPIKey)]
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

    /// The YouTube key for a movie's trailer (from `/movie/{id}/videos`), or
    /// `nil` if there's no YouTube trailer / on failure. Prefers an official
    /// trailer, then any trailer, then any YouTube clip.
    func trailerYouTubeKey(id: Int) async -> String? {
        guard hasAPIKey, var components = URLComponents(string: "\(baseURL)/movie/\(id)/videos") else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "api_key", value: Secrets.tmdbAPIKey)]
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
