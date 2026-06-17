import SwiftUI

/// Placeholder for the future "Swipe" feature — the tab slot is in place now.
struct SwipePlaceholderView: View {
    /// Cream (#F4EFE6) — the design's text color.
    private let cream = Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(cream.opacity(0.5))
                Text("Swipe")
                    .font(.dearBellaSectionHeader)
                    .foregroundStyle(cream)
                Text("Coming soon")
                    .font(.dearBellaBody)
                    .foregroundStyle(cream.opacity(0.6))
            }
        }
    }
}

#Preview {
    SwipePlaceholderView()
}
