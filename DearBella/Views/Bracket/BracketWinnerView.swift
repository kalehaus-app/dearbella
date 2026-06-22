import SwiftUI

/// The bracket winner: large poster + details, Bella's one-line take (with a
/// loading state and graceful fallback), and Save / Start Over actions.
struct BracketWinnerView: View {
    @ObservedObject var viewModel: BracketViewModel
    let winner: SwipeMovie
    @EnvironmentObject private var watchlist: WatchlistStore

    private let streakYellow = Color(red: 1, green: 1, blue: 1 / 255)   // #FFFF01

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("WINNER")
                    .font(.inter(13, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(streakYellow)
                    .padding(.top, 16)

                Color.clear
                    .aspectRatio(0.66, contentMode: .fit)
                    .overlay { PosterImage(posterPath: winner.posterPath, seed: winner.title) }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .frame(maxWidth: 260)

                Text(winner.year != nil ? "\(winner.title) (\(winner.year!))" : winner.title)
                    .font(.dmSerif(30))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)

                if !winner.genres.isEmpty {
                    Text(winner.genres.prefix(3).joined(separator: ", "))
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(Theme.cream.opacity(0.6))
                }

                bellaLine

                if !winner.overview.isEmpty {
                    Text(winner.overview)
                        .font(.inter(14))
                        .foregroundStyle(Theme.cream.opacity(0.8))
                        .lineSpacing(3)
                        .padding(.top, 4)
                }

                actions
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var bellaLine: some View {
        if viewModel.isLoadingBlurb {
            HStack(spacing: 8) {
                ProgressView().tint(Theme.cyan)
                Text("Bella's weighing in…")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
        } else if let blurb = viewModel.bellaBlurb {
            Text(blurb)
                .font(.inter(16, weight: .medium))
                .foregroundStyle(Theme.cyan)
                .multilineTextAlignment(.center)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            let saved = watchlist.isSaved(winner.savedFilm.id)
            Button {
                watchlist.save(winner.savedFilm)
            } label: {
                Label(saved ? "Saved to My List" : "Save to My List", systemImage: saved ? "checkmark" : "plus")
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.cyan)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(saved)
            .opacity(saved ? 0.7 : 1)

            Button {
                viewModel.reset()
            } label: {
                Text("Start Over")
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.cream.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}
