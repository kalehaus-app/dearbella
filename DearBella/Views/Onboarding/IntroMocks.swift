import SwiftUI

// Small non-interactive "mock" graphics that illustrate each intro slide.
// They're decorative previews of features we build for real in later steps,
// now backed by real TMDB posters (via MovieCatalog) just like the rest of
// the app, with the placeholder gradient as the loading/fallback state.

/// A chat bubble used in the intro's chat mock.
struct ChatBubble: View {
    let text: String
    let color: Color
    /// `true` = the user's own message (blue, left-aligned per wireframe).
    let isMine: Bool

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: .infinity, alignment: isMine ? .leading : .trailing)
    }
}

/// "Always know what to watch" — a mock chat exchange with real poster thumbs.
struct ChatMock: View {
    @EnvironmentObject private var catalog: MovieCatalog

    /// (display title, curated film id) pairs for the suggestion thumbnails.
    private let suggestions = [
        ("Lady Bird", "lady-bird"),
        ("It", "it"),
        ("Kill Bill", "kill-bill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ChatBubble(text: "What should I watch tonight?", color: .blue, isMine: true)
            ChatBubble(text: "Here's 3 suggestions…", color: Theme.surface, isMine: false)
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.1) { title, filmID in
                    Color.clear
                        .aspectRatio(0.7, contentMode: .fit)
                        .overlay {
                            ZStack(alignment: .bottomLeading) {
                                PosterImage(posterPath: catalog.posterPath(filmID: filmID), seed: filmID)
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.5)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                                Text(title)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(5)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(maxWidth: 220, alignment: .leading)
            ChatBubble(text: "No try again", color: .blue, isMine: true)
        }
    }
}

/// A small captioned tile backed by a real poster, used by the curated and
/// vibe mocks.
struct MiniTile: View {
    let caption: String
    let seed: String
    let filmID: String

    @EnvironmentObject private var catalog: MovieCatalog

    var body: some View {
        Color.clear
            .aspectRatio(1.6, contentMode: .fit)
            .overlay {
                ZStack(alignment: .topLeading) {
                    PosterImage(posterPath: catalog.posterPath(filmID: filmID), seed: seed)
                    LinearGradient(
                        colors: [.black.opacity(0.1), .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Text(caption)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// "Personalized like a friend who knows cinema." — a curated grid mock.
struct CuratedMock: View {
    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Curated for you")
                .font(.headline)
                .foregroundStyle(.white)
            LazyVGrid(columns: columns, spacing: 8) {
                MiniTile(caption: "Tonight's Mood: Dreamy & Disoriented", seed: "mood", filmID: "eternal-sunshine")
                MiniTile(caption: "Films you'll love if you liked Carrie", seed: "carrie", filmID: "get-out")
                MiniTile(caption: "Top 3 Hidden Gems this week", seed: "gems", filmID: "whiplash")
                MiniTile(caption: "Underrated Holiday films for you", seed: "holiday", filmID: "amelie")
            }
        }
        .padding(14)
        .background(Theme.surface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// A colored vibe pill (Chill / Board / Silly).
struct VibePill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(color)
            .clipShape(Capsule())
    }
}

/// "Your cinematic companion" — vibe pills plus a things-to-do grid.
struct VibeMock: View {
    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Browse by Vibe:")
                .font(.headline)
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                VibePill(text: "Chill", color: .blue)
                VibePill(text: "Board", color: .green)
                VibePill(text: "Silly", color: .pink)
            }
            LazyVGrid(columns: columns, spacing: 8) {
                MiniTile(caption: "Start your film bucket list", seed: "bucket", filmID: "godfather")
                MiniTile(caption: "Your Dream Cast", seed: "cast", filmID: "inglourious-basterds")
                MiniTile(caption: "Your favorite film scenes", seed: "scenes", filmID: "pulp-fiction")
                MiniTile(caption: "Your Overrated List", seed: "overrated", filmID: "truman-show")
            }
        }
        .padding(14)
        .background(Theme.surface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
