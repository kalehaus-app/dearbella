import SwiftUI

/// One reusable collection screen, opened by every "Curated for you" tile.
/// Same design; the `title` + `source` differ per tile. Loads on appear (i.e.
/// when a tile is tapped), shows loading/empty/error states, and lets the user
/// save any film to their watchlist.
struct CollectionView: View {
    let title: String
    let source: CollectionViewModel.Source

    @StateObject private var viewModel = CollectionViewModel()
    @EnvironmentObject private var watchlist: WatchlistStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                backButton
                Text(title)
                    .font(.dearBellaTitle)
                    .foregroundStyle(Theme.cream)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                content
            }
        }
        .task { await viewModel.load(source: source) }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.cyan)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            stateMessage {
                ProgressView().tint(Theme.cyan)
                Text("Finding films…")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
        } else if let error = viewModel.error {
            stateMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.cream.opacity(0.5))
                Text(error)
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.films) { film in
                        filmCard(film)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func filmCard(_ film: RecommendedFilm) -> some View {
        let saved = watchlist.isSaved(film.savedFilm.id)
        return HStack(alignment: .top, spacing: 12) {
            Color.clear
                .frame(width: 70, height: 105)
                .overlay { PosterImage(posterPath: film.posterPath, seed: film.title) }
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(film.year != nil ? "\(film.title) (\(film.year!))" : film.title)
                    .font(.inter(16, weight: .semibold))
                    .foregroundStyle(Theme.cream)

                if !film.reason.isEmpty {
                    Text(film.reason)
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.6))
                        .lineLimit(3)
                }

                Button {
                    watchlist.toggle(film.savedFilm)
                } label: {
                    Label(saved ? "Saved" : "Save", systemImage: saved ? "checkmark" : "plus")
                        .font(.inter(12, weight: .semibold))
                        .foregroundStyle(saved ? Theme.ink : Theme.cream)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(saved ? Theme.cyan : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stateMessage<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 12) { content() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CollectionView(
        title: "Tonight's Mood: Dreamy & Disoriented",
        source: .claudeTheme("Tonight's Mood: Dreamy & Disoriented")
    )
    .environmentObject(WatchlistStore())
}
