import SwiftUI

/// The opening "Dear Bella" screen (wireframe Frame 52): a full-bleed,
/// slowly-zooming background image with the logo over a dark scrim. Shown
/// briefly, then the flow advances to the intro carousel.
struct SplashView: View {
    var body: some View {
        ZStack {
            KenBurnsImage(imageName: "SplashBackground")

            // Dark scrim so the logo stays legible over any image.
            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                Text("Dear Bella")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                Spacer().frame(height: 120)
            }
        }
    }
}

#Preview {
    SplashView()
}
