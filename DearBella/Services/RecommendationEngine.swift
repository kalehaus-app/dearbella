import Foundation

/// Turns a taste profile + mood into real, poster-backed film recommendations,
/// and generates the personalized "Curated for you" home cards. Uses Claude for
/// the picks (and the witty voice) and TMDB to resolve each title to art.
struct RecommendationEngine {
    static let shared = RecommendationEngine()

    private let claude = ClaudeClient.shared
    private let tmdb = TMDBClient.shared

    private let persona = """
    You are DearBella, a witty, film-literate movie recommender with the taste of \
    a cinephile best friend. Your voice is warm, clever, and concise — the energy \
    of "Films you'll love if you liked Carrie." You never pad. You only recommend \
    real films that actually exist. Always tailor picks to the user's taste profile \
    and current mood, and never recommend a film in the exclude list.
    """

    // MARK: - Recommendations

    func recommend(
        context: TasteContext,
        moodPick: String?,
        feeling: String?,
        referenceFilm: String?,
        exclude: [String]
    ) async throws -> RecommendationResult {
        let prompt = """
        Taste profile:
        - Favorite genres: \(list(context.genres))
        - Top films: \(list(context.topFilms))

        Current request:
        - In the mood for: \(moodPick ?? "anything good")
        - How they're feeling: \(feeling ?? "not specified")
        - Wants something similar to: \(referenceFilm ?? "not specified")
        - Do NOT recommend (already shown or owned): \(list(exclude))

        Recommend exactly 3 films that fit. One witty sentence per reason.
        """

        let tool = ClaudeTool(
            name: "present_recommendations",
            description: "Present exactly 3 personalized film recommendations.",
            inputSchema: claudeJSONSchema("""
            {
              "type": "object",
              "properties": {
                "intro": { "type": "string", "description": "A short, witty one-liner introducing the picks, in DearBella's voice." },
                "films": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "title": { "type": "string" },
                      "year": { "type": "integer" },
                      "reason": { "type": "string", "description": "One witty, personal sentence." }
                    },
                    "required": ["title", "year", "reason"]
                  }
                }
              },
              "required": ["intro", "films"]
            }
            """)
        )

        let output = try await claude.generate(
            system: persona,
            userPrompt: prompt,
            tool: tool,
            as: RecommendationToolInput.self
        )

        var resolved: [RecommendedFilm] = []
        for film in output.films {
            let movie = await tmdb.searchMovie(title: film.title, year: film.year)
            resolved.append(
                RecommendedFilm(
                    title: film.title,
                    year: film.year,
                    reason: film.reason,
                    posterPath: movie?.posterPath,
                    tmdbID: movie?.id
                )
            )
        }
        return RecommendationResult(intro: output.intro, films: resolved)
    }

    // MARK: - Curated home cards

    func curatedCards(context: TasteContext) async throws -> [ResolvedCuratedCard] {
        let prompt = """
        Taste profile:
        - Favorite genres: \(list(context.genres))
        - Top films: \(list(context.topFilms))

        Generate 4 personalized "Curated for you" home-feed cards. Each card has a \
        witty title (like "Films you'll love if you liked Carrie" or "Tonight's \
        mood: dreamy & disoriented") and one representative real film whose poster \
        will back the card. Tailor them to this user's taste.
        """

        let tool = ClaudeTool(
            name: "present_curated",
            description: "Present 4 personalized curated home cards.",
            inputSchema: claudeJSONSchema("""
            {
              "type": "object",
              "properties": {
                "cards": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "title": { "type": "string", "description": "Witty card caption." },
                      "filmTitle": { "type": "string", "description": "Representative real film." },
                      "filmYear": { "type": "integer" }
                    },
                    "required": ["title", "filmTitle"]
                  }
                }
              },
              "required": ["cards"]
            }
            """)
        )

        let output = try await claude.generate(
            system: persona,
            userPrompt: prompt,
            tool: tool,
            as: CuratedToolInput.self
        )

        var cards: [ResolvedCuratedCard] = []
        for card in output.cards {
            let movie = await tmdb.searchMovie(title: card.filmTitle, year: card.filmYear)
            cards.append(ResolvedCuratedCard(caption: card.title, posterPath: movie?.posterPath))
        }
        return cards
    }

    private func list(_ items: [String]) -> String {
        items.isEmpty ? "none" : items.joined(separator: ", ")
    }
}
