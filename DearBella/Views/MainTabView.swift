import SwiftUI

/// Wraps the main app in a bottom tab bar: Home to see what's on, Swipe to
/// fill your list, My List to decide from it. Home is first, so after
/// onboarding the app still lands on the dashboard exactly as before.
///
/// Three tabs, and one job each. Matching isn't a tab because it isn't a place
/// you browse — it's what you do with a list once you have one, so it starts
/// from My List. Bracket and Chat stay reachable from Home.
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

            SwipeView()
                .tabItem {
                    Label("Swipe", systemImage: "rectangle.stack")
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
