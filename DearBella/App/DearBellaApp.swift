import SwiftUI

/// The entry point of the app.
///
/// `@main` tells the system "start here". The body returns a `Scene`,
/// which is the top-level container for the app's UI. For now it shows
/// `RootView`; as we build the onboarding and home flows we'll swap in
/// real navigation here.
@main
struct DearBellaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
