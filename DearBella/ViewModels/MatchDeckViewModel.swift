import Foundation

/// Drives Match: a vibe is chosen, Bella deals a deck to fit it, and a few
/// cards later the round resolves into one film.
///
/// The deck is Claude-curated per vibe rather than TMDB's popularity list, so
/// every card is already in the right neighbourhood — the old deck showed
/// whatever was trending and hoped. When a vibe's deck runs dry it refills from
/// popular films rather than dead-ending, since a deck that stops is worse than
/// a deck that drifts.
///
/// Liking saves to the watchlist, but that's the view's job (it holds the
/// store); this model stays focused on the deck, the round, and history.
@MainActor
final class MatchDeckViewModel: ObservableObject {
    /// The chosen vibe. Nil means the picker is still showing.
    @Published private(set) var vibe: MatchVibe?

    @Published private(set) var deck: [SwipeMovie] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var exhausted = false

    /// Films liked in this sitting. Swiping that only ever adds to a list is
    /// a deferred decision; once enough cards are in, these become the
    /// shortlist Bella picks tonight's film from.
    @Published private(set) var sessionLikes: [SwipeMovie] = []
    @Published private(set) var isMatchReady = false

    /// Cards swiped since the last match.
    private var swipesThisSession = 0

    /// Short on purpose. The payoff has to arrive before swiping starts to
    /// feel like a chore, and a fast decision is the whole point.
    private let swipesPerMatch = 5

    /// A match needs a real choice behind it — picking "the one film you
    /// liked" isn't a decision, it's an echo.
    private let likesPerMatch = 2

    private let history = SwipeHistoryStore.shared
    private let hidden = HiddenFilmsStore.shared
    private let tmdb = TMDBClient.shared
    private let engine = RecommendationEngine.shared

    /// Taste profile for the deck request, handed in by the view.
    private var context = TasteContext(films: [])

    /// Set once the vibe's curated deck is spent, after which refills come
    /// from popular films rather than stopping.
    private var vibeExhausted = false
    private var page = 0
    private var isFetching = false
    private var runtimeCache: [Int: Int] = [:]

    /// The card currently on top.
    var topMovie: SwipeMovie? { deck.first }

    /// Chooses a vibe and deals its deck.
    func choose(_ vibe: MatchVibe, context: TasteContext) async {
        self.vibe = vibe
        self.context = context
        deck = []
        error = nil
        exhausted = false
        vibeExhausted = false
        page = 0
        startNewRound()
        await loadVibeDeck()
    }

    /// Back to the picker, so a different mood is one tap away.
    func changeVibe() {
        vibe = nil
        deck = []
        error = nil
        exhausted = false
        startNewRound()
    }

    /// Asks Bella for films fitting the vibe. On failure the deck falls back to
    /// popular films rather than leaving an empty screen — a worse deck beats
    /// no deck when someone is standing there wanting to watch something.
    private func loadVibeDeck() async {
        guard let vibe, !isFetching else { return }
        isFetching = true
        isLoading = true
        defer { isFetching = false; isLoading = false }

        do {
            let films = try await engine.matchDeck(
                vibe: vibe,
                context: context,
                exclude: deck.map(\.title)
            )
            let fresh = films.filter { !history.hasSeen($0.id) && !hidden.isHidden(id: $0.id) }

            if fresh.isEmpty {
                vibeExhausted = true
                await fetchMore()
            } else {
                deck = fresh
            }
        } catch {
            vibeExhausted = true
            await fetchMore()
        }
    }

    /// Top-up from TMDB's popular list, used once the vibe's curated deck is
    /// spent. Runs through successive pages until it adds unseen films, hits a
    /// page cap (treated as exhausted), or fails.
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
                    error = "Couldn't load films right now. Check your connection and try again."
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

    /// Offers a verdict once the round is up and there's something to choose
    /// between. Falling short of either bar just carries on dealing cards
    /// rather than interrupting — there's nothing to decide between one film,
    /// and nothing at all to decide between none.
    private func countSwipe() {
        swipesThisSession += 1
        guard swipesThisSession >= swipesPerMatch,
              sessionLikes.count >= likesPerMatch else { return }
        isMatchReady = true
    }

    /// Called when the match is dismissed: clears the shortlist so the next
    /// round starts fresh rather than re-picking from old likes.
    func startNewRound() {
        isMatchReady = false
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
        guard deck.count <= 3 else { return }
        Task {
            // Ask Bella for more of the same vibe while she still has some;
            // only fall back to popular films once she's out.
            if vibe != nil && !vibeExhausted {
                await loadVibeDeck()
            } else {
                await fetchMore()
            }
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
