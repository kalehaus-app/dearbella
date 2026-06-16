import Foundation

/// Drives the "What should I watch tonight?" conversation as a small state
/// machine: pick a mood → pick a feeling → see picks → refine or get more.
@MainActor
final class ChatViewModel: ObservableObject {

    enum Phase {
        case mood       // choosing what they're in the mood for
        case feeling    // choosing how they feel
        case results    // picks are showing
        case refine     // typing a reference film
    }

    struct Entry: Identifiable {
        let id = UUID()
        let kind: Kind
        enum Kind {
            case bella(String)
            case user(String)
            case picks([RecommendedFilm])
        }
    }

    @Published private(set) var entries: [Entry] = []
    @Published private(set) var phase: Phase = .mood
    @Published private(set) var isLoading = false
    @Published private(set) var hasResults = false
    @Published var referenceText = ""

    let context: TasteContext
    let moodOptions: [String]
    let feelingOptions = [
        "Cozy & low-key", "Wired & restless", "Heartbroken",
        "Need a laugh", "Adventurous", "Nostalgic",
    ]

    private var moodPick: String?
    private var feeling: String?
    private var shownTitles: [String] = []
    private let engine = RecommendationEngine.shared

    init(context: TasteContext) {
        self.context = context

        // Mood pills: the user's saved genres plus a few vibe words, de-duplicated.
        var seen = Set<String>()
        var options: [String] = []
        for option in context.genres + ["Funny", "Scary", "Mind-bending", "Romantic"] {
            if seen.insert(option).inserted { options.append(option) }
        }
        moodOptions = Array(options.prefix(8))

        entries.append(Entry(kind: .bella("What are you in the mood for tonight?")))
    }

    func pickMood(_ mood: String) {
        moodPick = mood
        entries.append(Entry(kind: .user(mood)))
        entries.append(Entry(kind: .bella("Good taste. And how are you feeling?")))
        phase = .feeling
    }

    func pickFeeling(_ feeling: String) {
        self.feeling = feeling
        entries.append(Entry(kind: .user(feeling)))
        Task { await generate(reference: nil) }
    }

    func askForReference() {
        phase = .refine
        entries.append(Entry(kind: .bella("No worries. Name a film you'd want something like, and I'll try again.")))
    }

    func submitReference() {
        let text = referenceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        referenceText = ""
        entries.append(Entry(kind: .user("Movies like \(text)")))
        Task { await generate(reference: text) }
    }

    func moreSuggestions() {
        Task { await generate(reference: nil) }
    }

    private func generate(reference: String?) async {
        isLoading = true
        hasResults = false
        phase = .results
        defer { isLoading = false }

        do {
            let result = try await engine.recommend(
                context: context,
                moodPick: moodPick,
                feeling: feeling,
                referenceFilm: reference,
                exclude: shownTitles
            )
            entries.append(Entry(kind: .bella(result.intro)))
            entries.append(Entry(kind: .picks(result.films)))
            entries.append(Entry(kind: .bella("What do you think? Tap one to save it to your list.")))
            shownTitles.append(contentsOf: result.films.map(\.title))
            hasResults = true
        } catch {
            entries.append(Entry(kind: .bella("Hmm, I couldn't reach my brain just now — check your connection (or that your Claude API key is set) and try again.")))
            hasResults = true
        }
    }
}
