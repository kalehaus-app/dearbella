import Foundation

/// Drives the Swipe feed: a deck of films to fill your list from.
///
/// There's no gate in front of it — it opens already dealing, because a screen
/// asking what you want before showing you anything is a wall in front of the
/// only thing the tab does. The filter changes the pool mid-flow instead.
///
/// Swipe collects; it doesn't decide. Deciding happens in Match, from what's
/// already been saved here. Liking saves to the watchlist, but that's the
/// view's job (it holds the store); this model stays on the deck and history.
@MainActor
final class SwipeFeedViewModel: ObservableObject {
    /// The pool currently being dealt from. Starts on everything, so the deck
    /// is live the moment the tab opens.
    @Published private(set) var filter: SwipeFilter = .everything

    @Published private(set) var deck: [SwipeMovie] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var exhausted = false




    private let history = SwipeHistoryStore.shared
    private let hidden = HiddenFilmsStore.shared
    private let tmdb = TMDBClient.shared
    /// Set once the source's own supply is spent, after which refills come
    /// from popular films rather than stopping.
    private var sourceExhausted = false
    private var page = 0
    private var isFetching = false
    private var runtimeCache: [Int: Int] = [:]

    /// The card currently on top.
    var topMovie: SwipeMovie? { deck.first }

    /// Opens the deck on whatever filter is current. Safe to call repeatedly.
    func loadInitial() async {
        guard deck.isEmpty, !isFetching else { return }
        await loadDeck()
    }

    /// Switches pools mid-flow. The deck is replaced rather than appended to,
    /// since the point of changing filter is to stop seeing the old pool.
    func apply(_ filter: SwipeFilter) async {
        guard filter != self.filter else { return }
        self.filter = filter
        deck = []
        error = nil
        exhausted = false
        sourceExhausted = false
        page = 0
        await loadDeck()
    }

    private func loadDeck() async {
        switch filter {
        case .everything:       await fetchMore()
        case .newReleases:      await loadNewReleases()
        case .genre(let id, _): await loadGenreDeck(id)
        }
    }

    /// Recent releases, straight from TMDB.
    ///
    /// Never falls back to popular films the way the other pools do. Popular
    /// films are mostly old ones, so widening here would quietly fill a shelf
    /// labelled "new releases" with The Godfather — a filter that changes what
    /// it means is worse than one that admits it's empty.
    private func loadNewReleases() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = deck.isEmpty
        defer { isFetching = false; isLoading = false }

        var attempts = 0
        while attempts < 3 {
            attempts += 1
            page += 1
            let movies = await tmdb.recentReleases(page: page)

            if movies.isEmpty {
                if deck.isEmpty && attempts == 1 {
                    error = "Couldn't load films right now. Check your connection and try again."
                } else {
                    exhausted = true
                }
                return
            }

            let fresh = usable(movies)
            if !fresh.isEmpty {
                deck.append(contentsOf: fresh)
                error = nil
                return
            }
        }
        // Genuinely through everything recent — say so rather than widening.
        exhausted = true
    }

    /// Cards worth showing: real art, not already swiped, hidden, or in hand.
    private func usable(_ movies: [TMDBMovie]) -> [SwipeMovie] {
        movies
            .compactMap(SwipeMovie.init(from:))
            .filter { movie in
                movie.posterPath?.isEmpty == false
                    && !history.hasSeen(movie.id)
                    && !hidden.isHidden(id: movie.id)
                    && !deck.contains { $0.id == movie.id }
            }
    }

    /// Genres come straight from TMDB: instant, free, and popularity is a fair
    /// answer to "show me horror" in a way it never is to "wreck me".
    private func loadGenreDeck(_ genreID: Int) async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = deck.isEmpty
        defer { isFetching = false; isLoading = false }

        var attempts = 0
        while attempts < 3 {
            attempts += 1
            page += 1
            let movies = await tmdb.discoverMovies(genreID: genreID, page: page)

            if movies.isEmpty {
                if deck.isEmpty && attempts == 1 {
                    error = "Couldn't load films right now. Check your connection and try again."
                } else {
                    sourceExhausted = true
                }
                return
            }

            let fresh = usable(movies)
            if !fresh.isEmpty {
                deck.append(contentsOf: fresh)
                error = nil
                return
            }
        }
        sourceExhausted = true
    }


    /// Top-up from TMDB's popular list, used once the vibe's curated deck is
    /// spent. Runs through successive pages until it adds unseen films, hits a
    /// page cap (treated as exhausted), or fails.
    func fetchMore() async {
        guard !isFetching, !exhausted else { return }
        isFetching = true
        isLoading = deck.isEmpty
        defer { isFetching = false; isLoading = false }
        await fetchPopular()
    }

    /// The body of `fetchMore`, without the in-flight guard.
    ///
    /// The narrower loaders fall back to popular films when their own pool
    /// comes up empty, and they call this while already holding `isFetching` —
    /// going through `fetchMore` would trip its guard, silently skip the
    /// fallback, and leave an empty deck claiming there was nothing left.
    private func fetchPopular() async {

        var attempts = 0
        while attempts < 5 {
            attempts += 1
            page += 1
            let movies = await tmdb.popularMovies(page: page)

            if movies.isEmpty {
                // First try with an empty deck → treat as a load failure;
                // otherwise we've reached the end of the catalog.
                if deck.isEmpty && attempts == 1 {
                    error = "Couldn't load films right now. Check your connection and try again."
                } else {
                    exhausted = true
                }
                return
            }

            // `usable` also drops posterless entries — TMDB "popular" includes
            // upcoming titles with no art yet, which would otherwise show (and
            // save) as a blank gradient.
            let unseen = usable(movies)

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
        guard deck.count <= 3 else { return }
        Task {
            // Top up from the same pool while it still has films; only widen to
            // popular ones once it's spent.
            if sourceExhausted { await fetchMore() } else { await loadDeck() }
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
