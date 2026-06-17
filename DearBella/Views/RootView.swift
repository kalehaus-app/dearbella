import SwiftUI

/// Top-level router: shows onboarding until it's finished, then the main app
/// (a tab bar that defaults to Home). Because it watches `OnboardingStore`,
/// completing (or resetting) onboarding flips the screen automatically.
struct RootView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var catalog: MovieCatalog

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                MainTabView()
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
