import SwiftUI

/// Generates a stable, good-looking gradient from a text seed.
///
/// Until real TMDB poster images arrive (Step 4), every genre/film card shows
/// one of these gradients instead of a photo. The same seed always produces
/// the same colors, so a given film looks consistent every launch.
enum PlaceholderArt {

    static func gradient(for seed: String) -> LinearGradient {
        let hash = stableHash(seed)
        let hueTop = Double(hash % 360) / 360.0
        let hueBottom = Double((hash / 7) % 360) / 360.0
        return LinearGradient(
            colors: [
                Color(hue: hueTop, saturation: 0.50, brightness: 0.58),
                Color(hue: hueBottom, saturation: 0.65, brightness: 0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A small, deterministic hash (djb2). Masked to stay positive so it never
    /// overflows when we take a remainder. Stable across launches, unlike
    /// Swift's built-in `hashValue`.
    private static func stableHash(_ string: String) -> Int {
        var hash = 5381
        for byte in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return hash & 0x7FFFFFFF
    }
}
