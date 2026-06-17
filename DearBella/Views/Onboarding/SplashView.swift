import SwiftUI

/// The opening splash: the full-bleed SplashBackground graphic, edge to edge,
/// with a gentle fade-in. No text overlay — the image is the complete splash.
/// Timing and the transition into the app are handled by `OnboardingFlowView`.
struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) { appeared = true }
        }
    }
}

#Preview {
    SplashView()
}
