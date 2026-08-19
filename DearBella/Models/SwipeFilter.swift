import Foundation

/// What the Discover deck is currently dealing from.
///
/// Discover is for collecting, not deciding — you're filling your list, and the
/// filter just changes which pool you're filling it from. Deciding happens
/// later, in My List, from what you've already saved.
///
/// A short row on purpose. Nineteen genres is a menu to read rather than a
/// filter to tap, and the point of the row is to be glanceable while you're
/// mid-swipe. Everything here also comes straight from TMDB, so switching is
/// instant and free.
enum SwipeFilter: Identifiable, Hashable {
    /// Films chosen for this person specifically, from what they've saved,
    /// rated and reacted to. The one pool that isn't a TMDB query — it costs a
    /// model call, so it only loads when someone actually taps it.
    case forYou
    case everything
    case newReleases
    case genre(id: Int, name: String)

    var id: String {
        switch self {
        case .forYou:           return "for-you"
        case .everything:       return "all"
        case .newReleases:      return "new"
        case .genre(let id, _): return "genre-\(id)"
        }
    }

    var title: String {
        switch self {
        case .forYou:             return "For you"
        case .everything:         return "All"
        case .newReleases:        return "New releases"
        case .genre(_, let name): return name
        }
    }

    /// The genres everyone already has a feeling about, in the order people
    /// tend to reach for them.
    private static let everydayGenres: [(id: Int, name: String)] = [
        (28, "Action"),
        (35, "Comedy"),
        (27, "Horror"),
        (10749, "Romance"),
        (878, "Sci-Fi"),
        (53, "Thriller"),
    ]

    /// The filter row, in the order it's offered. "For you" leads because it's
    /// the reason to come back; the deck still *opens* on All, since a first
    /// run has nothing to personalize from and a spinner is a poor greeting.
    static var all: [SwipeFilter] {
        [.forYou, .everything, .newReleases]
            + everydayGenres.map { SwipeFilter.genre(id: $0.id, name: $0.name) }
    }
}
