import SwiftUI

/// The little progress dots: outlined circles, filled white for the active one.
/// Used by the intro carousel and the "Great picks!" reveal.
struct PageDots: View {
    let count: Int
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? Theme.textPrimary : Color.clear)
                    .overlay(Circle().stroke(Theme.textPrimary, lineWidth: 1.5))
                    .frame(width: 14, height: 14)
            }
        }
    }
}
