import SwiftUI

/// The moment a swipe session resolves into an actual decision.
///
/// Swiping that only adds films to a list defers the choice rather than making
/// it — the deck never says "watch this one". After a round of cards, Bella
/// picks one film from everything liked in that sitting and commits to it, the
/// way the bracket ends on a winner.
struct SwipeVerdictView: View {
    let shortlist: [SwipeMovie]
    let onKeepSwiping: () -> Void

    @EnvironmentObject private var watchlist: WatchlistStore
    @Environment(\.dismiss) private var dismiss

    @State private var pick: SwipeMovie?
    @State private var blurb: String?
    @State private var isThinking = true

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let pick {
                result(pick)
            } else {
                thinking
            }
        }
        .task { await decide() }
    }

    // MARK: - States

    private var thinking: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Theme.cyan)
            Text("Bella's deciding…")
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream.opacity(0.8))
        }
    }

    private func result(_ movie: SwipeMovie) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Watch this tonight")
                    .font(.inter(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.cyan)
                    .clipShape(Capsule())
                    .padding(.top, 24)

                PosterImage(posterPath: movie.posterPath, seed: movie.title)
                    .frame(maxWidth: 240)
                    .aspectRatio(0.66, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(movie.title)
                    .font(.dmSerif(30))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)

                if isThinking {
                    ProgressView().tint(Theme.cyan).padding(.top, 2)
                } else if let blurb {
                    Text(blurb)
                        .font(.inter(15))
                        .foregroundStyle(Theme.cream.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 32)
                }

                actions(movie)
                    .padding(.top, 4)

                Text("Picked from the \(shortlist.count) film\(shortlist.count == 1 ? "" : "s") you liked just now.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.45))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
    }

    private func actions(_ movie: SwipeMovie) -> some View {
        VStack(spacing: 10) {
            Link(destination: WatchlistStore.watchURL(for: movie.savedFilm)) {
                Label("Where to watch", systemImage: "play.rectangle.fill")
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.cyan)
                    .clipShape(Capsule())
            }

            Button {
                onKeepSwiping()
                dismiss()
            } label: {
                Text("Keep swiping")
                    .font(.inter(15, weight: .medium))
                    .foregroundStyle(Theme.cream.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Deciding

    /// Shows a pick immediately, then lets Bella's reasoning catch up.
    ///
    /// The local choice — the best-reviewed film on the shortlist — is what
    /// actually gets displayed, so the screen is never blocked on the network
    /// and the answer is the same whether or not the call succeeds. Claude only
    /// supplies the sentence explaining it.
    private func decide() async {
        guard pick == nil, !shortlist.isEmpty else { return }

        let chosen = shortlist.max { ($0.rating ?? 0) < ($1.rating ?? 0) } ?? shortlist[0]
        pick = chosen

        // Everything liked this round is already saved by the swipe itself,
        // so there's nothing to add here — just the reasoning to fetch.
        blurb = try? await BracketBella.blurb(title: chosen.title, overview: chosen.overview)
        isThinking = false
    }
}
