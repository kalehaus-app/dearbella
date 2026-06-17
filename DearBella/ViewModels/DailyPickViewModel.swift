import Foundation

/// Produces Bella's one pick per calendar day and caches it, so the dashboard
/// doesn't make a paid Claude call on every open. The pick persists for the day
/// until the user taps "Not tonight," which fetches a different one and replaces
/// the cached pick (excluding what's already been shown today).
@MainActor
final class DailyPickViewModel: ObservableObject {
    @Published private(set) var pick: DailyPick?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let engine = RecommendationEngine.shared
    private var shownTodayTitles: [String] = []

    private let pickKey = "dailyPick.pick"
    private let dateKey = "dailyPick.date"
    private let shownKey = "dailyPick.shownTitles"

    init() {
        // Restore today's cached pick (if it's still the same day).
        if UserDefaults.standard.string(forKey: dateKey) == Self.todayString(),
           let data = UserDefaults.standard.data(forKey: pickKey),
           let cached = try? JSONDecoder().decode(DailyPick.self, from: data) {
            pick = cached
            shownTodayTitles = UserDefaults.standard.stringArray(forKey: shownKey) ?? []
        }
    }

    /// Generates today's pick only if there isn't one cached for today.
    func loadIfNeeded(context: TasteContext) async {
        guard pick == nil, !isLoading else { return }
        await generate(context: context)
    }

    /// Fetches a different pick and replaces today's cached one.
    func notTonight(context: TasteContext) async {
        guard !isLoading else { return }
        await generate(context: context)
    }

    private func generate(context: TasteContext) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            guard let film = try await engine.dailyPick(context: context, exclude: shownTodayTitles) else {
                error = "Bella couldn't find a pick right now — try again."
                return
            }
            let dailyPick = DailyPick(from: film)
            pick = dailyPick
            shownTodayTitles.append(dailyPick.title)
            persist()
        } catch {
            self.error = "Couldn't reach Bella right now. Check your connection (or that your Claude API key is set)."
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(pick) {
            UserDefaults.standard.set(data, forKey: pickKey)
        }
        UserDefaults.standard.set(Self.todayString(), forKey: dateKey)
        UserDefaults.standard.set(shownTodayTitles, forKey: shownKey)
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
