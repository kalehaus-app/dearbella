import Foundation

/// Manages the swipe deck: fetches batches of popular films, filters out ones
/// already swiped, refills as the user runs low, records likes/passes to the
/// swipe history, and lazily enriches the surfaced cards with runtime.
///
/// Liking saves to the watchlist — but that's done by the view (which holds the
/// WatchlistStore); this model stays focused on the deck + history.
@MainActor
final class SwipeDeckViewModel: ObservableObject {
    @Published private(set) var deck: [SwipeMovie] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var exhausted = false

    private let history = SwipeHistoryStore.shared
    private let hidden = HiddenFilmsStore.shared
    private let tmdb = TMDBClient.shared
    private var page = 0
    private var isFetching = false
    private var runtimeCache: [Int: Int] = [:]

    /// The card currently on top.
    var topMovie: SwipeMovie? { deck.first }

    func loadInitial() async {
        guard deck.isEmpty, !isFetching, !exhausted else { return }
        await fetchMore()
    }

    /// Fetches successive popular pages until it adds unseen films, hits a page
    /// cap (treated as exhausted), or fails.
    func fetchMore() async {
        guard !isFetching, !exhausted else { return }
        isFetching = true
        isLoading = deck.isEmpty
        defer { isFetching = false; isLoading = false }

        var attempts = 0
        while attempts < 5 {
            attempts += 1
            page += 1
            let movies = await tmdb.popularMovies(page: page)

            if movies.isEmpty {
                // First try with an empty deck → treat as a load failure;
                // otherwise we've reached the end of the catalog.
                if deck.isEmpty && attempts == 1 {
                    error = "Couldn't load movies right now. Check your connection (and TMDB key) and try again."
                } else {
                    exhausted = true
                }
                return
            }

            let unseen = movies
                .compactMap(SwipeMovie.init(from:))
                .filter { movie in
                    // Skip films with no poster — TMDB "popular" includes
                    // new/upcoming titles that have no poster yet, which would
                    // otherwise show (and save) as a blank gradient.
                    movie.posterPath?.isEmpty == false
                        && !history.hasSeen(movie.id)
                        && !hidden.isHidden(id: movie.id)
                        && !deck.contains { $0.id == movie.id }
                }

            if !unseen.isEmpty {
                deck.append(contentsOf: unseen)
                error = nil
                return
            }
            // Everything on this page was already swiped — try the next page.
        }

        // Several pages in a row were all already-seen and we have nothing left.
        if deck.isEmpty { exhausted = true }
    }

    func like(_ movie: SwipeMovie) {
        history.recordLike(movie.id)
        advance(past: movie)
    }

    func pass(_ movie: SwipeMovie) {
        history.recordPass(movie.id)
        advance(past: movie)
    }

    /// "Don't suggest this again": keeps the film out of future fetches and
    /// drops it from the deck now, so it doesn't sit there until it's swiped.
    func hide(_ movie: SwipeMovie) {
        hidden.hide(movie)
        history.recordPass(movie.id)
        advance(past: movie)
    }

    private func advance(past movie: SwipeMovie) {
        deck.removeAll { $0.id == movie.id }
        if deck.count <= 3 {
            Task { await fetchMore() }
        }
    }

    /// Lazily loads a card's runtime when it becomes visible (cached).
    func ensureRuntime(for id: Int) async {
        guard runtimeCache[id] == nil else { return }
        guard let runtime = await tmdb.movieRuntime(id: id) else { return }
        runtimeCache[id] = runtime
        if let index = deck.firstIndex(where: { $0.id == id }) {
            deck[index].runtime = runtime
        }
    }
}
