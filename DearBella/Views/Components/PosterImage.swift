import SwiftUI
import UIKit

/// Displays a TMDB poster, fading in once downloaded. While loading — or if
/// there's no path, or the art genuinely doesn't exist — it shows the
/// placeholder gradient so a card is never empty. `seed` keeps that fallback
/// gradient stable for a given film.
///
/// Backed by `PosterCache` rather than `AsyncImage`. `AsyncImage` kept no
/// usable cache and treated a cancelled load as a permanent failure, so saving
/// a film — which re-renders the list and cancels its in-flight loads — left
/// posters stuck on the gradient until the app was force-quit.
struct PosterImage: View {
    let posterPath: String?
    let seed: String
    var size: String = "w500"

    @State private var image: UIImage?

    private var url: URL? {
        TMDBClient.posterURL(path: posterPath, size: size)
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                PlaceholderArt.gradient(for: seed)
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else {
            image = nil
            return
        }

        // Render straight from memory when we already have it: no placeholder
        // flash, no animation, correct on the first frame.
        if let cached = PosterCache.shared.cachedImage(for: url) {
            image = cached
            return
        }

        image = nil

        let loaded = await PosterCache.shared.image(for: url)

        // If the card was recycled onto a different film while this was in
        // flight, SwiftUI has already cancelled us and started the load for the
        // new poster. The code after an `await` still runs when a task is
        // cancelled, so without this check the stale image would overwrite it.
        guard !Task.isCancelled, let loaded else { return }

        withAnimation(.easeIn(duration: 0.25)) {
            image = loaded
        }
    }
}
