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
    @EnvironmentObject private var onboarding: OnboardingStore

    @State private var drag: CGSize = .zero
    @State private var showReward = false
    @State private var likeCount = 0                 // drives the success haptic
    @State private var detailMovie: SwipeMovie?

    private let swipeThreshold: CGFloat = 110

    /// Everything Bella knows, for the "For you" pool. Recomputed as films are
    /// saved and rated, so tapping it always reasons from the current list.
    private var tasteContext: TasteContext {
        TasteContext(
            films: watchlist.films,
            onboardingGenres: SampleData.genres
                .filter { onboarding.selectedGenreIDs.contains($0.id) }
                .map(\.name),
            onboardingFilms: onboarding.selectedFilms.map(\.title),
            onboardingDirectors: onboarding.selectedDirectors.map(\.name)
        )
    }



    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .task {
            viewModel.update(taste: tasteContext)
            await viewModel.loadInitial()
        }
        .onChange(of: watchlist.films) { _, _ in
            viewModel.update(taste: tasteContext)
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
    }

    /// "For you" has two empty states and they mean opposite things: one says
    /// Bella has nothing to go on yet, the other that she's run out of ideas.
    private var emptyTitle: String {
        switch viewModel.filter {
        case .forYou where !viewModel.canPersonalize:
            return "Bella doesn't know you yet"
        case .forYou:
            return "That's everything Bella has for now"
        case .newReleases:
            return "You're caught up on new releases"
        default:
            return "That's everything here for now"
        }
    }

    private var emptyDetail: String {
        switch viewModel.filter {
        case .forYou where !viewModel.canPersonalize:
            return "Save a few films from All, or rate what you've watched, and this fills up."
        case .forYou:
            return "Rate a few more in My List and there'll be new ones here."
        default:
            return "Try another filter above."
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            message {
                ProgressView().tint(viewModel.filter == .forYou ? Theme.sparkEnd : Theme.highlight)
                Text(viewModel.filter == .forYou ? "Bella's picking for you…" : "Loading films…")
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
                Text(emptyTitle)
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Text(emptyDetail)
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.6))
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
                        if option == .forYou {
                            sparkChip(isSelected: isSelected)
                        } else {
                            plainChip(option.title, isSelected: isSelected)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func plainChip(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.inter(13, weight: .semibold))
            .foregroundStyle(isSelected ? Theme.ink : Theme.cream)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.highlight : Color.white.opacity(0.07))
            .clipShape(Capsule())
    }

    /// The only coloured thing in Discover. Unselected it wears the gradient
    /// as an outline and a sparkle, so it's visibly not another genre without
    /// shouting over the deck; selected it fills, and the row reads as one
    /// choice made rather than eight offered.
    private func sparkChip(isSelected: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .bold))
            Text("For you")
                .font(.inter(13, weight: .bold))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .foregroundStyle(isSelected ? AnyShapeStyle(Theme.ink) : AnyShapeStyle(Theme.spark))
        .background {
            if isSelected {
                Capsule().fill(Theme.spark)
            } else {
                Capsule()
                    .fill(Theme.sparkEnd.opacity(0.12))
                    .overlay(Capsule().strokeBorder(Theme.spark, lineWidth: 1.2))
            }
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
        .environmentObject(OnboardingStore())
}
