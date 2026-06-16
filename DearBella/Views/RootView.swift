import SwiftUI

/// Top-level router: shows onboarding until it's finished, then the home
/// screen. Because it watches `OnboardingStore`, completing (or resetting)
/// onboarding flips the screen automatically.
struct RootView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var catalog: MovieCatalog

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingFlowView()
            }
        }
        .animation(.easeInOut, value: store.hasCompletedOnboarding)
        .task {
            // Fetch real TMDB posters for the curated films once on launch.
            await catalog.loadPostersIfNeeded()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
        .environmentObject(WatchlistStore())
}
