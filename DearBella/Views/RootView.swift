import SwiftUI

/// Temporary placeholder shown when the app launches.
///
/// This exists so we can confirm the project builds and runs on the
/// simulator before we start building real screens. In Step 2 we'll
/// replace this with the onboarding flow (splash → genres → top 5 films
/// → "Great picks!").
struct RootView: View {
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Stand-in for the clapperboard logo until we add real art.
                Image(systemName: "film.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.accent)

                VStack(spacing: 8) {
                    Text("Dear Bella")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Your cinematic mood companion")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                }

                Text("Project scaffolded ✓")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)
            }
            .padding()
        }
    }
}

#Preview {
    RootView()
}
