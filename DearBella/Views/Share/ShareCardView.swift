import SwiftUI

/// Step 1 (static): the 9:16 "My Month, in films" share card, built at the
/// 1080×1920 export size with 5 hardcoded films at the spec's exact sizes,
/// colors, and layout. Real data, the size ramp, and export come in later steps.
struct ShareCardView: View {
    // Exact palette from the spec.
    private let cardRed = Color(red: 58 / 255, green: 10 / 255, blue: 14 / 255)    // #3A0A0E
    private let coral = Color(red: 240 / 255, green: 70 / 255, blue: 75 / 255)     // #F0464B
    private let mutedRed = Color(red: 154 / 255, green: 48 / 255, blue: 52 / 255)  // #9A3034

    /// Hardcoded reference films with their per-rank title sizes (pt @1080).
    private let films: [(rank: Int, title: String, size: CGFloat)] = [
        (1, "Aftersun", 102),
        (2, "Past Lives", 82),
        (3, "Moonlight", 122),                          // standout / biggest
        (4, "Lady Bird", 77),
        (5, "The Worst Person in the World", 68),
    ]

    var body: some View {
        ZStack {
            cardRed
            VStack(spacing: 0) {
                Spacer().frame(height: 210)
                topLabel
                Spacer()
                filmList
                Spacer()
                footer
                Spacer().frame(height: 384)
            }
        }
        .frame(width: 1080, height: 1920)
    }

    // MARK: - Top label

    private var topLabel: some View {
        (
            Text("MY JUNE, ")
                .font(.inter(40, weight: .bold))
                .tracking(1.4)
                .foregroundColor(coral)
            + Text("in films")
                .font(.inter(40, weight: .medium))
                .italic()
                .foregroundColor(coral)
        )
        .multilineTextAlignment(.center)
    }

    // MARK: - Film list

    private var filmList: some View {
        VStack(spacing: 8) {
            ForEach(films, id: \.rank) { film in
                row(film)
            }
        }
    }

    private func row(_ film: (rank: Int, title: String, size: CGFloat)) -> some View {
        ZStack {
            // Centered title.
            Text(film.title)
                .font(.inter(film.size, weight: .heavy))   // Inter-Bold (heaviest installed)
                .tracking(-1)
                .foregroundStyle(coral)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)

            // Hanging index number at the left.
            HStack {
                Text("\(film.rank)")
                    .font(.inter(34, weight: .regular))
                    .foregroundStyle(mutedRed)
                Spacer()
            }
        }
        .padding(.horizontal, 70)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 18) {
            // Placeholder clapper mark (real brand asset comes in a later step).
            Image(systemName: "film.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 58)
                .foregroundStyle(coral)

            Text("DEARBELLA · ON THE APP STORE")
                .font(.inter(34, weight: .bold))
                .tracking(2.8)
                .foregroundStyle(coral)
        }
    }
}

#Preview {
    // Scaled down so the 1080×1920 card is viewable in the canvas.
    ShareCardView()
        .scaleEffect(0.35)
        .frame(width: 1080 * 0.35, height: 1920 * 0.35)
}
