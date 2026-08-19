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
    @State private var showNotificationPrimer = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            if let pick {
                result(pick)
            } else {
                thinking
            }

            closeButton
        }
        .task { await decide() }
        .fullScreenCover(isPresented: $showNotificationPrimer) {
            NotificationPrimer { showNotificationPrimer = false }
                .presentationBackground(.clear)
        }
    }

    /// A visible way out. "Keep swiping" is the same exit phrased as an
    /// action, but a full-screen view with no close control reads as a trap
    /// however good the content is.
    private var closeButton: some View {
        Button {
            onKeepSwiping()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.cream.opacity(0.75))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
        .padding(.top, 8)
        .accessibilityLabel("Close")
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
            VStack(spacing: 14) {
                Text("Watch this tonight")
                    .font(.inter(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.cyan)
                    .clipShape(Capsule())
                    .padding(.top, 52)

                // Small enough that the title, the reason and both buttons
                // share one screen. This is a decision to act on, not a poster
                // to admire — burying the buttons below the fold undoes the
                // point of ending the session here.
                PosterImage(posterPath: movie.posterPath, seed: movie.title)
                    .frame(width: 150, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(movie.title)
                    .font(.dmSerif(26))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if isThinking {
                    ProgressView().tint(Theme.cyan)
                } else if let blurb {
                    Text(blurb)
                        .font(.inter(14))
                        .foregroundStyle(Theme.cream.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .lineLimit(4)
                        .padding(.horizontal, 24)
                }

                actions(movie)

                Text("Picked from the \(shortlist.count) film\(shortlist.count == 1 ? "" : "s") you liked just now.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.45))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private func actions(_ movie: SwipeMovie) -> some View {
        VStack(spacing: 8) {
            Link(destination: WatchlistStore.watchURL(for: movie.savedFilm)) {
                Label("Where to watch", systemImage: "play.rectangle.fill")
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
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
                    .padding(.vertical, 11)
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

        // Ask about reminders here, and only here: they've just seen Bella
        // decide for them, so "want this every Friday?" needs no explaining.
        await NotificationService.shared.refreshAuthorization()
        if NotificationService.shared.shouldOfferReminders {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showNotificationPrimer = true
        }
    }
}
