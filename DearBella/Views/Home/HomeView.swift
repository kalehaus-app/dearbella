import SwiftUI

/// A home-feed image tile: a local catalog image + caption. Backs the two
/// 2×2 grids ("Curated for you" and "Things to do").
private struct HomeImageTile: Identifiable {
    let id = UUID()
    let image: String
    let caption: String
    /// Where this tile's collection screen sources its films (curated tiles only).
    var source: CollectionViewModel.Source? = nil

    static let curated: [HomeImageTile] = [
        HomeImageTile(image: "dreamy", caption: "Tonight's Mood: Dreamy & Disoriented",
                      source: .claudeTheme(prompt: "dreamy, surreal, disorienting films", count: 6)),
        HomeImageTile(image: "cinema", caption: "Films you'll love if you like Cinematography",
                      source: .claudeTheme(prompt: "films celebrated for stunning, beautiful cinematography", count: 6)),
        HomeImageTile(image: "gems", caption: "Top 3 Hidden Gems this week",
                      source: .claudeTheme(prompt: "underrated hidden-gem films", count: 3)),
        HomeImageTile(image: "lovers", caption: "Underrated Lovers Films for you",
                      source: .claudeTheme(prompt: "underrated romance / love-story films", count: 6)),
    ]

    static let thingsToDo: [HomeImageTile] = [
        HomeImageTile(image: "bucket", caption: "Start your film bucket list"),
        HomeImageTile(image: "cast", caption: "Your Dream Cast"),
        HomeImageTile(image: "scenes", caption: "Your favorite film scenes"),
        HomeImageTile(image: "overrated", caption: "Your Overrated List"),
    ]
}

/// Home-only "Browse by Vibe" pills (palette colors). Kept separate from the
/// shared `VibePill` so the onboarding carousel is unaffected.
private struct HomeVibe: Identifiable {
    let id = UUID()
    let name: String
    let background: Color
    let textColor: Color

    static let all: [HomeVibe] = [
        HomeVibe(
            name: "Sad",
            background: Color(red: 255 / 255, green: 192 / 255, blue: 223 / 255), // #FFC0DF
            textColor: Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)       // #1A1A1A
        ),
        HomeVibe(
            name: "Board",
            background: Color(red: 170 / 255, green: 242 / 255, blue: 204 / 255),  // #AAF2CC
            textColor: Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)       // #1A1A1A
        ),
        HomeVibe(
            name: "Silly",
            background: Color(red: 1 / 255, green: 100 / 255, blue: 54 / 255),     // #016436
            textColor: Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)    // #F4EFE6
        ),
    ]
}

/// The home feed (wireframe Frame 47): curated cards, the blue "What should I
/// watch tonight?" panel, browse-by-vibe pills, a "Things to do" grid, and the
/// green film-fact card.
///
/// The chat, vibes, and "things to do" are placeholders for now — tapping them
/// shows a "coming soon" note. We wire the chat up for real in Step 5.
struct HomeView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var catalog: MovieCatalog
    @EnvironmentObject private var watchlist: WatchlistStore
    @State private var showComingSoon = false
    @State private var showChat = false
    @State private var selectedCollection: HomeImageTile?

    private let twoColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    /// The user's saved genres + top films, used to personalize Claude calls.
    private var tasteContext: TasteContext {
        let genreNames = SampleData.genres
            .filter { store.selectedGenreIDs.contains($0.id) }
            .map(\.name)
        let filmTitles = store.selectedFilms.map(\.title)
        return TasteContext(genres: genreNames, topFilms: filmTitles)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                watchTonightPanel
                curatedSection
                vibeSection
                myListSection
                thingsToDoSection
                filmFactCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Theme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showChat) {
            ChatView(context: tasteContext)
                .environmentObject(watchlist)
        }
        .fullScreenCover(item: $selectedCollection) { tile in
            if let source = tile.source {
                CollectionView(title: tile.caption, source: source)
                    .environmentObject(watchlist)
            }
        }
        .alert("Coming soon", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We'll wire this feature up in a later step.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Dear Bella")
                .font(.dmSerif(32, relativeTo: .title))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Menu {
                Button("Reset onboarding", role: .destructive) {
                    withAnimation { store.resetOnboarding() }
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Curated

    private var curatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Curated for you")
            LazyVGrid(columns: twoColumns, spacing: 12) {
                ForEach(HomeImageTile.curated) { tile in
                    Button { selectedCollection = tile } label: {
                        ImageTile(imageName: tile.image, caption: tile.caption, captionAtTop: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - My List

    @ViewBuilder
    private var myListSection: some View {
        if !watchlist.films.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "My List")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(watchlist.films) { film in
                            Link(destination: WatchlistStore.watchURL(for: film)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    PosterImage(posterPath: film.posterPath, seed: film.title)
                                        .frame(width: 110, height: 165)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(film.title)
                                        .font(.dearBellaCaption)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .frame(width: 110, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - What should I watch tonight?

    private var watchTonightPanel: some View {
        Button { showChat = true } label: {
            ZStack(alignment: .bottomTrailing) {
                Text("What should I\nwatch tonight?")
                    .font(.inter(30, weight: .bold, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Text("Start Chat")
                    .font(.dearBellaButton)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            .padding(20)
            .frame(height: 150)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Browse by Vibe

    private var vibeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Browse by Vibe:")
            HStack(spacing: 10) {
                ForEach(HomeVibe.all) { vibe in
                    Button { showComingSoon = true } label: {
                        HomeVibePill(text: vibe.name, background: vibe.background, textColor: vibe.textColor)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }

    // MARK: - Things to do

    private var thingsToDoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Things to do:")
            LazyVGrid(columns: twoColumns, spacing: 12) {
                ForEach(HomeImageTile.thingsToDo) { tile in
                    Button { showComingSoon = true } label: {
                        ImageTile(imageName: tile.image, caption: tile.caption, captionAtTop: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Film fact

    private var filmFactCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Film Fact")
                    .font(.inter(12, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color(red: 168 / 255, green: 160 / 255, blue: 149 / 255))
                Spacer()
                Button { showComingSoon = true } label: {
                    Text("Share")
                        .font(.inter(12, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color(red: 168 / 255, green: 160 / 255, blue: 149 / 255))
                }
                .buttonStyle(.plain)
            }

            Text(HomeContent.fact.headline)
                .font(.dmSerif(26))
                .foregroundStyle(Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255))

            Text(HomeContent.fact.highlight)
                .font(.dmSerif(26))
                .foregroundStyle(Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 42 / 255, green: 42 / 255, blue: 42 / 255), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
        .environmentObject(WatchlistStore())
}
