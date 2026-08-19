import SwiftUI

/// A brief "added to your list" confirmation badge shown when a film is liked.
/// Purely presentational — MatchView controls when it appears and fades.
struct LikeReward: View {
    var body: some View {
        Text("Added to your list 🎬")
            .font(.dearBellaButton)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Theme.cyan)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
    }
}
