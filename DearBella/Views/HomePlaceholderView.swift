import SwiftUI

/// Temporary landing screen shown after onboarding completes.
///
/// It confirms the saved choices stuck, and offers a "Reset" button so you can
/// re-run the onboarding flow while testing. The real home feed (curated
/// cards, vibe pills, "Things to do") replaces this in Step 3.
struct HomePlaceholderView: View {
    @EnvironmentObject private var store: OnboardingStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "film.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)

                Text("Welcome to Dear Bella")
                    .font(.title).bold()
                    .foregroundStyle(Theme.textPrimary)

                Text("\(store.selectedGenreIDs.count) genres · \(store.selectedFilmIDs.count) films saved")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)

                Text("Home feed comes in Step 3")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)

                Button("Reset onboarding") {
                    withAnimation { store.resetOnboarding() }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

#Preview {
    HomePlaceholderView()
        .environmentObject(OnboardingStore())
}
