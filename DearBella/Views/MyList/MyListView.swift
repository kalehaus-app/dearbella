import SwiftUI

/// The full "My List" tab — all saved films from the same on-device watchlist
/// the home preview row uses, as a scrollable poster grid. Tapping a film opens
/// its "where to watch" page (same as elsewhere). Genre filtering and ratings
/// come in a later pass.
struct MyListView: View {
    @EnvironmentObject private var watchlist: WatchlistStore

    /// Cream (#F4EFE6) — the design's text color.
    private let cream = Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("My List")
                    .font(.dearBellaTitle)
                    .foregroundStyle(cream)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if watchlist.films.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(watchlist.films) { film in
                    Link(destination: WatchlistStore.watchURL(for: film)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Color.clear
                                .aspectRatio(0.66, contentMode: .fit)
                                .overlay {
                                    PosterImage(posterPath: film.posterPath, seed: film.title)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text(film.title)
                                .font(.dearBellaBody)
                                .foregroundStyle(cream)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 44))
                .foregroundStyle(cream.opacity(0.5))
            Text("No films saved yet")
                .font(.dearBellaBody)
                .foregroundStyle(cream)
            Text("Tap \u{201C}Start Chat\u{201D} on Home and save films you love — they'll show up here.")
                .font(.dearBellaCaption)
                .foregroundStyle(cream.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MyListView()
        .environmentObject(WatchlistStore())
}
