import SwiftUI

/// The "My List" tab: the saved-films grid plus three AI-assisted pieces built
/// as separate components — taste insight (#3), genre filter pills (#1), and
/// "find more like my list" recommendations (#2). The AI pieces only call the
/// API on an explicit tap.
struct MyListView: View {
    @EnvironmentObject private var watchlist: WatchlistStore
    @StateObject private var viewModel = MyListViewModel()

    @State private var selectedGenre: String?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    /// Saved films as taste input for the AI features.
    private var tasteContext: TasteContext {
        TasteContext(
            genres: presentGenres,
            topFilms: watchlist.films.map(\.title)
        )
    }

    /// Genres present among saved films (so we never show an empty filter).
    private var presentGenres: [String] {
        Array(Set(watchlist.films.flatMap(\.genres))).sorted()
    }

    /// The grid contents after applying the selected genre filter.
    private var filteredFilms: [SavedFilm] {
        guard let genre = selectedGenre else { return watchlist.films }
        return watchlist.films.filter { $0.genres.contains(genre) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if watchlist.films.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    emptyState
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        TasteInsightSection(viewModel: viewModel, context: tasteContext)
                        if !presentGenres.isEmpty {
                            GenreFilterPills(genres: presentGenres, selected: $selectedGenre)
                        }
                        grid
                        Divider().background(Theme.cream.opacity(0.1)).padding(.horizontal, 20)
                        RecommendationsSection(viewModel: viewModel, context: tasteContext)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var header: some View {
        Text("My List")
            .font(.dearBellaTitle)
            .foregroundStyle(Theme.cream)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredFilms) { film in
                Link(destination: WatchlistStore.watchURL(for: film)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Color.clear
                            .aspectRatio(0.66, contentMode: .fit)
                            .overlay { PosterImage(posterPath: film.posterPath, seed: film.title) }
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text(film.title)
                            .font(.dearBellaBody)
                            .foregroundStyle(Theme.cream)
                            .lineLimit(2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 44))
                .foregroundStyle(Theme.cream.opacity(0.5))
            Text("No films saved yet")
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream)
            Text("Tap \u{201C}Start Chat\u{201D} on Home and save films you love — they'll show up here.")
                .font(.dearBellaCaption)
                .foregroundStyle(Theme.cream.opacity(0.6))
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
