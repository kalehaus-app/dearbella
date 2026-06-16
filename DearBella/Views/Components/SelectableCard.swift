import SwiftUI

/// A rounded poster-style card used in both the genre and film grids.
///
/// Two label styles:
/// - `.standard` (films): subtle title in the top-left over the poster.
/// - `.prominent` (genres): the poster and a bold caption bar are stacked in a
///   `VStack`, so the label has its own reserved space below the poster and can
///   never be clipped.
///
/// In both cases the poster is drawn inside a clipped container so its
/// `scaledToFill` overflow can't inflate the card's layout.
struct SelectableCard: View {
    let title: String
    /// Seed for the placeholder gradient (we pass the item's id).
    let seed: String
    /// Optional TMDB poster path; falls back to the gradient while absent.
    var posterPath: String? = nil
    let isSelected: Bool
    /// Optional order number ("1"–"5") shown for film picks.
    var badge: String? = nil
    /// Width-to-height ratio of the whole tile. ~0.8 genres, ~0.66 films.
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

    @ViewBuilder
    private var cardContent: some View {
        switch titleProminence {
        case .standard: standardTile
        case .prominent: prominentTile
        }
    }

    /// The poster, clipped to whatever space it's given so it can't overflow
    /// and inflate the card.
    private var poster: some View {
        Color.clear
            .overlay { PosterImage(posterPath: posterPath, seed: seed) }
            .clipped()
    }

    /// Film tiles: poster fills the card, title in the top-left over scrims.
    private var standardTile: some View {
        ZStack {
            poster

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

            if isSelected {
                selectionMarker
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    /// Genre tiles: poster on top, a solid caption bar with the bold genre name
    /// reserved below it. Neither can clip the other.
    private var prominentTile: some View {
        VStack(spacing: 0) {
            poster
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        selectionMarker.padding(8)
                    }
                }

            Text(title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.black)
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
