import SwiftUI

/// The Home dashboard's "My List" preview row. A standalone view with its own
/// `@EnvironmentObject` subscription to the shared `WatchlistStore`, so it
/// updates live whenever the watchlist changes (e.g. a swipe-like) — the same
/// way the My List tab observes it.
struct MyListPreview: View {
    @EnvironmentObject private var watchlist: WatchlistStore

    var body: some View {
        if !watchlist.films.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "My List")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(watchlist.films) { film in
                            Link(destination: WatchlistStore.watchURL(for: film)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    PosterImage(posterPath: film.posterPath, seed: film.title)
                                        .frame(width: 110, height: 165)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(film.title)
                                        .font(.dearBellaCaption)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .frame(width: 110, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
