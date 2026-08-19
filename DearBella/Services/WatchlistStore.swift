import Foundation

/// Holds the user's saved films and persists them on-device, the same way
/// `OnboardingStore` saves the genre/film picks.
///
/// `SavedFilm` itself lives in `Models/SavedFilm.swift`.
@MainActor
final class WatchlistStore: ObservableObject {
    @Published private(set) var films: [SavedFilm] {
        didSet { persist() }
    }

    private let key = "watchlist.films"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([SavedFilm].self, from: data) {
            films = saved
        } else {
            films = []
        }
    }

    // MARK: - Slices

    /// Films in one status, newest activity first. Watched films order by when
    /// they were watched; everything else keeps insertion order (newest saved
    /// first), which is what `insert(at: 0)` already gives us.
    func films(in status: FilmStatus) -> [SavedFilm] {
        let matching = films.filter { $0.status == status }
        guard status == .watched else { return matching }
        return matching.sorted {
            ($0.watchedAt ?? .distantPast) > ($1.watchedAt ?? .distantPast)
        }
    }

    func count(of status: FilmStatus) -> Int {
        films.reduce(into: 0) { total, film in
            if film.status == status { total += 1 }
        }
    }

    /// The current record for a film, so a detail sheet always renders live
    /// state rather than the copy it was handed when it opened.
    func film(id: String) -> SavedFilm? {
        films.first { $0.id == id }
    }

    // MARK: - Membership

    func isSaved(_ id: String) -> Bool {
        films.contains { $0.id == id }
    }

    func toggle(_ film: SavedFilm) {
        if let index = films.firstIndex(where: { $0.id == film.id }) {
            films.remove(at: index)
        } else {
            films.insert(film, at: 0)
        }
    }

    /// Removes a film from the list entirely.
    func remove(_ film: SavedFilm) {
        films.removeAll { $0.id == film.id }
    }

    /// Empties the list. Ratings and notes go with it, which is why the only
    /// caller confirms first.
    func removeAll() {
        films = []
    }

    /// Adds a film if it isn't already saved (used by swipe-right). Unlike
    /// `toggle`, this never removes an already-saved film.
    func save(_ film: SavedFilm) {
        guard !isSaved(film.id) else { return }
        films.insert(film, at: 0)
    }

    // MARK: - Taste

    func setStatus(_ status: FilmStatus, for id: String) {
        modify(id) { film in
            film.status = status
            // Reaching "watched" without an explicit date means they marked it
            // watched now; leaving "watched" clears the date so it can't linger.
            switch status {
            case .watched where film.watchedAt == nil: film.watchedAt = Date()
            case .watchlist, .archived: film.watchedAt = nil
            default: break
            }
        }
    }

    /// Sets or clears a star rating. Rating something implies you've seen it,
    /// so this promotes the film to `watched`.
    func setRating(_ rating: Double?, for id: String) {
        modify(id) { film in
            film.rating = rating
            if rating != nil { markWatched(&film) }
        }
    }

    /// Sets or clears the one-tap reaction. Like rating, this implies watched.
    func setReaction(_ reaction: FilmReaction?, for id: String) {
        modify(id) { film in
            film.reaction = reaction
            if reaction != nil { markWatched(&film) }
        }
    }

    func setNote(_ note: String, for id: String) {
        modify(id) { film in
            film.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Moves a film to watched without disturbing a date it already has.
    private func markWatched(_ film: inout SavedFilm) {
        guard film.status != .watched else { return }
        film.status = .watched
        if film.watchedAt == nil { film.watchedAt = Date() }
    }

    /// Applies an edit in place. One mutation of `films` means one persist and
    /// one UI update, however many fields the closure touches.
    private func modify(_ id: String, _ transform: (inout SavedFilm) -> Void) {
        guard let index = films.firstIndex(where: { $0.id == id }) else { return }
        var film = films[index]
        transform(&film)
        guard film != films[index] else { return }
        films[index] = film
    }

    // MARK: - Backfill

    /// Background repair pass for saved films with holes in their record.
    ///
    /// Two ways a film ends up incomplete. It may predate genre tracking, or —
    /// more visibly — it arrived from a recommendation whose title TMDB
    /// couldn't match, so it has no poster and sits in the grid as a bare
    /// gradient. `searchMovie` now tries plainer readings of a title, so a
    /// second attempt often succeeds where the first didn't; when it does, the
    /// decorated title is replaced by the real one too, since "Cassavetes' A
    /// Woman Under the Influence" is not what the film is called.
    ///
    /// Only films actually missing something are fetched. TMDB failures are
    /// skipped and simply retried next time.
    func backfillMissingMetadata() async {
        let incomplete = films.filter { $0.genres.isEmpty || $0.posterPath == nil }
        guard !incomplete.isEmpty else { return }

        let client = TMDBClient.shared
        var resolved: [String: TMDBMovie] = [:]
        for film in incomplete {
            if let movie = await client.searchMovie(title: film.title, year: film.year) {
                resolved[film.id] = movie
            }
        }
        guard !resolved.isEmpty else { return }

        // Re-read `films` (it may have changed during the awaits) and apply
        // everything in one assignment — a single persist + UI update.
        films = films.map { film in
            guard let movie = resolved[film.id] else { return film }

            let genres = film.genres.isEmpty ? movie.genreNames : film.genres
            let poster = film.posterPath ?? movie.posterPath

            // Only rewrite the title when the stored one needed cleaning up to
            // match at all — otherwise a legitimate alternate title would be
            // silently replaced by TMDB's preferred spelling.
            let wasDecorated = TMDBClient.titleCandidates(film.title).count > 1
            let title = (wasDecorated ? movie.title : nil) ?? film.title

            let updated = SavedFilm(
                id: film.id,
                title: title,
                year: film.year,
                posterPath: poster,
                tmdbID: film.tmdbID ?? movie.id,
                genres: genres,
                status: film.status,
                rating: film.rating,
                reaction: film.reaction,
                note: film.note,
                watchedAt: film.watchedAt,
                addedAt: film.addedAt
            )
            return updated == film ? film : updated
        }
    }

    // MARK: - Links

    /// A "where to watch" link — the TMDB watch page when we have an id, else a
    /// Google search as a fallback.
    static func watchURL(for film: SavedFilm) -> URL {
        if let id = film.tmdbID {
            return URL(string: "https://www.themoviedb.org/movie/\(id)/watch")!
        }
        let query = "where to watch \(film.title) \(film.year.map(String.init) ?? "")"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.google.com/search?q=\(encoded)")!
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(films) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
