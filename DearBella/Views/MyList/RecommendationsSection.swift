import SwiftUI

/// #2 — "Find more like my list": a button that uses the saved films as taste
/// input to generate new recommendations (reusing the chat's Claude+TMDB
/// engine). Results show as a horizontal row of poster cards, each with a Save
/// action. Fires only on tap (paid call). Handles loading + failure.
struct RecommendationsSection: View {
    @ObservedObject var viewModel: MyListViewModel
    let context: TasteContext
    @EnvironmentObject private var watchlist: WatchlistStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task { await viewModel.generateRecommendations(context: context) }
            } label: {
                Label("Find more like my list", systemImage: "sparkles")
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.cyan)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingRecs)
            .opacity(viewModel.isLoadingRecs ? 0.5 : 1)

            if viewModel.isLoadingRecs {
                HStack(spacing: 8) {
                    ProgressView().tint(Theme.cyan)
                    Text("Finding films you'll love…")
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.7))
                }
            }

            if let error = viewModel.recsError {
                Text(error)
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.6))
            }

            if !viewModel.recommendations.isEmpty {
                Text("Suggested for you")
                    .font(.dearBellaSectionHeader)
                    .foregroundStyle(Theme.cream)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(viewModel.recommendations) { film in
                            suggestionCard(film)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func suggestionCard(_ film: RecommendedFilm) -> some View {
        let saved = watchlist.isSaved(film.savedFilm.id)
        return VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(0.66, contentMode: .fit)
                .overlay { PosterImage(posterPath: film.posterPath, seed: film.title) }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(film.title)
                .font(.dearBellaCaption)
                .foregroundStyle(Theme.cream)
                .lineLimit(2)

            Button {
                watchlist.toggle(film.savedFilm)
            } label: {
                Label(saved ? "Saved" : "Save", systemImage: saved ? "checkmark" : "plus")
                    .font(.inter(12, weight: .semibold))
                    .foregroundStyle(saved ? Theme.ink : Theme.cream)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(saved ? Theme.cyan : Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 120)
    }
}
