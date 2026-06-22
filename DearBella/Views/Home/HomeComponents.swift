import SwiftUI

/// A rounded image-style card with a caption in the top-left — the building
/// block for the "Curated for you" and "Things to do" grids. Uses a
/// placeholder gradient until TMDB art arrives in Step 4.
struct CaptionCard: View {
    let caption: String
    let seed: String
    var posterPath: String? = nil
    var aspectRatio: CGFloat = 1.5

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                ZStack(alignment: .topLeading) {
                    PosterImage(posterPath: posterPath, seed: seed)
                    LinearGradient(
                        colors: [.black.opacity(0.05), .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Text(caption)
                        .font(.dearBellaBody)
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Home-only "Browse by Vibe" pill with explicit background + text colors.
/// (Separate from the shared `VibePill` so onboarding stays untouched.)
struct HomeVibePill: View {
    let text: String
    let background: Color
    let textColor: Color

    var body: some View {
        Text(text)
            .font(.inter(13, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(background)
            .clipShape(Capsule())
    }
}

/// A simple left-aligned section title used between home-feed sections.
struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.dearBellaSectionHeader)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
