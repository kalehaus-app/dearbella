import SwiftUI

/// The opening "Dear Bella" screen (wireframe Frame 52): the title above a
/// teal card holding the red clapperboard. Shown briefly, then the flow
/// advances to the intro carousel.
struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                Spacer().frame(height: 32)

                Text("Dear Bella")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.55, green: 0.70, blue: 0.70))
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay {
                        Image(systemName: "film.fill")
                            .font(.system(size: 96))
                            .foregroundStyle(Theme.accent)
                            .rotationEffect(.degrees(-8))
                    }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SplashView()
}
