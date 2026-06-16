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

    /// Builds a full image URL from a TMDB `poster_path` like "/abc.jpg".
    /// `size` is a TMDB bucket: w185, w342, w500, w780, original…
    static func posterURL(path: String?, size: String = "w500") -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }
}
