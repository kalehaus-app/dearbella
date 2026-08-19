import SwiftUI

/// The Discover tab: a deck of films to fill your list from.
///
/// It opens already dealing — no picker in front of it, because a screen
/// asking what you want before showing you anything is a wall in front of the
/// only thing the tab does. The filter row switches pools mid-flow instead.
///
/// Drag right to like (saves to the watchlist), left to pass; the buttons do
/// the same. This tab collects; deciding happens in My List, from what's saved.
struct DiscoverView: View {
    @StateObject private var viewModel = SwipeFeedViewModel()
    @EnvironmentObject private var watchlist: WatchlistStore

    @State private var drag: CGSize = .zero
    @State private var showReward = false
    @State private var likeCount = 0                 // drives the success haptic
    @State private var detailMovie: SwipeMovie?

    private let swipeThreshold: CGFloat = 110



    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .task { await viewModel.loadInitial() }
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
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            message {
                ProgressView().tint(Theme.highlight)
                Text("Loading films…")
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
                    .foregroundStyle(Theme.highlight)
                Text(viewModel.filter == .newReleases
                     ? "You're caught up on new releases"
                     : "That's everything here for now")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Text("Try another filter above.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.6))
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

    /// Title, then the pools. Changing filter is a chip tap rather than a
    /// separate screen, so switching moods never costs the deck you're in.
    private var deckHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Discover")
                .font(.dearBellaTitle)
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 20)

            filterRow
        }
        .padding(.top, 12)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SwipeFilter.all) { option in
                    let isSelected = viewModel.filter == option

                    Button {
                        Task { await viewModel.apply(option) }
                    } label: {
                        Text(option.title)
                            .font(.inter(13, weight: .semibold))
                            .foregroundStyle(isSelected ? Theme.ink : Theme.cream)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Theme.highlight : Color.white.opacity(0.07))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var buttons: some View {
        HStack(spacing: 40) {
            circleButton(systemName: "xmark", color: Theme.cream.opacity(0.7)) {
                if let top = viewModel.topMovie { fly(top, liked: false) }
            }
            circleButton(systemName: "heart.fill", color: Theme.highlight) {
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
    DiscoverView()
        .environmentObject(WatchlistStore())
}
