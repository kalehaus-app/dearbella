import SwiftUI

/// The entry point of the app.
///
/// `@main` tells the system "start here". We create the single
/// `OnboardingStore` here with `@StateObject` (so it lives for the whole app
/// session) and inject it into the view tree with `.environmentObject`, which
/// lets any screen read and update the user's choices.
@main
struct DearBellaApp: App {
    @StateObject private var onboardingStore = OnboardingStore()
    @StateObject private var movieCatalog = MovieCatalog()
    @StateObject private var watchlistStore = WatchlistStore()
    @StateObject private var hiddenFilmsStore = HiddenFilmsStore.shared
    @StateObject private var notifications = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboardingStore)
                .environmentObject(movieCatalog)
                .environmentObject(watchlistStore)
                .environmentObject(hiddenFilmsStore)
                .environmentObject(notifications)
                // Registers the delegate before launch finishes, so a reminder
                // tapped from a cold start still routes to tonight's pick.
                .task { notifications.start() }
        }
    }
}
