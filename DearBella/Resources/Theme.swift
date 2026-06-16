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

    // MARK: - Shape

    /// Standard corner radius for the rounded poster cards.
    static let cardCornerRadius: CGFloat = 16
}
