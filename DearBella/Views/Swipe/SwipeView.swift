import SwiftUI

/// The Swipe tab: a Tinder-style deck of popular films. Drag right to like
/// (saves to the watchlist), left to pass; buttons do the same. Handles
/// loading, load failure, and running out of cards.
struct SwipeView: View {
    @StateObject private var viewModel = SwipeDeckViewModel()
    @EnvironmentObject private var watchlist: WatchlistStore

    @State private var drag: CGSize = .zero

    private let swipeThreshold: CGFloat = 110

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .task { await viewModel.loadInitial() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            message {
                ProgressView().tint(Theme.cyan)
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
                    .foregroundStyle(Theme.cyan)
                Text("You've swiped through everything for now")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        } else {
            deck
        }
    }

    // MARK: - Deck

    private var deck: some View {
        VStack(spacing: 20) {
            Text("Swipe")
                .font(.dearBellaTitle)
                .foregroundStyle(Theme.cream)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)

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
                        .gesture(dragGesture(for: top))
                        .task(id: top.id) { await viewModel.ensureRuntime(for: top.id) }
                }
            }
            .padding(.horizontal, 24)

            buttons
                .padding(.bottom, 8)
        }
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
            } else {
                viewModel.pass(movie)
            }
            drag = .zero
        }
    }

    private func message<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 12) { content() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SwipeView()
        .environmentObject(WatchlistStore())
}
