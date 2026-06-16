import SwiftUI

/// DearBella's typography system.
///
/// Two custom families (both free, SIL Open Font License):
/// - **DM Serif Display** — display/headline moments (the wordmark, section headers).
/// - **Inter** — all functional/body text (titles, blurbs, captions, labels, buttons).
///
/// The font FILES must be added to the app bundle and listed under `UIAppFonts`
/// in Info.plist (see `Resources/Fonts/README.md`). If a file is missing,
/// `Font.custom` falls back to the system font automatically — so the app still
/// builds and runs before the fonts are installed.
///
/// These styles are defined centrally so screens can adopt them later; this
/// step only creates the system and does not apply it anywhere.
enum DearBellaFont {
    // PostScript names — must match the installed .ttf files. If a weight
    // doesn't render after install, verify its PostScript name in Font Book
    // and adjust the matching constant here.
    static let serifRegular = "DMSerifDisplay-Regular"
    static let serifItalic = "DMSerifDisplay-Italic"
    static let interRegular = "Inter-Regular"
    static let interMedium = "Inter-Medium"
    static let interSemiBold = "Inter-SemiBold"
    static let interBold = "Inter-Bold"
}

extension Font {

    // MARK: - Builders

    /// DM Serif Display at an explicit size, scaling with Dynamic Type.
    static func dmSerif(_ size: CGFloat, relativeTo style: TextStyle = .largeTitle) -> Font {
        .custom(DearBellaFont.serifRegular, size: size, relativeTo: style)
    }

    /// Inter at an explicit size + weight, scaling with Dynamic Type.
    static func inter(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: TextStyle = .body
    ) -> Font {
        .custom(interFontName(for: weight), size: size, relativeTo: style)
    }

    private static func interFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return DearBellaFont.interBold
        case .semibold:             return DearBellaFont.interSemiBold
        case .medium:               return DearBellaFont.interMedium
        default:                    return DearBellaFont.interRegular
        }
    }

    // MARK: - Reusable named styles (adopt these across the app later)

    /// Big display moments — the "Dear Bella" wordmark, hero titles. (DM Serif Display, large)
    static let dearBellaTitle = Font.dmSerif(40, relativeTo: .largeTitle)

    /// Section headers — "Curated for you", "My List". (DM Serif Display, medium)
    static let dearBellaSectionHeader = Font.dmSerif(28, relativeTo: .title)

    /// Default body / UI text — movie titles, blurbs, messages. (Inter)
    static let dearBellaBody = Font.inter(17, weight: .regular, relativeTo: .body)

    /// Small supporting text — captions, metadata. (Inter, small)
    static let dearBellaCaption = Font.inter(13, weight: .regular, relativeTo: .caption)

    /// Button / pill labels. (Inter, semibold)
    static let dearBellaButton = Font.inter(17, weight: .semibold, relativeTo: .body)
}
