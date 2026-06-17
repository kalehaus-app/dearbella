import SwiftUI

/// One swipe card: full-bleed poster with movie info over a bottom scrim, plus
/// drag-driven LIKE / PASS badges. `dragWidth` is the live horizontal drag of
/// the top card (0 for cards underneath) and drives the badge opacity.
struct SwipeCardView: View {
    let movie: SwipeMovie
    var dragWidth: CGFloat = 0

    var body: some View {
        Color.clear
            .aspectRatio(0.66, contentMode: .fit)
            .overlay {
                ZStack {
                    PosterImage(posterPath: movie.posterPath, seed: movie.title)

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.9)],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    info
                    badges
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.08)))
    }

    // MARK: - Info

    private var info: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(movie.title)
                .font(.dmSerif(30))
                .foregroundStyle(Theme.cream)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let rating = movie.rating, rating > 0 {
                    Text("★ \(String(format: "%.1f", rating))")
                        .font(.inter(12, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.cyan)
                        .clipShape(Capsule())
                }
                Text(metaLine)
                    .font(.inter(13, weight: .medium))
                    .foregroundStyle(Theme.cream.opacity(0.85))
                    .lineLimit(1)
            }

            if !movie.overview.isEmpty {
                Text(movie.overview)
                    .font(.inter(13))
                    .foregroundStyle(Theme.cream.opacity(0.8))
                    .lineLimit(3)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    /// "2019 · Drama, Thriller · 2h 12m"
    private var metaLine: String {
        var parts: [String] = []
        if let year = movie.year { parts.append(String(year)) }
        if !movie.genres.isEmpty { parts.append(movie.genres.prefix(2).joined(separator: ", ")) }
        if let runtime = movie.runtime { parts.append(runtimeText(runtime)) }
        return parts.joined(separator: " · ")
    }

    private func runtimeText(_ minutes: Int) -> String {
        minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }

    // MARK: - LIKE / PASS badges

    private var badges: some View {
        HStack {
            badge(text: "LIKE", color: Theme.cyan, opacity: clamp(dragWidth / 100))
            Spacer()
            badge(text: "PASS", color: Color(red: 1, green: 0.35, blue: 0.4), opacity: clamp(-dragWidth / 100))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func badge(text: String, color: Color, opacity: Double) -> some View {
        Text(text)
            .font(.inter(20, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 3))
            .rotationEffect(.degrees(text == "LIKE" ? -12 : 12))
            .opacity(opacity)
    }

    private func clamp(_ value: CGFloat) -> Double {
        Double(min(max(value, 0), 1))
    }
}
