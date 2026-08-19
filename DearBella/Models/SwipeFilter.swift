import Foundation

/// What the Swipe deck is currently dealing from.
///
/// Swipe is for collecting, not deciding — you're filling your list, and the
/// filter just changes which pool you're filling it from. Deciding happens
/// later, in Match, from what you've already saved.
enum SwipeFilter: Identifiable, Hashable {
    case everything
    case newReleases
    case genre(id: Int, name: String)
    case mood(MatchVibe)

    var id: String {
        switch self {
        case .everything:       return "all"
        case .newReleases:      return "new"
        case .genre(let id, _): return "genre-\(id)"
        case .mood(let vibe):   return "mood-\(vibe.id)"
        }
    }

    var title: String {
        switch self {
        case .everything:         return "All"
        case .newReleases:        return "New releases"
        case .genre(_, let name): return name
        case .mood(let vibe):     return vibe.title
        }
    }

    var vibe: MatchVibe? {
        if case .mood(let vibe) = self { return vibe }
        return nil
    }

    /// The filter row, in the order it's offered. Everything first, because
    /// the deck opens on it and the row should read as "you are here".
    static var all: [SwipeFilter] {
        [.everything, .newReleases]
            + MatchVibe.all.map(SwipeFilter.mood)
            + TMDBGenre.all.map { SwipeFilter.genre(id: $0.id, name: $0.name) }
    }
}
