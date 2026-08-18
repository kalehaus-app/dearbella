import SwiftUI

/// Wraps the main app in a bottom tab bar. Home is the first tab, so after
/// onboarding the app still lands on the dashboard exactly as before. Chat is
/// NOT a tab — it stays reachable via the "Start Chat" CTA on Home.
struct MainTabView: View {
    @EnvironmentObject private var notifications: NotificationService
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            MyListView()
                .tabItem {
                    Label("My List", systemImage: "bookmark")
                }
                .tag(1)

            SwipeView()
                .tabItem {
                    Label("Swipe", systemImage: "rectangle.stack")
                }
                .tag(2)

            BracketView()
                .tabItem {
                    Label("Bracket", systemImage: "trophy")
                }
                .tag(3)
        }
        .tint(Theme.cyan)
        // A reminder promises tonight's pick, so it has to land on the tab
        // that shows it, whichever tab was open last.
        .onChange(of: notifications.didOpenFromReminder) { _, fromReminder in
            if fromReminder { selection = 0 }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
        .environmentObject(WatchlistStore())
        .environmentObject(NotificationService.shared)
}
