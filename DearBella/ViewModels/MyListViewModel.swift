import Foundation

/// Backs the AI features on the My List tab: the on-demand taste summary (#3)
/// and the "find more like my list" recommendations (#2). Both fire only when
/// the user taps a button — never automatically — to avoid surprise API costs.
@MainActor
final class MyListViewModel: ObservableObject {

    // Recommendations (#2)
    @Published private(set) var recommendations: [RecommendedFilm] = []
    @Published private(set) var isLoadingRecs = false
    @Published private(set) var recsError: String?

    // Taste summary (#3)
    @Published private(set) var tasteSummary: String?
    @Published private(set) var isLoadingSummary = false
    @Published private(set) var summaryError: String?

    private let engine = RecommendationEngine.shared
    private let summaryCacheKey = "mylist.tasteSummary"

    init() {
        // Show the cached summary if we generated one previously.
        tasteSummary = UserDefaults.standard.string(forKey: summaryCacheKey)
    }

    func generateRecommendations(context: TasteContext) async {
        isLoadingRecs = true
        recsError = nil
        defer { isLoadingRecs = false }

        do {
            let result = try await engine.recommend(
                context: context,
                moodPick: nil,
                feeling: nil,
                referenceFilm: nil,
                exclude: context.topFilms        // don't re-suggest saved films
            )
            recommendations = result.films
            if recommendations.isEmpty {
                recsError = "DearBella couldn't find new picks just now — try again."
            }
        } catch {
            recsError = "Couldn't reach DearBella right now. Check your connection (or that your Claude API key is set) and try again."
        }
    }

    func generateTasteSummary(context: TasteContext) async {
        isLoadingSummary = true
        summaryError = nil
        defer { isLoadingSummary = false }

        do {
            let summary = try await engine.tasteSummary(context: context)
            tasteSummary = summary
            UserDefaults.standard.set(summary, forKey: summaryCacheKey)
        } catch {
            summaryError = "Couldn't read your taste right now — try again."
        }
    }
}
