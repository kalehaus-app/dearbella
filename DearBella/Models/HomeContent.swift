import SwiftUI

/// A card in the "Curated for you" grid. `filmID` points at a curated film
/// whose TMDB poster backs the card.
struct CuratedItem: Identifiable {
    let id = UUID()
    let caption: String
    let seed: String
    let filmID: String
}

/// A card in the "Things to do" grid. `filmID` backs it with a real poster.
struct ThingToDo: Identifiable {
    let id = UUID()
    let caption: String
    let seed: String
    let filmID: String
}

/// A "Browse by Vibe" pill.
struct Vibe: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

/// The green "Film Fact" card's content.
struct FilmFact {
    let headline: String
    let highlight: String
}

/// Hardcoded home-feed content for Step 3. Curated picks will become real,
/// AI-driven recommendations in Step 5; the imagery becomes TMDB art in Step 4.
enum HomeContent {
    static let curated: [CuratedItem] = [
        CuratedItem(caption: "Tonight's Mood: Dreamy & Disoriented", seed: "mood", filmID: "eternal-sunshine"),
        CuratedItem(caption: "Films you'll love if you liked Carrie", seed: "carrie", filmID: "get-out"),
        CuratedItem(caption: "Top 3 Hidden Gems this week", seed: "gems", filmID: "whiplash"),
        CuratedItem(caption: "Underrated Holiday films for you", seed: "holiday", filmID: "amelie"),
    ]

    static let vibes: [Vibe] = [
        Vibe(name: "Chill", color: .blue),
        Vibe(name: "Board", color: .green),
        Vibe(name: "Silly", color: .pink),
    ]

    static let thingsToDo: [ThingToDo] = [
        ThingToDo(caption: "Start your film bucket list", seed: "bucket", filmID: "godfather"),
        ThingToDo(caption: "Your Dream Cast", seed: "cast", filmID: "inglourious-basterds"),
        ThingToDo(caption: "Your favorite film scenes", seed: "scenes", filmID: "pulp-fiction"),
        ThingToDo(caption: "Your Overrated List", seed: "overrated", filmID: "truman-show"),
    ]

    static let fact = FilmFact(
        headline: "THE FIRST MOVIE\nTHEATERS OPENED IN",
        highlight: "1907"
    )
}
