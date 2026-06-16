import SwiftUI

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
    @StateObject private var feed = HomeFeedModel()
    @State private var showComingSoon = false
    @State private var showChat = false

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
                curatedSection
                myListSection
                watchTonightPanel
                vibeSection
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
        .task {
            await feed.loadCuratedIfNeeded(context: tasteContext)
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
                .font(.title2.bold())
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
                if feed.curatedCards.isEmpty {
                    // Built-in fallback until Claude's personalized cards load.
                    ForEach(HomeContent.curated) { item in
                        Button { showComingSoon = true } label: {
                            CaptionCard(
                                caption: item.caption,
                                seed: item.seed,
                                posterPath: catalog.posterPath(filmID: item.filmID)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    ForEach(feed.curatedCards) { card in
                        Button { showChat = true } label: {
                            CaptionCard(
                                caption: card.caption,
                                seed: card.caption,
                                posterPath: card.posterPath
                            )
                        }
                        .buttonStyle(.plain)
                    }
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
                                        .font(.caption)
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
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Text("Start Chat")
                    .font(.subheadline.weight(.bold))
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
                ForEach(HomeContent.vibes) { vibe in
                    Button { showComingSoon = true } label: {
                        VibePill(text: vibe.name, color: vibe.color)
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
                ForEach(HomeContent.thingsToDo) { item in
                    Button { showComingSoon = true } label: {
                        CaptionCard(
                            caption: item.caption,
                            seed: item.seed,
                            posterPath: catalog.posterPath(filmID: item.filmID)
                        )
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
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Button { showComingSoon = true } label: {
                    Text("Share")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
            }

            Text(HomeContent.fact.headline)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)

            Text(HomeContent.fact.highlight)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(red: 0.18, green: 0.78, blue: 0.35))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    HomeView()
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
        .environmentObject(WatchlistStore())
}
