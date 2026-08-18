import SwiftUI

/// Shows what Bella has actually learned from the films you've rated.
///
/// Rating things is work, and until now that work disappeared into a store
/// with nothing to show for it. This is the receipt: how much Bella knows,
/// what it thinks you're into, and — while the picture is still thin — how
/// much further there is to go. It reads the taste profile the recommender
/// already builds, so what's on screen is genuinely what Bella is using.
struct TasteProgressCard: View {
    let films: [SavedFilm]

    /// Below this, the read is more noise than signal and says so.
    private let confidentAt = 5

    private var rated: [SavedFilm] {
        films.filter(\.hasTasteSignal)
    }

    private var profile: TasteContext {
        TasteContext(films: films)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.cyan)
                Text("Bella's read on you")
                    .font(.inter(11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.8)
            }

            if rated.isEmpty {
                Text("Rate a film you've seen and Bella starts learning what you actually like — not just what you saved.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(headline)
                    .font(.dmSerif(20, relativeTo: .title3))
                    .foregroundStyle(Theme.cream)
                    .fixedSize(horizontal: false, vertical: true)

                if !profile.genres.isEmpty {
                    genrePills
                }

                if rated.count < confidentAt {
                    Text("\(confidentAt - rated.count) more and Bella's picks get noticeably sharper.")
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.5))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.cyan.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var headline: String {
        let count = rated.count
        let noun = count == 1 ? "film" : "films"
        if count < confidentAt {
            return "\(count) \(noun) rated — still getting to know you."
        }
        if let loved = profile.loved.first {
            return "\(count) \(noun) rated. You loved \(loved), and it shows."
        }
        return "\(count) \(noun) rated. Bella's got a solid read on you."
    }

    /// The genres actually driving recommendations, most influential first.
    private var genrePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(profile.genres.prefix(5), id: \.self) { genre in
                    Text(genre)
                        .font(.inter(12, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.cyan)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
