import SwiftUI

// Small non-interactive "mock" graphics that illustrate each intro slide.
// They're decorative previews of features we build for real in later steps.

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

/// "Always know what to watch" — a mock chat exchange.
struct ChatMock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ChatBubble(text: "What should I watch tonight?", color: .blue, isMine: true)
            ChatBubble(text: "Here's 3 suggestions…", color: Theme.surface, isMine: false)
            HStack(spacing: 8) {
                ForEach(["Lady Bird", "It", "Kill Bill"], id: \.self) { title in
                    Color.clear
                        .aspectRatio(0.7, contentMode: .fit)
                        .overlay {
                            ZStack(alignment: .topLeading) {
                                PlaceholderArt.gradient(for: title)
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

/// A small captioned tile used by the curated and vibe mocks.
struct MiniTile: View {
    let caption: String
    let seed: String

    var body: some View {
        Color.clear
            .aspectRatio(1.6, contentMode: .fit)
            .overlay {
                ZStack(alignment: .topLeading) {
                    PlaceholderArt.gradient(for: seed)
                    LinearGradient(
                        colors: [.black.opacity(0.1), .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Text(caption)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
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
                MiniTile(caption: "Tonight's Mood: Dreamy & Disoriented", seed: "mood")
                MiniTile(caption: "Films you'll love if you liked Carrie", seed: "carrie")
                MiniTile(caption: "Top 3 Hidden Gems this week", seed: "gems")
                MiniTile(caption: "Underrated Holiday films for you", seed: "holiday")
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
                MiniTile(caption: "Start your film bucket list", seed: "bucket")
                MiniTile(caption: "Your Dream Cast", seed: "cast")
                MiniTile(caption: "Your favorite film scenes", seed: "scenes")
                MiniTile(caption: "Your Overrated List", seed: "overrated")
            }
        }
        .padding(14)
        .background(Theme.surface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
