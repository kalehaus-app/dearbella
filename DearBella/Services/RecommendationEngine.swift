import Foundation

/// Turns a taste profile + mood into real, poster-backed film recommendations,
/// the daily pick, and the taste summary. Uses Claude for the picks (and the
/// witty voice) and TMDB to resolve each title to art.
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

    The taste profile is built from what they've actually recorded, so weigh it \
    in that order: their own notes are the most specific signal, then films they \
    loved or rated highly, then what they merely saved. Films they did not enjoy \
    are a hard steer away — don't recommend those films, and don't recommend \
    near-neighbours of them either. When their history clearly points somewhere, \
    let the reason say so ("you rated Hereditary 5 stars, so…") rather than \
    describing the film in the abstract.
    """

    // MARK: - Recommendations

    func recommend(
        context: TasteContext,
        moodPick: String?,
        feeling: String?,
        referenceFilm: String?,
        exclude: [String]
    ) async throws -> RecommendationResult {
        let avoid = await Self.blocked(context, plus: exclude)

        let prompt = """
        Taste profile:
        \(profile(context))

        Current request:
        - In the mood for: \(moodPick ?? "anything good")
        - How they're feeling: \(feeling ?? "not specified")
        - Wants something similar to: \(referenceFilm ?? "not specified")
        - Do NOT recommend (already shown, saved, hidden, or disliked): \(list(avoid))

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
                      "title": { "type": "string", "description": "The film's exact release title and nothing else — no director name, no quotation marks, no year, no commentary." },
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
                    tmdbID: movie?.id,
                    genres: movie?.genreNames ?? []
                )
            )
        }
        return RecommendationResult(intro: output.intro, films: resolved)
    }

    // MARK: - Find me something

    /// One film, chosen from what the user says they love, with a reason that
    /// answers them rather than describing the film.
    ///
    /// The reason is the point. "You liked Once Upon a Time in Hollywood for
    /// the old-Hollywood texture, so watch this" is a friend talking; a plot
    /// summary is a catalogue. So the prompt is told to quote their own words
    /// back and to justify the pick against them.
    func findSomething(
        taste: TasteProfile,
        context: TasteContext,
        exclude: [String]
    ) async throws -> RecommendedFilm? {
        let avoid = await Self.blocked(context, plus: exclude)

        let director = taste.director.trimmingCharacters(in: .whitespacesAndNewlines)
        let film = taste.favouriteFilm.trimmingCharacters(in: .whitespacesAndNewlines)
        let why = taste.why.trimmingCharacters(in: .whitespacesAndNewlines)

        // Any one of these can stand alone — "anything by Céline Sciamma" is a
        // complete request — so only what they actually gave is described.
        var told: [String] = []
        if !film.isEmpty {
            told.append("- A film they love: \(film)")
        }
        if !director.isEmpty {
            told.append("- A director or actor they love: \(director)")
        }
        if !why.isEmpty {
            told.append("- What they're after, in their words: \"\(why)\"")
        }

        let prompt = """
        They've told you, in their own words:
        \(told.joined(separator: "\n"))

        What else you know about their taste:
        \(profile(context))

        Do NOT recommend: \(list(avoid))

        Recommend exactly ONE film that answers what they asked for. It must
        genuinely deliver the thing they described — not merely share a genre,
        a cast member or a director with it. If they named a director or actor,
        the pick need not be that person's work, but it must scratch the same
        itch; if it is their work, say why that one.

        The reason is the whole point. Address them as "you", name the specific
        quality that connects it to what they told you, and where they gave you
        their own words, use them back. Two sentences at most. Write "you loved
        Heat for the professionalism, so watch this" — never a plot summary.
        """

        let tool = ClaudeTool(
            name: "present_daily_pick",
            description: "Present one film chosen from what the user says they love.",
            inputSchema: claudeJSONSchema("""
            {
              "type": "object",
              "properties": {
                "title": { "type": "string", "description": "The film's exact release title and nothing else — no director name, no quotation marks, no year, no commentary." },
                "year": { "type": "integer" },
                "reason": { "type": "string", "description": "One or two sentences connecting it to what they said they love, addressed to them." }
              },
              "required": ["title", "year", "reason"]
            }
            """)
        )

        let pick = try await claude.generate(
            system: persona,
            userPrompt: prompt,
            tool: tool,
            as: DailyPickToolInput.self
        )

        let movie = await tmdb.searchMovie(title: pick.title, year: pick.year)
        return RecommendedFilm(
            title: pick.title,
            year: pick.year,
            reason: pick.reason,
            posterPath: movie?.posterPath,
            tmdbID: movie?.id,
            genres: movie?.genreNames ?? []
        )
    }

    // MARK: - Daily pick

    /// Picks ONE film for tonight from the user's taste, with a witty personal
    /// one-line reason in Bella's voice. `exclude` lists titles to avoid (already
    /// shown today / saved).
    func dailyPick(context: TasteContext, exclude: [String]) async throws -> RecommendedFilm? {
        let avoid = await Self.blocked(context, plus: exclude)

        let prompt = """
        Based on this person's taste, pick exactly ONE film for them to watch
        tonight.
        \(profile(context))
        Do NOT pick any of these (already shown, saved, hidden, or disliked): \(list(avoid))
        Give a short, witty, personal one-line reason in your voice, as if you
        know them — e.g. "You told me you love a slow-burn ache, trust me tonight."
        If their ratings or notes justify the pick, say so in that one line.
        """

        let tool = ClaudeTool(
            name: "present_daily_pick",
            description: "Present one personalized film pick for tonight.",
            inputSchema: claudeJSONSchema("""
            {
              "type": "object",
              "properties": {
                "title": { "type": "string", "description": "The film's exact release title and nothing else — no director name, no quotation marks, no year, no commentary." },
                "year": { "type": "integer" },
                "reason": { "type": "string", "description": "One witty, personal sentence in Bella's voice." }
              },
              "required": ["title", "year", "reason"]
            }
            """)
        )

        let pick = try await claude.generate(
            system: persona,
            userPrompt: prompt,
            tool: tool,
            as: DailyPickToolInput.self
        )

        let movie = await tmdb.searchMovie(title: pick.title, year: pick.year)
        return RecommendedFilm(
            title: pick.title,
            year: pick.year,
            reason: pick.reason,
            posterPath: movie?.posterPath,
            tmdbID: movie?.id,
            genres: movie?.genreNames ?? []
        )
    }

    // MARK: - Taste summary

    func tasteSummary(context: TasteContext) async throws -> String {
        let prompt = """
        \(profile(context))

        Write a short, witty one or two sentence summary of their movie taste, in \
        DearBella's voice — e.g. "Based on your list, you're into quirky indie \
        comedies and emotional sci-fi." Address them as "you". If they've rated or \
        written about films, draw on that rather than the genre list alone — it's \
        the part that actually sounds like them.
        """

        let tool = ClaudeTool(
            name: "present_taste_summary",
            description: "Present a short, witty summary of the user's movie taste.",
            inputSchema: claudeJSONSchema("""
            {
              "type": "object",
              "properties": {
                "summary": { "type": "string", "description": "One or two witty sentences about their taste." }
              },
              "required": ["summary"]
            }
            """)
        )

        return try await claude.generate(
            system: persona,
            userPrompt: prompt,
            tool: tool,
            as: TasteSummaryToolInput.self
        ).summary
    }

    private func list(_ items: [String]) -> String {
        items.isEmpty ? "none" : items.joined(separator: ", ")
    }

    /// Renders everything we know about the user's taste. Sections with no data
    /// are left out entirely, so a brand-new user's prompt stays short and gets
    /// richer as they rate things — nothing is ever described as "none" when
    /// the truth is "not yet".
    private func profile(_ context: TasteContext) -> String {
        var lines = [
            "- Favorite genres: \(list(context.genres))",
            "- Films on their list: \(list(context.topFilms))"
        ]
        if !context.directors.isEmpty {
            lines.append("- Directors they named as their own: \(list(context.directors))")
        }
        if !context.loved.isEmpty {
            lines.append("- LOVED, weight these heaviest: \(list(context.loved))")
        }
        if !context.liked.isEmpty {
            lines.append("- Liked: \(list(context.liked))")
        }
        if !context.disliked.isEmpty {
            lines.append("- DID NOT ENJOY, steer well clear: \(list(context.disliked))")
        }
        if !context.ratings.isEmpty {
            lines.append("- Their ratings: \(list(context.ratings))")
        }
        if !context.notes.isEmpty {
            lines.append("- Their own notes on films they've seen:")
            lines.append(contentsOf: context.notes.map { "  · \($0)" })
        }
        return lines.joined(separator: "\n")
    }

    /// Everything Claude must not suggest: the caller's list plus every film
    /// the user told us they didn't enjoy, plus everything they've hidden.
    @MainActor
    private static func blocked(_ context: TasteContext, plus exclude: [String]) -> [String] {
        var seen = Set<String>()
        return (exclude + context.disliked + HiddenFilmsStore.shared.excludeTitles)
            .filter { seen.insert($0.lowercased()).inserted }
    }
}
