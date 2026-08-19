import SwiftUI

/// Wraps the main app in a bottom tab bar: Home to browse, Match to decide, My
/// List to keep. Home is first, so after onboarding the app still lands on the
/// dashboard exactly as before.
///
/// Three tabs, not four. Bracket lives inside Match as a second way to decide
/// rather than holding a tab of its own — a tab is the most valuable space in
/// the app, and it earns that only by being somewhere people go regularly.
/// Chat stays reachable via the "Start Chat" CTA on Home.
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

            MatchView()
                .tabItem {
                    Label("Match", systemImage: "sparkles.rectangle.stack")
                }
                .tag(1)

            MyListView()
                .tabItem {
                    Label("My List", systemImage: "bookmark")
                }
                .tag(2)
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
        .environmentObject(HiddenFilmsStore.shared)
}
