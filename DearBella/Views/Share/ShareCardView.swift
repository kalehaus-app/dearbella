import SwiftUI

/// The 9:16 "My Month, in films" share card at the 1080×1920 export size.
///
/// Takes the resolved film titles (top 5 from the watchlist) so the same view
/// can be both previewed and rendered to an image later. Title sizes come from
/// `ShareCardData.titleSize`; the month label is dynamic. Handles fewer-than-5
/// and empty cases gracefully.
struct ShareCardView: View {
    /// The films to show, in rank order (top 5 from the user's list).
    let films: [String]

    // Exact palette from the spec.
    private let cardRed = Color(red: 58 / 255, green: 10 / 255, blue: 14 / 255)    // #3A0A0E
    private let coral = Color(red: 240 / 255, green: 70 / 255, blue: 75 / 255)     // #F0464B
    private let mutedRed = Color(red: 154 / 255, green: 48 / 255, blue: 52 / 255)  // #9A3034

    var body: some View {
        ZStack {
            cardRed
            VStack(spacing: 0) {
                Spacer().frame(height: 210)
                topLabel
                Spacer()
                if films.isEmpty {
                    emptyPlaceholder
                } else {
                    filmList
                }
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
            Text("MY \(ShareCardData.monthName), ")
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
            ForEach(Array(films.enumerated()), id: \.offset) { index, title in
                row(rank: index + 1, title: title, size: ShareCardData.titleSize(for: index, count: films.count))
            }
        }
    }

    private func row(rank: Int, title: String, size: CGFloat) -> some View {
        ZStack {
            // Centered title.
            Text(title)
                .font(.inter(size, weight: .heavy))   // Inter-Bold (heaviest installed)
                .tracking(-1)
                .foregroundStyle(coral)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)

            // Hanging index number at the left.
            HStack {
                Text("\(rank)")
                    .font(.inter(34, weight: .regular))
                    .foregroundStyle(mutedRed)
                Spacer()
            }
        }
        .padding(.horizontal, 70)
    }

    // MARK: - Empty state

    private var emptyPlaceholder: some View {
        Text("Save films to your list to see your top 5 here.")
            .font(.inter(40, weight: .medium))
            .foregroundStyle(coral)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 120)
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

#Preview("Top 5") {
    ShareCardView(films: [
        "Aftersun", "Past Lives", "Moonlight", "Lady Bird", "The Worst Person in the World",
    ])
    .scaleEffect(0.35)
    .frame(width: 1080 * 0.35, height: 1920 * 0.35)
}

#Preview("Three films") {
    ShareCardView(films: ["Aftersun", "Past Lives", "Moonlight"])
        .scaleEffect(0.35)
        .frame(width: 1080 * 0.35, height: 1920 * 0.35)
}

#Preview("Empty") {
    ShareCardView(films: [])
        .scaleEffect(0.35)
        .frame(width: 1080 * 0.35, height: 1920 * 0.35)
}
