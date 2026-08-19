import SwiftUI

/// The Match tab: pick a vibe, swipe a deck dealt to fit it, and a few cards
/// later get matched with one film.
///
/// Drag right to like (saves to the watchlist), left to pass; the buttons do
/// the same. Handles loading, load failure, and running out of cards.
struct MatchView: View {
    @StateObject private var viewModel = MatchDeckViewModel()
    @EnvironmentObject private var watchlist: WatchlistStore
    @EnvironmentObject private var store: OnboardingStore

    @State private var drag: CGSize = .zero
    @State private var showReward = false
    @State private var likeCount = 0                 // drives the success haptic
    @State private var detailMovie: SwipeMovie?
    @State private var showBracket = false

    private let swipeThreshold: CGFloat = 110

    /// Dismissing the match any way — the button or a swipe down — starts the
    /// next round, so the shortlist can never be shown twice.
    private var matchBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isMatchReady },
            set: { if !$0 { viewModel.startNewRound() } }
        )
    }

    /// What Bella knows about them, so the deck is picked to the vibe *and* to
    /// their taste rather than the vibe alone.
    private var tasteContext: TasteContext {
        TasteContext(
            films: watchlist.films,
            onboardingGenres: SampleData.genres
                .filter { store.selectedGenreIDs.contains($0.id) }
                .map(\.name),
            onboardingFilms: store.selectedFilms.map(\.title)
        )
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .sensoryFeedback(.success, trigger: likeCount)
        .overlay(alignment: .top) {
            if showReward {
                LikeReward()
                    .padding(.top, 70)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .fullScreenCover(item: $detailMovie) { movie in
            MovieDetailView(movie: movie) { viewModel.hide($0) }
        }
        .fullScreenCover(isPresented: $showBracket) {
            BracketFlow()
                .environmentObject(watchlist)
                .environmentObject(HiddenFilmsStore.shared)
        }
        .fullScreenCover(isPresented: matchBinding) {
            MatchResultView(shortlist: viewModel.sessionLikes, vibe: viewModel.vibe) {
                viewModel.startNewRound()
            }
            .environmentObject(watchlist)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.vibe == nil {
            MatchVibePicker(
                onSelect: { vibe in
                    Task { await viewModel.choose(vibe, context: tasteContext) }
                },
                onBracket: { showBracket = true }
            )
        } else if viewModel.isLoading {
            message {
                ProgressView().tint(Theme.cyan)
                Text("Bella's picking films for you…")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
        } else if let error = viewModel.error, viewModel.deck.isEmpty {
            message {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.cream.opacity(0.5))
                Text(error)
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        } else if viewModel.deck.isEmpty {
            message {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.cyan)
                Text("That's everything for this one")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                Button("Try another vibe") { viewModel.changeVibe() }
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.cyan)
            }
        } else {
            deck
        }
    }

    // MARK: - Deck

    private var deck: some View {
        VStack(spacing: 20) {
            deckHeader

            ZStack {
                // One card behind, for a subtle stacked look.
                if viewModel.deck.count > 1 {
                    SwipeCardView(movie: viewModel.deck[1])
                        .scaleEffect(0.95)
                        .offset(y: 16)
                        .allowsHitTesting(false)
                }

                if let top = viewModel.topMovie {
                    SwipeCardView(movie: top, dragWidth: drag.width)
                        .offset(drag)
                        .rotationEffect(.degrees(Double(drag.width / 18)))
                        .onTapGesture { detailMovie = top }
                        .gesture(dragGesture(for: top))
                        .task(id: top.id) { await viewModel.ensureRuntime(for: top.id) }
                }
            }
            .padding(.horizontal, 24)

            buttons
                .padding(.bottom, 8)
        }
    }

    /// Names the vibe in play and offers the way back — someone whose mood has
    /// changed shouldn't have to swipe out a deck they no longer want.
    private var deckHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.vibe?.title ?? "Match")
                    .font(.dmSerif(28))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Swipe right on anything you'd watch")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.5))
            }
            Spacer()
            Button { viewModel.changeVibe() } label: {
                Text("Change")
                    .font(.inter(13, weight: .semibold))
                    .foregroundStyle(Theme.cyan)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var buttons: some View {
        HStack(spacing: 40) {
            circleButton(systemName: "xmark", color: Theme.cream.opacity(0.7)) {
                if let top = viewModel.topMovie { fly(top, liked: false) }
            }
            circleButton(systemName: "heart.fill", color: Theme.cyan) {
                if let top = viewModel.topMovie { fly(top, liked: true) }
            }
        }
    }

    private func circleButton(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
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

    // MARK: - Gestures + commit

    private func dragGesture(for movie: SwipeMovie) -> some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    fly(movie, liked: true)
                } else if value.translation.width < -swipeThreshold {
                    fly(movie, liked: false)
                } else {
                    withAnimation(.spring(response: 0.3)) { drag = .zero }
                }
            }
    }

    /// Animates the top card off-screen, then commits the like/pass.
    private func fly(_ movie: SwipeMovie, liked: Bool) {
        let endX: CGFloat = liked ? 1000 : -1000
        withAnimation(.easeOut(duration: 0.3)) {
            drag = CGSize(width: endX, height: drag.height)
        } completion: {
            if liked {
                watchlist.save(movie.savedFilm)
                viewModel.like(movie)
                triggerReward()
            } else {
                viewModel.pass(movie)
            }
            drag = .zero
        }
    }

    /// Brief, non-blocking "added to your list" confirmation + success haptic.
    private func triggerReward() {
        likeCount += 1
        withAnimation(.spring(response: 0.35)) { showReward = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeOut(duration: 0.4)) { showReward = false }
        }
    }

    private func message<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 12) { content() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MatchView()
        .environmentObject(WatchlistStore())
        .environmentObject(OnboardingStore())
}
