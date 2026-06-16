import Foundation

/// Generates the personalized "Curated for you" home cards via Claude, caching
/// them on-device. Falls back silently (leaving `curatedCards` empty) when
/// there's no Claude key or the call fails — the home screen then shows its
/// built-in static cards.
@MainActor
final class HomeFeedModel: ObservableObject {
    @Published private(set) var curatedCards: [ResolvedCuratedCard] = []

    private let cacheKey = "home.curatedCards"
    private var attempted = false

    init() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([ResolvedCuratedCard].self, from: data) {
            curatedCards = cached
        }
    }

    func loadCuratedIfNeeded(context: TasteContext) async {
        guard !attempted, ClaudeClient.shared.hasAPIKey else { return }
        attempted = true

        do {
            let cards = try await RecommendationEngine.shared.curatedCards(context: context)
            guard !cards.isEmpty else { return }
            curatedCards = cards
            if let data = try? JSONEncoder().encode(cards) {
                UserDefaults.standard.set(data, forKey: cacheKey)
            }
        } catch {
            // Keep the static fallback cards.
        }
    }
}
