import SwiftUI

/// A half-star 0.5–5 rating control.
///
/// Drag or tap anywhere across the row to set a value; the gesture is
/// continuous, so sliding a thumb along the stars scrubs the rating the way
/// people expect from Letterboxd. Set `isInteractive` to false for a read-only
/// display (list cards, share art).
struct StarRating: View {
    @Binding var rating: Double?

    var size: CGFloat = 28
    var spacing: CGFloat = 6
    var isInteractive: Bool = true

    /// Laid out at a known width so the drag maths needs no `GeometryReader`.
    private var totalWidth: CGFloat { size * 5 + spacing * 4 }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(rating == nil ? Theme.cream.opacity(0.28) : Theme.cyan)
            }
        }
        .frame(width: totalWidth, height: size)
        .contentShape(Rectangle())
        .allowsHitTesting(isInteractive)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { rating = value(atX: $0.location.x) }
        )
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue(rating.map { "\($0.formatted()) of 5 stars" } ?? "Not rated")
        .accessibilityAdjustableAction { direction in
            let current = rating ?? 0
            switch direction {
            case .increment: rating = min(current + 0.5, 5)
            case .decrement: rating = max(current - 0.5, 0.5)
            @unknown default: break
            }
        }
    }

    /// Which star image to draw at `index`, given how much of it is filled.
    private func symbol(for index: Int) -> String {
        let filled = (rating ?? 0) - Double(index)
        if filled >= 1 { return "star.fill" }
        if filled >= 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    /// Maps a horizontal touch position onto the nearest half star, rounding up
    /// so touching any part of a star fills at least its first half.
    private func value(atX x: CGFloat) -> Double {
        let clamped = min(max(x, 0), totalWidth)
        let halves = (clamped / (size + spacing) * 2).rounded(.up)
        return min(max(Double(halves) / 2, 0.5), 5)
    }
}

/// The compact, read-only badge shown over a poster on the list cards.
struct RatingBadge: View {
    let rating: Double?
    let reaction: FilmReaction?

    var body: some View {
        if rating != nil || reaction != nil {
            HStack(spacing: 4) {
                if let reaction {
                    Image(systemName: reaction.symbol)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(reaction == .disliked ? Theme.cream.opacity(0.7) : Theme.cyan)
                }
                if let rating {
                    Text(rating.formatted())
                        .font(.inter(11, weight: .bold))
                        .foregroundStyle(Theme.cream)
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.cyan)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.black.opacity(0.65), in: Capsule())
        }
    }
}
