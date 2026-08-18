import Foundation

/// Drives the 8-movie, 3-round single-elimination bracket: genre pick → fetch
/// 8 → matchups → winner. Reuses `SwipeMovie` (TMDB-backed, savable),
/// `TMDBClient` (proxy), and `ClaudeClient` (proxy) for Bella's blurb.
@MainActor
final class BracketViewModel: ObservableObject {
    enum Stage: Equatable {
        case genre
        case loading
        case playing
        case finished
        case failed
    }

    @Published private(set) var stage: Stage = .genre
    @Published private(set) var contestants: [SwipeMovie] = []   // current round
    @Published private(set) var matchupIndex = 0
    @Published private(set) var roundNumber = 1                  // 1...3
    @Published private(set) var winner: SwipeMovie?
    @Published private(set) var bellaBlurb: String?
    @Published private(set) var isLoadingBlurb = false

    private var nextRound: [SwipeMovie] = []
    private let tmdb = TMDBClient.shared
    private let hidden = HiddenFilmsStore.shared

    let totalRounds = 3

    var matchupsInRound: Int { contestants.count / 2 }
    var leftMovie: SwipeMovie? { contestants[safe: matchupIndex * 2] }
    var rightMovie: SwipeMovie? { contestants[safe: matchupIndex * 2 + 1] }

    /// "Round 1" / "Semifinals" / "Final" by remaining contestants.
    var roundName: String {
        switch contestants.count {
        case 2: return "Final"
        case 4: return "Semifinals"
        default: return "Round \(roundNumber)"
        }
    }

    // MARK: - Lifecycle

    func start(genreID: Int) async {
        stage = .loading
        winner = nil
        bellaBlurb = nil
        nextRound = []
        matchupIndex = 0
        roundNumber = 1

        var pool: [SwipeMovie] = []
        var seen = Set<Int>()
        for page in 1...2 {
            let movies = await tmdb.discoverMovies(genreID: genreID, page: page)
            for movie in movies.compactMap(SwipeMovie.init(from:))
            where movie.posterPath?.isEmpty == false && !hidden.isHidden(id: movie.id) {
                if seen.insert(movie.id).inserted { pool.append(movie) }
            }
            if pool.count >= 24 { break }
        }

        guard pool.count >= 8 else {
            stage = .failed
            return
        }

        // Random 8 from the most popular ~30 so the bracket varies per run.
        contestants = Array(pool.prefix(30).shuffled().prefix(8))
        stage = .playing
    }

    func choose(_ movie: SwipeMovie) {
        guard stage == .playing else { return }
        nextRound.append(movie)

        if matchupIndex + 1 < matchupsInRound {
            matchupIndex += 1
            return
        }

        // Round complete.
        if nextRound.count == 1 {
            winner = nextRound.first
            stage = .finished
            Task { await loadBlurb() }
        } else {
            contestants = nextRound
            nextRound = []
            matchupIndex = 0
            roundNumber += 1
        }
    }

    func reset() {
        stage = .genre
        contestants = []
        nextRound = []
        matchupIndex = 0
        roundNumber = 1
        winner = nil
        bellaBlurb = nil
        isLoadingBlurb = false
    }

    // MARK: - Bella blurb

    private func loadBlurb() async {
        guard let winner else { return }
        isLoadingBlurb = true
        defer { isLoadingBlurb = false }
        bellaBlurb = try? await BracketBella.blurb(title: winner.title, overview: winner.overview)
        // nil on failure → graceful fallback (winner shown without the line).
    }
}

/// One Claude call (via the proxy) for the winner's witty one-liner.
enum BracketBella {
    private struct Blurb: Decodable { let blurb: String }

    static func blurb(title: String, overview: String) async throws -> String {
        let system = """
        You are DearBella, a witty, film-literate movie recommender with the taste \
        of a cinephile best friend — warm, clever, and concise.
        """
        let prompt = """
        The user just crowned "\(title)" the winner of tonight's movie bracket.
        Overview: \(overview)
        In one short, witty sentence in your voice, tell them why it's a great pick
        for tonight.
        """
        let tool = ClaudeTool(
            name: "present_blurb",
            description: "Present one witty sentence about the winning film.",
            inputSchema: claudeJSONSchema("""
            {
              "type": "object",
              "properties": { "blurb": { "type": "string" } },
              "required": ["blurb"]
            }
            """)
        )
        return try await ClaudeClient.shared.generate(
            system: system,
            userPrompt: prompt,
            tool: tool,
            as: Blurb.self
        ).blurb
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
