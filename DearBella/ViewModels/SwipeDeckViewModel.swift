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

    /// Films liked in this sitting. Swiping that only ever adds to a list is
    /// a deferred decision; once enough cards are in, these become the
    /// shortlist Bella picks tonight's film from.
    @Published private(set) var sessionLikes: [SwipeMovie] = []
    @Published private(set) var isVerdictReady = false

    /// Cards swiped since the last verdict.
    private var swipesThisSession = 0

    /// Enough cards to have learned something, few enough to still feel quick.
    private let swipesPerVerdict = 12

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
        sessionLikes.append(movie)
        countSwipe()
        advance(past: movie)
    }

    func pass(_ movie: SwipeMovie) {
        history.recordPass(movie.id)
        countSwipe()
        advance(past: movie)
    }

    /// Offers a verdict once the round is up, provided there's something to
    /// choose between. With no likes there is nothing to decide, so the deck
    /// just carries on rather than interrupting for an empty result.
    private func countSwipe() {
        swipesThisSession += 1
        guard swipesThisSession >= swipesPerVerdict, !sessionLikes.isEmpty else { return }
        isVerdictReady = true
    }

    /// Called when the verdict is dismissed: clears the shortlist so the next
    /// round starts fresh rather than re-picking from old likes.
    func startNewRound() {
        isVerdictReady = false
        swipesThisSession = 0
        sessionLikes = []
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
