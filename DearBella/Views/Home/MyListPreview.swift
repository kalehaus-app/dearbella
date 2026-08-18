import SwiftUI

/// The Home dashboard's "My List" preview row. A standalone view with its own
/// `@EnvironmentObject` subscription to the shared `WatchlistStore`, so it
/// updates live whenever the watchlist changes (e.g. a swipe-like) — the same
/// way the My List tab observes it.
struct MyListPreview: View {
    @EnvironmentObject private var watchlist: WatchlistStore

    /// Only films still waiting to be watched. Home is a "what do I watch
    /// tonight" surface, so films already seen or archived would be noise.
    private var upcoming: [SavedFilm] {
        watchlist.films(in: .watchlist)
    }

    var body: some View {
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "My List")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(upcoming) { film in
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
