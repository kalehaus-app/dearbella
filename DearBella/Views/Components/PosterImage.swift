import SwiftUI

/// Displays a TMDB poster, fading in once downloaded. While loading — or if
/// there's no path, no key, or no network — it shows the placeholder gradient
/// so a card is never empty. `seed` keeps the fallback gradient stable.
struct PosterImage: View {
    let posterPath: String?
    let seed: String

    var body: some View {
        if let url = TMDBClient.posterURL(path: posterPath) {
            AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    PlaceholderArt.gradient(for: seed)
                }
            }
        } else {
            PlaceholderArt.gradient(for: seed)
        }
    }
}
