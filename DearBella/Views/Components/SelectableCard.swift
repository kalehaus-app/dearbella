import SwiftUI

/// A rounded poster-style card used in both the genre and film grids.
///
/// Two label styles:
/// - `.standard` (films): subtle title in the top-left over light scrims.
/// - `.prominent` (genres): a bold genre name in a solid dark caption bar
///   across the bottom — guaranteed readable, never clipped by the tile edge.
struct SelectableCard: View {
    let title: String
    /// Seed for the placeholder gradient (we pass the item's id).
    let seed: String
    /// Optional TMDB poster path; falls back to the gradient while absent.
    var posterPath: String? = nil
    let isSelected: Bool
    /// Optional order number ("1"–"5") shown for film picks.
    var badge: String? = nil
    /// Width-to-height ratio. ~0.85 for genre tiles, ~0.66 for tall posters.
    var aspectRatio: CGFloat = 1.0
    /// How the title is presented. Genres use `.prominent`.
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
        ZStack {
            PosterImage(posterPath: posterPath, seed: seed)

            switch titleProminence {
            case .standard: standardLabel
            case .prominent: prominentLabel
            }

            if isSelected {
                selectionMarker
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    /// Film tiles: title in the top-left over soft scrims.
    private var standardLabel: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .top,
                endPoint: .center
            )
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .center,
                endPoint: .bottom
            )
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(radius: 3)
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// Genre tiles: a solid dark caption bar across the bottom. The name is big
    /// and bold, shrinks to fit on one line, and can't clip the tile edge.
    private var prominentLabel: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.72))
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
