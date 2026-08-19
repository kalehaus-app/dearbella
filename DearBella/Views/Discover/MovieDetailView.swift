import SwiftUI

/// Detail screen opened by tapping a swipe card: large poster, full info, and a
/// "Play Trailer" button (TMDB videos → YouTube). The trailer key loads on
/// appear; the button opens YouTube externally, shows "Loading trailer…" while
/// fetching, and falls back to "No trailer available" if none is found.
struct MovieDetailView: View {
    let movie: SwipeMovie
    /// Reported back so the deck can drop the card, not just the store.
    var onHide: ((SwipeMovie) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var trailerKey: String?
    @State private var trailerLoaded = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Color.clear
                        .aspectRatio(0.66, contentMode: .fit)
                        .overlay { PosterImage(posterPath: movie.posterPath, seed: movie.title) }
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text(movie.title)
                        .font(.dmSerif(32))
                        .foregroundStyle(Theme.cream)

                    HStack(spacing: 8) {
                        if let rating = movie.rating, rating > 0 {
                            Text("★ \(String(format: "%.1f", rating))")
                                .font(.inter(12, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.highlight)
                                .clipShape(Capsule())
                        }
                        Text(metaLine)
                            .font(.inter(14, weight: .medium))
                            .foregroundStyle(Theme.cream.opacity(0.85))
                    }

                    trailerButton

                    if !movie.overview.isEmpty {
                        Text(movie.overview)
                            .font(.inter(15))
                            .foregroundStyle(Theme.cream.opacity(0.85))
                            .lineSpacing(3)
                    }

                    HideFilmButton(title: movie.title) {
                        onHide?(movie)
                        dismiss()
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .padding(.top, 40)
            }

            backButton
        }
        .task {
            guard !trailerLoaded else { return }
            trailerLoaded = true
            trailerKey = await TMDBClient.shared.trailerYouTubeKey(id: movie.id)
        }
    }

    @ViewBuilder
    private var trailerButton: some View {
        if let key = trailerKey, let url = URL(string: "https://www.youtube.com/watch?v=\(key)") {
            Button { openURL(url) } label: {
                Label("Play Trailer", systemImage: "play.fill")
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.highlight)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        } else if !trailerLoaded {
            Label("Loading trailer…", systemImage: "play.fill")
                .font(.dearBellaButton)
                .foregroundStyle(Theme.cream.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        } else {
            Label("No trailer available", systemImage: "play.slash")
                .font(.dearBellaButton)
                .foregroundStyle(Theme.cream.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
        }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.highlight)
                .padding(10)
                .background(.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var metaLine: String {
        var parts: [String] = []
        if let year = movie.year { parts.append(String(year)) }
        if !movie.genres.isEmpty { parts.append(movie.genres.prefix(3).joined(separator: ", ")) }
        if let runtime = movie.runtime {
            parts.append(runtime >= 60 ? "\(runtime / 60)h \(runtime % 60)m" : "\(runtime)m")
        }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    MovieDetailView(movie: SwipeMovie(from: TMDBMovie(
        id: 1, title: "Sample Film", posterPath: nil, overview: "A sample overview.",
        releaseDate: "2019-01-01", voteAverage: 7.8, genreIDs: [18], runtime: 122
    ))!)
}
