import SwiftUI

/// A rounded poster-style card used in both the genre and film grids.
///
/// Shows a placeholder gradient with the title in the top-left. When selected
/// it gains an accent border and a marker in the top-right — either a check
/// (genres) or a numbered badge showing pick order (films).
struct SelectableCard: View {
    let title: String
    /// Seed for the placeholder gradient (we pass the item's id).
    let seed: String
    /// Optional TMDB poster path; falls back to the gradient while absent.
    var posterPath: String? = nil
    let isSelected: Bool
    /// Optional order number ("1"–"5") shown for film picks.
    var badge: String? = nil
    /// Width-to-height ratio. ~1.1 for genre tiles, ~0.66 for tall posters.
    var aspectRatio: CGFloat = 1.0
    /// How loud the title is. Genres use `.prominent` for at-a-glance reading.
    var titleProminence: TitleProminence = .standard
    let action: () -> Void

    enum TitleProminence {
        case standard
        case prominent
    }

    var body: some View {
        Button(action: action) {
            Color.clear
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay { cardContent }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .stroke(Theme.accent, lineWidth: isSelected ? 3 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        ZStack(alignment: .topLeading) {
            PosterImage(posterPath: posterPath, seed: seed)

            // Scrims darken the art so the title stays legible. Genres use a
            // stronger top scrim so the name reads instantly at a glance.
            topScrim
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(title)
                .font(titleFont)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 4)
                .padding(titlePadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if isSelected {
                selectionMarker
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    private var titleFont: Font {
        switch titleProminence {
        case .standard: return .headline.weight(.semibold)
        case .prominent: return .system(size: 24, weight: .heavy)
        }
    }

    private var titlePadding: CGFloat {
        switch titleProminence {
        case .standard: return 10
        case .prominent: return 12
        }
    }

    /// The top darkening gradient — heavier for prominent (genre) labels.
    @ViewBuilder
    private var topScrim: some View {
        switch titleProminence {
        case .standard:
            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .top,
                endPoint: .center
            )
        case .prominent:
            LinearGradient(
                colors: [.black.opacity(0.85), .black.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var selectionMarker: some View {
        if let badge {
            Text(badge)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.accent))
        } else {
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.accent))
        }
    }
}
