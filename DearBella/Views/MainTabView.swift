import SwiftUI

/// Wraps the main app in a bottom tab bar. Home is the first tab, so after
/// onboarding the app still lands on the dashboard exactly as before. Chat is
/// NOT a tab — it stays reachable via the "Start Chat" CTA on Home.
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            MyListView()
                .tabItem {
                    Label("My List", systemImage: "bookmark")
                }

            SwipePlaceholderView()
                .tabItem {
                    Label("Swipe", systemImage: "rectangle.stack")
                }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    MainTabView()
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
        .environmentObject(WatchlistStore())
}
