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
    @State private var showAbout = false

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
                MyListPreview()
                BellaPickCard()
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
        .sheet(isPresented: $showAbout) {
            AboutView()
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
                Button {
                    showAbout = true
                } label: {
                    Label("About", systemImage: "info.circle")
                }
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

    // The dashboard's My List preview is now its own view: `MyListPreview`.

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

    // MARK: - Bella's Pick Today
    // The old static "Film Fact" card was replaced by `BellaPickCard`.
}

#Preview {
    HomeView()
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
        .environmentObject(WatchlistStore())
}
