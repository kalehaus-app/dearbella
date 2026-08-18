import Foundation

// MARK: - Status

/// Where a film sits in the user's list.
///
/// A film starts on the `watchlist`, moves to `watched` once they've seen it
/// (rating or reacting moves it there automatically), and can be `archived`
/// when they've decided they're not going to watch it — archived films stay
/// saved, and still count as taste signal, but keep the main list manageable.
enum FilmStatus: String, Codable, CaseIterable, Identifiable {
    case watchlist
    case watched
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .watchlist: return "Want to Watch"
        case .watched:   return "Watched"
        case .archived:  return "Archived"
        }
    }

    /// Short form for the segmented picker, where space is tight.
    var shortTitle: String {
        switch self {
        case .watchlist: return "Watchlist"
        case .watched:   return "Watched"
        case .archived:  return "Archived"
        }
    }

    var symbol: String {
        switch self {
        case .watchlist: return "bookmark"
        case .watched:   return "checkmark.circle"
        case .archived:  return "archivebox"
        }
    }
}

// MARK: - Reaction

/// A one-tap gut reaction. Deliberately lower friction than a star rating —
/// most people won't rate every film, but they'll tap one of these, and it's
/// the strongest simple signal Bella has for what to recommend next.
enum FilmReaction: String, Codable, CaseIterable, Identifiable {
    case loved
    case liked
    case disliked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .loved:    return "Loved"
        case .liked:    return "Liked"
        case .disliked: return "Not for me"
        }
    }

    var symbol: String {
        switch self {
        case .loved:    return "heart.fill"
        case .liked:    return "hand.thumbsup.fill"
        case .disliked: return "hand.thumbsdown.fill"
        }
    }

    /// How this reads to Claude when we describe the user's taste.
    var tastePhrase: String {
        switch self {
        case .loved:    return "loved"
        case .liked:    return "liked"
        case .disliked: return "did not enjoy"
        }
    }
}

// MARK: - Saved film

/// A film in the user's list, plus everything they've told us about it.
///
/// The identity fields (`id`, `title`, …) are fixed at save time. The taste
/// fields below them are `var` because they're what the user edits over time,
/// and they're what feeds `TasteContext` so recommendations improve as the
/// list grows.
struct SavedFilm: Identifiable, Codable, Equatable {
    // Identity — set once, when the film is saved.
    let id: String          // stable key (TMDB id, or title-year fallback)
    let title: String
    let year: Int?
    let posterPath: String?
    let tmdbID: Int?
    let genres: [String]

    // Taste — edited by the user after the fact.
    var status: FilmStatus
    var rating: Double?         // 0.5...5.0, in half-star steps
    var reaction: FilmReaction?
    var note: String
    var watchedAt: Date?

    /// When the film was saved. Optional because films saved before this
    /// existed have no honest value to report.
    let addedAt: Date?

    init(
        id: String,
        title: String,
        year: Int?,
        posterPath: String?,
        tmdbID: Int?,
        genres: [String] = [],
        status: FilmStatus = .watchlist,
        rating: Double? = nil,
        reaction: FilmReaction? = nil,
        note: String = "",
        watchedAt: Date? = nil,
        addedAt: Date? = Date()
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.posterPath = posterPath
        self.tmdbID = tmdbID
        self.genres = genres
        self.status = status
        self.rating = rating
        self.reaction = reaction
        self.note = note
        self.watchedAt = watchedAt
        self.addedAt = addedAt
    }

    /// Decoding is lenient on every field added after the first release, so a
    /// list saved by an older build loads instead of being silently dropped.
    /// Only `id` and `title` are genuinely required.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        year = try c.decodeIfPresent(Int.self, forKey: .year)
        posterPath = try c.decodeIfPresent(String.self, forKey: .posterPath)
        tmdbID = try c.decodeIfPresent(Int.self, forKey: .tmdbID)
        genres = try c.decodeIfPresent([String].self, forKey: .genres) ?? []
        status = try c.decodeIfPresent(FilmStatus.self, forKey: .status) ?? .watchlist
        rating = try c.decodeIfPresent(Double.self, forKey: .rating)
        reaction = try c.decodeIfPresent(FilmReaction.self, forKey: .reaction)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        watchedAt = try c.decodeIfPresent(Date.self, forKey: .watchedAt)
        addedAt = try c.decodeIfPresent(Date.self, forKey: .addedAt)
    }

    // MARK: Derived

    var isWatched: Bool { status == .watched }

    /// Whether the user has told us anything about the film beyond saving it.
    var hasTasteSignal: Bool {
        rating != nil || reaction != nil || !note.isEmpty
    }

    var displayTitle: String {
        guard let year else { return title }
        return "\(title) (\(year))"
    }

    /// e.g. "★★★★½" — nil when unrated.
    var starsText: String? {
        guard let rating else { return nil }
        let full = Int(rating)
        let half = rating - Double(full) >= 0.5
        return String(repeating: "★", count: full) + (half ? "½" : "")
    }
}
