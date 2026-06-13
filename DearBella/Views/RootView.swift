import SwiftUI

/// Top-level router: shows onboarding until it's finished, then the home
/// screen. Because it watches `OnboardingStore`, completing (or resetting)
/// onboarding flips the screen automatically.
struct RootView: View {
    @EnvironmentObject private var store: OnboardingStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                HomePlaceholderView()
            } else {
                OnboardingFlowView()
            }
        }
        .animation(.easeInOut, value: store.hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
        .environmentObject(OnboardingStore())
}
