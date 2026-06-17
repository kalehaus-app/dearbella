import Foundation

/// Helper for the share card: derives the films to feature, the dynamic month
/// label, and the per-rank title-size ramp. Kept separate from the visual
/// `ShareCardView` so each is easy to adjust.
enum ShareCardData {
    /// The films to feature: the user's list order, capped (default top 5).
    /// The ramp supports up to 8, but we default to 5 for now.
    static func topTitles(from films: [SavedFilm], max: Int = 5) -> [String] {
        Array(films.prefix(max)).map(\.title)
    }

    /// Current month name, uppercased, for the "MY <MONTH>," recap label.
    static var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: Date()).uppercased()
    }

    /// Per-rank title size (pt @1080), tuned so the block stays balanced for
    /// 5–8 films. For 5 films this reproduces the approved sizes
    /// (≈ 103 / 83 / 122 / 78 / 69 — the big/medium/biggest/medium/small rhythm).
    static func titleSize(for index: Int, count: Int) -> CGFloat {
        let base: CGFloat = count <= 5 ? 92 : (count <= 6 ? 80 : (count <= 7 ? 70 : 62))
        let rhythm: [CGFloat] = [1.12, 0.9, 1.33, 0.85, 0.75, 0.82, 0.78, 0.72]
        return base * (index < rhythm.count ? rhythm[index] : 0.75)
    }
}
