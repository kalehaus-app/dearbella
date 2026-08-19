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

    /// What marks a primary action or a selected state — pure white (#FFFFFF).
    ///
    /// Monochrome on purpose. The only colour on screen should be the film
    /// art: posters are already loud and every one of them is a different
    /// palette, so a bright interface colour competes with the content instead
    /// of framing it. White also sits a shade brighter than the cream used for
    /// body text, which is enough to read as interactive without adding a hue.
    static let highlight = Color.white

    /// Cream (#F4EFE6) — primary text color in the new design system.
    static let cream = Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)

    /// Near-black (#1A1A1A) — text on light/cyan fills.
    static let ink = Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)

    // MARK: - Spark

    /// The one place colour is allowed back in: the "For you" deck.
    ///
    /// Everything else stays monochrome so the posters carry the colour, and
    /// that rule is what makes this work — a single warm gradient in a black
    /// and white interface reads as "this one is different", which is exactly
    /// what a personalized deck is. It would be noise if the filter row were
    /// already six colours.
    ///
    /// Warm on purpose. Amber into coral is a cinema-marquee colour; a cool
    /// one would read as system chrome rather than as this app.
    static let sparkStart = Color(red: 255 / 255, green: 176 / 255, blue: 32 / 255)   // #FFB020
    static let sparkEnd = Color(red: 255 / 255, green: 61 / 255, blue: 127 / 255)     // #FF3D7F

    static var spark: LinearGradient {
        LinearGradient(
            colors: [sparkStart, sparkEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Shape

    /// Standard corner radius for the rounded poster cards.
    static let cardCornerRadius: CGFloat = 16
}
