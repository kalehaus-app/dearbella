import SwiftUI

/// One head-to-head matchup: two large posters side by side. Tapping a poster
/// opens a detail sheet to preview it; choosing happens from the sheet, which
/// then advances the bracket.
struct BracketMatchupView: View {
    @ObservedObject var viewModel: BracketViewModel

    @State private var detailMovie: SwipeMovie?

    var body: some View {
        VStack(spacing: 24) {
            progress

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 14) {
                if let left = viewModel.leftMovie {
                    posterChoice(left)
                }
                Text("VS")
                    .font(.dmSerif(22))
                    .foregroundStyle(Theme.cyan)
                if let right = viewModel.rightMovie {
                    posterChoice(right)
                }
            }
            .padding(.horizontal, 20)
            .id("\(viewModel.roundNumber)-\(viewModel.matchupIndex)")
            .transition(.opacity)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .sheet(item: $detailMovie) { movie in
            BracketMovieDetailSheet(movie: movie) {
                detailMovie = nil
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.choose(movie)
                }
            }
            .environmentObject(HiddenFilmsStore.shared)
        }
    }

    private var progress: some View {
        VStack(spacing: 4) {
            Text(viewModel.roundName)
                .font(.dmSerif(28))
                .foregroundStyle(Theme.cream)
            Text("Round \(viewModel.roundNumber) of \(viewModel.totalRounds) · Matchup \(viewModel.matchupIndex + 1) of \(viewModel.matchupsInRound)")
                .font(.inter(13, weight: .medium))
                .foregroundStyle(Theme.cream.opacity(0.6))
        }
        .padding(.top, 12)
    }

    private func posterChoice(_ movie: SwipeMovie) -> some View {
        VStack(spacing: 8) {
            Color.clear
                .aspectRatio(0.66, contentMode: .fit)
                .overlay { PosterImage(posterPath: movie.posterPath, seed: movie.title) }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08)))

            Text(movie.year != nil ? "\(movie.title) (\(movie.year!))" : movie.title)
                .font(.inter(14, weight: .semibold))
                .foregroundStyle(Theme.cream)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { detailMovie = movie }
    }
}
