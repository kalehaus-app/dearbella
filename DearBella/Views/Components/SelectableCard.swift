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
    let isSelected: Bool
    /// Optional order number ("1"–"5") shown for film picks.
    var badge: String? = nil
    /// Width-to-height ratio. ~1.1 for genre tiles, ~0.66 for tall posters.
    var aspectRatio: CGFloat = 1.0
    let action: () -> Void

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
            PlaceholderArt.gradient(for: seed)

            // Darken the bottom so titles stay legible.
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
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
