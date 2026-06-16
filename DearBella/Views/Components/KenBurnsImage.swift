import SwiftUI
import UIKit

/// A full-bleed background image with a slow, continuous "Ken Burns" zoom.
///
/// It looks for an image named `imageName` in the asset catalog. Until you add
/// one, it shows a cinematic gradient fallback so the splash still looks good.
/// To use a real photo: in Xcode open `Assets.xcassets`, select the
/// `SplashBackground` image set, and drag your image into it.
///
/// (Later you can swap this whole view for a looping video without touching
/// the splash screen's layout.)
struct KenBurnsImage: View {
    let imageName: String

    @State private var zoomedIn = false

    var body: some View {
        GeometryReader { geo in
            content
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(zoomedIn ? 1.18 : 1.0)
                .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                zoomedIn = true
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName).resizable()
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.16),
                    Color(red: 0.32, green: 0.10, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
