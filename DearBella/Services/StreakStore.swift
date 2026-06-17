import Foundation

/// Tracks a daily-open streak: consecutive calendar days the user engaged with
/// the app. Increments once per new day, resets to 1 if a day was missed.
/// Persisted in UserDefaults. Shared singleton so the card can observe it.
@MainActor
final class StreakStore: ObservableObject {
    static let shared = StreakStore()

    @Published private(set) var count: Int

    private let countKey = "streak.count"
    private let dateKey = "streak.lastDate"

    init() {
        count = UserDefaults.standard.integer(forKey: countKey)
    }

    /// Call once when the user engages for the day (the dashboard appearing).
    func registerEngagement() {
        let today = Self.dayString(Date())
        let last = UserDefaults.standard.string(forKey: dateKey)
        guard last != today else { return }   // already counted today

        let yesterday = Self.dayString(
            Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )
        count = (last == yesterday) ? count + 1 : 1   // continue, else (miss/first) reset

        UserDefaults.standard.set(count, forKey: countKey)
        UserDefaults.standard.set(today, forKey: dateKey)
    }

    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
