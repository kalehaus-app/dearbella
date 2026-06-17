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

/// A home-feed tile backed by a local asset-catalog image, with a caption in a
/// corner over a subtle dark scrim. "Curated for you" uses a bottom caption;
/// "Things to do" uses a top caption.
struct ImageTile: View {
    let imageName: String
    let caption: String
    /// `true` places the caption at the top-left, `false` at the bottom-left.
    let captionAtTop: Bool
    var aspectRatio: CGFloat = 1.5

    /// Cream (#F4EFE6) — the design's caption color.
    private let cream = Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()

                    // Subtle scrim: darkest at the caption edge, fading to clear.
                    LinearGradient(
                        colors: captionAtTop
                            ? [.black.opacity(0.6), .clear]
                            : [.clear, .black.opacity(0.6)],
                        startPoint: captionAtTop ? .top : .center,
                        endPoint: captionAtTop ? .center : .bottom
                    )

                    Text(caption)
                        .font(.inter(15, weight: .semibold))
                        .foregroundStyle(cream)
                        .shadow(radius: 3)
                        .padding(12)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: captionAtTop ? .topLeading : .bottomLeading
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
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
