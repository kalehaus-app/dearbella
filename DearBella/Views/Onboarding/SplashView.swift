import SwiftUI
import UIKit

/// The opening splash: the full-bleed SplashBackground graphic, edge to edge,
/// with a gentle fade-in. Timing and the transition into the app are handled
/// by `OnboardingFlowView`.
///
/// The `SplashBackground` image set is currently empty — it has a
/// `Contents.json` and no image — so this falls back to the wordmark rather
/// than showing a black screen for a second and a half and looking broken.
/// Drop artwork into that image set in Xcode and it takes over automatically.
struct SplashView: View {
    @State private var appeared = false

    private var hasArtwork: Bool {
        UIImage(named: "SplashBackground") != nil
    }

    var body: some View {
        ZStack {
            if hasArtwork {
                GeometryReader { geo in
                    Image("SplashBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            } else {
                wordmark
            }
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) { appeared = true }
        }
    }

    private var wordmark: some View {
        ZStack {
            Theme.background

            VStack(spacing: 10) {
                Text("Dear Bella")
                    .font(.dmSerif(44))
                    .foregroundStyle(Theme.cream)
                Text("What should I watch tonight?")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cyan)
            }
        }
    }
}

#Preview {
    SplashView()
}
