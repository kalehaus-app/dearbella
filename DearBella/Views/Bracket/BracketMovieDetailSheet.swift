import SwiftUI

/// Preview sheet for a movie in a bracket matchup: poster, title, year, TMDB
/// rating, and overview, with a "Choose this one" button that advances the
/// bracket. Dismissable (Close button / swipe-down) so both movies can be
/// previewed before deciding. Reuses `SwipeMovie`'s fields.
struct BracketMovieDetailSheet: View {
    let movie: SwipeMovie
    let onChoose: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    Color.clear
                        .aspectRatio(0.66, contentMode: .fit)
                        .overlay { PosterImage(posterPath: movie.posterPath, seed: movie.title) }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .frame(maxWidth: 240)
                        .frame(maxWidth: .infinity)

                    Text(movie.year != nil ? "\(movie.title) (\(movie.year!))" : movie.title)
                        .font(.dmSerif(28))
                        .foregroundStyle(Theme.cream)

                    if let rating = movie.rating, rating > 0 {
                        Text("★ \(String(format: "%.1f", rating))")
                            .font(.inter(13, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.cyan)
                            .clipShape(Capsule())
                    }

                    if !movie.overview.isEmpty {
                        Text(movie.overview)
                            .font(.inter(15))
                            .foregroundStyle(Theme.cream.opacity(0.85))
                            .lineSpacing(3)
                    }

                    chooseButton
                        .padding(.top, 8)
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.cream.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    private var chooseButton: some View {
        Button { onChoose() } label: {
            Text("Choose this one")
                .font(.dearBellaButton)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.cyan)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
