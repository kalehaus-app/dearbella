import Foundation

/// Records every swipe — likes and passes — by TMDB movie id, persisted
/// on-device. Used now to avoid showing the same film twice; the stored history
/// is also intended to improve recommendations in a future pass.
///
/// A shared singleton so the deck view model can use it without environment
/// plumbing at init time.
@MainActor
final class SwipeHistoryStore {
    static let shared = SwipeHistoryStore()

    private(set) var likedIDs: Set<Int>
    private(set) var passedIDs: Set<Int>

    private enum Keys {
        static let liked = "swipe.likedIDs"
        static let passed = "swipe.passedIDs"
    }

    init() {
        likedIDs = Set(UserDefaults.standard.array(forKey: Keys.liked) as? [Int] ?? [])
        passedIDs = Set(UserDefaults.standard.array(forKey: Keys.passed) as? [Int] ?? [])
    }

    /// Whether this film has already been swiped (liked or passed).
    func hasSeen(_ id: Int) -> Bool {
        likedIDs.contains(id) || passedIDs.contains(id)
    }

    func recordLike(_ id: Int) {
        likedIDs.insert(id)
        UserDefaults.standard.set(Array(likedIDs), forKey: Keys.liked)
    }

    func recordPass(_ id: Int) {
        passedIDs.insert(id)
        UserDefaults.standard.set(Array(passedIDs), forKey: Keys.passed)
    }
}
