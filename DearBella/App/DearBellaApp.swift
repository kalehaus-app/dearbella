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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(onboardingStore)
        }
    }
}
