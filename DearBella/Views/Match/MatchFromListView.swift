import SwiftUI

/// "Get a match": swipe your own list down to one film for tonight.
///
/// This is the decision half of the app, and it deliberately draws only on
/// what's already saved. A fresh deck asks "what exists?"; your list asks
/// "which of the things I already want?" — which is the question people
/// actually have at 8pm on a Friday, and the one nothing else answers.
///
/// It's also what makes collecting worth doing: every swipe in Discover is
/// feeding this.
///
/// The rule is as small as it can be: five films at a time, and the first one
/// you swipe right on is the match. Narrowing rounds asked people to hold a
/// tournament in their head — but nobody deliberating over dinner wants a
/// bracket, they want to be asked until something sounds good.
struct MatchFromListView: View {
    let films: [SavedFilm]

    @EnvironmentObject private var watchlist: WatchlistStore
    @Environment(\.dismiss) private var dismiss

    @State private var remaining: [SavedFilm] = []
    @State private var rejected: Set<String> = []
    @State private var drag: CGSize = .zero
    @State private var matched: SavedFilm?

    private let swipeThreshold: CGFloat = 110

    /// Few enough to get through in seconds. A round is a nudge, not an audit.
    private let roundSize = 5

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            if let matched {
                MatchedFilmView(film: matched) { dismiss() }
            } else {
                deck
            }

            closeButton
        }
        .onAppear(perform: start)
    }

    // MARK: - Deck

    private var deck: some View {
        VStack(spacing: 18) {
            header

            ZStack {
                if remaining.count > 1, let next = remaining.dropFirst().first {
                    card(next)
                        .scaleEffect(0.95)
                        .offset(y: 16)
                        .allowsHitTesting(false)
                }

                if let top = remaining.first {
                    card(top)
                        .offset(drag)
                        .rotationEffect(.degrees(Double(drag.width / 18)))
                        .gesture(gesture(for: top))
                }
            }
            .padding(.horizontal, 24)

            buttons
                .padding(.bottom, 8)
        }
        .padding(.top, 52)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Fancy this tonight?")
                .font(.dmSerif(24))
                .foregroundStyle(Theme.cream)
                .multilineTextAlignment(.center)
            Text("First one you like is your match")
                .font(.dearBellaCaption)
                .foregroundStyle(Theme.cream.opacity(0.5))
        }
        .padding(.horizontal, 24)
    }

    private func card(_ film: SavedFilm) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PosterImage(posterPath: film.posterPath, seed: film.title)
                .frame(maxWidth: .infinity)
                .aspectRatio(0.66, contentMode: .fit)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(film.title)
                    .font(.dmSerif(22))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(2)
                if !film.genres.isEmpty {
                    Text(film.genres.prefix(3).joined(separator: " · "))
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    private var buttons: some View {
        HStack(spacing: 40) {
            circle(systemName: "xmark", color: Theme.cream.opacity(0.7)) {
                if let top = remaining.first { fly(top, keep: false) }
            }
            circle(systemName: "heart.fill", color: Theme.cyan) {
                if let top = remaining.first { fly(top, keep: true) }
            }
        }
    }

    private func circle(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 64, height: 64)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
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

    // MARK: - Rounds

    /// Deals a fresh round, preferring films this sitting hasn't rejected yet.
    /// Once they've all been turned down, the pool reopens rather than
    /// dead-ending — running out of list is not an answer to "what's on
    /// tonight".
    private func start() {
        guard remaining.isEmpty, matched == nil else { return }
        deal()
    }

    private func deal() {
        var pool = films.filter { !rejected.contains($0.id) }
        if pool.isEmpty {
            rejected = []
            pool = films
        }
        remaining = Array(pool.shuffled().prefix(roundSize))
    }

    private func gesture(for film: SavedFilm) -> some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    fly(film, keep: true)
                } else if value.translation.width < -swipeThreshold {
                    fly(film, keep: false)
                } else {
                    withAnimation(.spring(response: 0.3)) { drag = .zero }
                }
            }
    }

    private func fly(_ film: SavedFilm, keep: Bool) {
        withAnimation(.easeOut(duration: 0.28)) {
            drag = CGSize(width: keep ? 1000 : -1000, height: drag.height)
        } completion: {
            drag = .zero

            if keep {
                matched = film
                return
            }

            rejected.insert(film.id)
            remaining.removeAll { $0.id == film.id }
            if remaining.isEmpty { deal() }
        }
    }
}

/// The end of the round: one film, and what to do about it.
private struct MatchedFilmView: View {
    let film: SavedFilm
    let onDone: () -> Void

    @EnvironmentObject private var watchlist: WatchlistStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("It's a match")
                    .font(.inter(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.cyan)
                    .clipShape(Capsule())
                    .padding(.top, 52)

                PosterImage(posterPath: film.posterPath, seed: film.title)
                    .frame(width: 150, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(film.title)
                    .font(.dmSerif(26))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text("Watch this one tonight.")
                    .font(.inter(14))
                    .foregroundStyle(Theme.cream.opacity(0.75))

                VStack(spacing: 8) {
                    Link(destination: WatchlistStore.watchURL(for: film)) {
                        Label("Where to watch", systemImage: "play.rectangle.fill")
                            .font(.dearBellaButton)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.cyan)
                            .clipShape(Capsule())
                    }

                    Button {
                        watchlist.setStatus(.watched, for: film.id)
                        onDone()
                    } label: {
                        Text("I watched it")
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
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
    }
}
