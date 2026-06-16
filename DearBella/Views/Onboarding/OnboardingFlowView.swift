import SwiftUI

/// Coordinates the onboarding screens in order:
/// splash → intro carousel → genres → top 5 films → "Great picks!".
///
/// It holds the current `step` and swaps screens with a cross-fade. The splash
/// auto-advances after a short delay; every other step advances when its
/// button calls back. Finishing marks onboarding complete in the store, which
/// makes `RootView` switch to the home screen.
struct OnboardingFlowView: View {
    @EnvironmentObject private var store: OnboardingStore
    @State private var step: Step = .splash

    private enum Step {
        case splash, intro, genres, films, greatPicks
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            currentScreen
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch step {
        case .splash:
            SplashView()
                .task { await advanceFromSplash() }
        case .intro:
            IntroCarouselView { go(to: .genres) }
        case .genres:
            GenreSelectionView { go(to: .films) }
        case .films:
            FilmSelectionView { go(to: .greatPicks) }
        case .greatPicks:
            GreatPicksView { store.completeOnboarding() }
        }
    }

    private func go(to next: Step) {
        withAnimation(.easeInOut(duration: 0.35)) {
            step = next
        }
    }

    private func advanceFromSplash() async {
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        go(to: .intro)
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
}
