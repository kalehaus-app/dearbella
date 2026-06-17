import SwiftUI

/// Central place for the app's colors, fonts, and shared visual constants.
///
/// Keeping these in one spot means when we refine the design later we change
/// it here once, not in every screen. The design is dark-themed and
/// image-heavy with rounded poster cards, so the values below reflect that.
enum Theme {

    // MARK: - Colors

    /// The app's background — true black (#000000) across the main surfaces.
    static let background = Color.black

    /// Slightly lifted surface color for cards sitting on the background.
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.12)

    /// Primary text color (high contrast on the dark background).
    static let textPrimary = Color.white

    /// Secondary text color for captions and supporting copy.
    static let textSecondary = Color.white.opacity(0.6)

    /// The signature DearBella red, taken from the splash "clapperboard".
    static let accent = Color(red: 0.95, green: 0.20, blue: 0.18)

    /// Cyan accent (#6ADFFF) — selected tab + My List accents.
    static let cyan = Color(red: 106 / 255, green: 223 / 255, blue: 255 / 255)

    /// Cream (#F4EFE6) — primary text color in the new design system.
    static let cream = Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)

    /// Near-black (#1A1A1A) — text on light/cyan fills.
    static let ink = Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)

    // MARK: - Shape

    /// Standard corner radius for the rounded poster cards.
    static let cardCornerRadius: CGFloat = 16
}
