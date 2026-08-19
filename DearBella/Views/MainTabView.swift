import SwiftUI

/// Wraps the main app in a bottom tab bar: Home to see what's on, Discover to
/// fill your list, My List to decide from it. Home is first, so after
/// onboarding the app still lands on the dashboard exactly as before.
///
/// Three tabs, and one job each. Matching isn't a tab because it isn't a place
/// you browse — it's what you do with a list once you have one, so it starts
/// from My List. Bracket and Chat stay reachable from Home.
struct MainTabView: View {
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppRouter.Tab.home)

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "rectangle.stack")
                }
                .tag(AppRouter.Tab.discover)

            MyListView()
                .tabItem {
                    Label("My List", systemImage: "bookmark")
                }
                .tag(AppRouter.Tab.myList)
        }
        .tint(Theme.highlight)
        // A reminder promises tonight's pick, so it has to land on the tab
        // that shows it, whichever tab was open last.
        .onChange(of: notifications.didOpenFromReminder) { _, fromReminder in
            if fromReminder { router.tab = .home }
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
        .environmentObject(AppRouter())
}
