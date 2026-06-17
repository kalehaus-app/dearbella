import SwiftUI
import UIKit

/// Renders `ShareCardView` to a crisp 1080×1920 PNG-ready `UIImage` for sharing
/// and saving. Kept separate from the view and the sheet.
enum ShareCardRenderer {
    @MainActor
    static func render(films: [String]) -> UIImage? {
        let card = ShareCardView(films: films).frame(width: 1080, height: 1920)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0        // the card is already sized at 1080×1920
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
