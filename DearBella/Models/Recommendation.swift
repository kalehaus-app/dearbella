import Foundation

// MARK: - Taste context (personalization)

/// What we tell Claude about the user so picks feel personal.
///
/// The plain `genres`/`topFilms` pair is the baseline every screen has always
/// had. The fields below it are the learned signal: what they actually rated,
/// reacted to and wrote about once they'd seen a film. `init(films:)` derives
/// all of it from the saved library, so the more the list is used the sharper
/// the recommendations get.
struct TasteContext {
    let genres: [String]
    let topFilms: [String]

    /// Films they were enthusiastic about — the strongest positive signal.
    let loved: [String]
    /// Films they enjoyed without loving.
    let liked: [String]
    /// Films they actively didn't enjoy. Never recommend near these.
    let disliked: [String]
    /// Rated films rendered as "Title (Year) — 4.5/5".
    let ratings: [String]
    /// Their own words, as "Title: note". The most specific signal we have.
    let notes: [String]

    init(
        genres: [String],
        topFilms: [String],
        loved: [String] = [],
        liked: [String] = [],
        disliked: [String] = [],
        ratings: [String] = [],
        notes: [String] = []
    ) {
        self.genres = genres
        self.topFilms = topFilms
        self.loved = loved
        self.liked = liked
        self.disliked = disliked
        self.ratings = ratings
        self.notes = notes
    }

    /// Builds a full taste profile from the user's saved library, optionally
    /// seeded with what they picked during onboarding.
    ///
    /// Archived films are kept in the profile — deciding not to watch something
    /// still says something about taste — but a film the user disliked never
    /// contributes to their preferred genres. The onboarding picks come last in
    /// both lists: they're a stated preference, and what someone actually
    /// watched and rated is the better evidence.
    init(
        films: [SavedFilm],
        onboardingGenres: [String] = [],
        onboardingFilms: [String] = []
    ) {
        let opinionated = films.filter { $0.hasTasteSignal }

        loved = Self.titles(of: opinionated.filter { Self.sentiment(of: $0) == .loved })
        liked = Self.titles(of: opinionated.filter { Self.sentiment(of: $0) == .liked })
        disliked = Self.titles(of: opinionated.filter { Self.sentiment(of: $0) == .disliked })

        ratings = opinionated
            .filter { $0.rating != nil }
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            .prefix(20)
            .map { "\($0.displayTitle) — \(($0.rating ?? 0).formatted())/5" }

        notes = opinionated
            .filter { !$0.note.isEmpty }
            .prefix(15)
            .map { "\($0.title): \($0.note)" }

        // Genres, most-frequent first, counted only across films they didn't
        // dislike — otherwise a badly-received horror film argues for horror.
        let positive = films.filter { Self.sentiment(of: $0) != .disliked }
        var counts: [String: Int] = [:]
        for film in positive {
            for genre in film.genres { counts[genre, default: 0] += 1 }
        }
        let learnedGenres = counts
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(8)
            .map(\.key)
        genres = Self.merged(learnedGenres, onboardingGenres, limit: 12)

        // Films they felt strongest about lead, so a long list still opens
        // with its most informative entries.
        let ranked = films.sorted { Self.weight(of: $0) > Self.weight(of: $1) }
        let learnedFilms = Self.titles(of: Array(ranked.prefix(25)))
        topFilms = Self.merged(learnedFilms, onboardingFilms, limit: 30)
    }

    // MARK: Derivation

    private enum Sentiment {
        case loved, liked, neutral, disliked
    }

    /// Collapses a reaction and a star rating into one verdict. An explicit
    /// reaction wins, since it's the more deliberate act; otherwise the stars
    /// speak for themselves.
    private static func sentiment(of film: SavedFilm) -> Sentiment {
        if let reaction = film.reaction {
            switch reaction {
            case .loved: return .loved
            case .liked: return .liked
            case .disliked: return .disliked
            }
        }
        guard let rating = film.rating else { return .neutral }
        if rating >= 4.5 { return .loved }
        if rating >= 3.5 { return .liked }
        if rating <= 2.0 { return .disliked }
        return .neutral
    }

    /// Ordering weight for `topFilms` — strongest opinions first.
    private static func weight(of film: SavedFilm) -> Int {
        switch sentiment(of: film) {
        case .loved:    return 3
        case .liked:    return 2
        case .neutral:  return 1
        case .disliked: return 0
        }
    }

    private static func titles(of films: [SavedFilm]) -> [String] {
        films.map(\.displayTitle)
    }

    /// Appends `extra` after `primary`, dropping case-insensitive duplicates
    /// and capping the total so prompts don't grow without bound.
    private static func merged(_ primary: [String], _ extra: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        return (primary + extra)
            .filter { seen.insert($0.lowercased()).inserted }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Recommendation tool I/O

/// Decoded from Claude's `present_recommendations` tool call.
struct RecommendationToolInput: Decodable {
    let intro: String
    let films: [FilmSuggestion]
}

struct FilmSuggestion: Decodable {
    let title: String
    let year: Int?
    let reason: String
}

/// A suggestion after we've resolved it to real TMDB art.
struct RecommendedFilm: Identifiable {
    let id = UUID()
    let title: String
    let year: Int?
    let reason: String
    let posterPath: String?
    let tmdbID: Int?
    let genres: [String]

    /// Title with the year, when we have one — two films share a name often
    /// enough that the year is part of knowing which one was meant.
    var displayTitle: String {
        guard let year else { return title }
        return "\(title) (\(year))"
    }

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
}

/// The result of one recommendation round.
struct RecommendationResult {
    let intro: String
    let films: [RecommendedFilm]
}

/// Decoded from Claude's `present_taste_summary` tool call.
struct TasteSummaryToolInput: Decodable {
    let summary: String
}
