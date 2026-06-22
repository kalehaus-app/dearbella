import SwiftUI
import WebKit

/// A WebKit-backed YouTube player. Embeds the trailer in an HTML iframe and
/// plays it inline (no third-party packages). Used only by `MovieDetailView`'s
/// "Play Trailer" button.
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
        context.coordinator.loadedKey = nil
        return webView
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        /// Tracks the last key we loaded so SwiftUI re-renders don't restart it.
        var loadedKey: String?
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedKey != videoKey else { return }
        context.coordinator.loadedKey = videoKey

        // Load the embed inside an HTML iframe with a real origin baseURL, rather
        // than navigating to the embed URL directly — that gives YouTube a valid
        // origin/referer and avoids the "153" player configuration error. Using
        // youtube.com (not the stricter -nocookie host) avoids "152" unavailable.
        let html = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              html, body { margin: 0; padding: 0; background: #000; height: 100%; }
              iframe { display: block; width: 100%; height: 100%; border: 0; }
            </style>
          </head>
          <body>
            <iframe
              width="100%"
              height="100%"
              src="https://www.youtube.com/embed/\(videoKey)?playsinline=1&autoplay=1&rel=0&modestbranding=1&enablejsapi=1"
              frameborder="0"
              allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
              allowfullscreen>
            </iframe>
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
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
