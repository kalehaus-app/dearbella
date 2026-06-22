import SwiftUI
import WebKit

/// A WebKit-backed YouTube player. Loads the privacy-friendly embed URL for a
/// video key and plays it inline (no third-party packages). Used only by
/// `MovieDetailView`'s "Play Trailer" button.
struct YouTubeWebView: UIViewRepresentable {
    let videoKey: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Play inside the web view rather than kicking out to full-screen native
        // playback, and allow autoplay so the trailer starts on present.
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: "https://www.youtube-nocookie.com/embed/\(videoKey)?playsinline=1&autoplay=1&rel=0") else {
            return
        }
        // Reload only if the key changed, so SwiftUI re-renders don't restart it.
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

/// Full-screen container that presents the YouTube trailer on true black with a
/// cyan close button, matching the DearBella design system.
struct TrailerPlayerView: View {
    let videoKey: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.background.ignoresSafeArea()

            YouTubeWebView(videoKey: videoKey)
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.cyan)
                    .padding(10)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}
