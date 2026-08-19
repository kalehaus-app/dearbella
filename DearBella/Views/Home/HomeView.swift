import SwiftUI

/// The home feed, and the app's front door.
///
/// It leads with "tell me what you love and I'll find your next one", because
/// that is what the app is for — a screen of poster rows looks like a catalogue
/// and doesn't do anything. Browsing sits underneath it.
struct HomeView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var watchlist: WatchlistStore
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var tasteStore: TasteProfileStore
    @State private var showComingSoon = false
    @State private var showFindSomething = false
    @State private var showAbout = false
    @State private var recentMovies: [SwipeMovie] = []
    @State private var didLoadRecent = false

    private let dailyPickAnchor = "dailyPick"

    /// Everything the user has told us — what they rated and reacted to in My
    /// List, seeded with their onboarding picks — used to personalize Claude
    /// calls.
    private var tasteContext: TasteContext {
        TasteContext(
            films: watchlist.films,
            onboardingGenres: SampleData.genres
                .filter { store.selectedGenreIDs.contains($0.id) }
                .map(\.name),
            onboardingFilms: store.selectedFilms.map(\.title)
        )
    }

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 28) {
                    header
                    findSomethingPanel
                    newOnDemandSection
                    MyListPreview()
                    BellaPickCard().id(dailyPickAnchor)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                // Arriving from a reminder means they were promised a pick,
                // so go to it rather than leaving them to scroll for it.
                .onChange(of: notifications.didOpenFromReminder) { _, fromReminder in
                    guard fromReminder else { return }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(dailyPickAnchor, anchor: .center)
                    }
                    notifications.didOpenFromReminder = false
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .task { await loadRecentReleases() }
        .fullScreenCover(isPresented: $showFindSomething) {
            FindSomethingView(context: tasteContext)
                .environmentObject(watchlist)
                .environmentObject(tasteStore)
                .environmentObject(store)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
                .environmentObject(HiddenFilmsStore.shared)
                .environmentObject(notifications)
                .environmentObject(watchlist)
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
            Button {
                showAbout = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    // MARK: - New & On Demand

    @ViewBuilder
    private var newOnDemandSection: some View {
        if !recentMovies.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "New & On Demand")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentMovies) { movie in
                            Link(destination: WatchlistStore.watchURL(for: movie.savedFilm)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    PosterImage(posterPath: movie.posterPath, seed: movie.title)
                                        .frame(width: 110, height: 165)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(movie.title)
                                        .font(.dearBellaCaption)
                                        .foregroundStyle(Theme.cream)
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

    private func loadRecentReleases() async {
        guard !didLoadRecent else { return }
        didLoadRecent = true
        let movies = await TMDBClient.shared.recentReleases()
        recentMovies = movies.compactMap(SwipeMovie.init(from:))
    }

    // MARK: - My List

    // The dashboard's My List preview is now its own view: `MyListPreview`.

    // MARK: - What should I watch tonight?

    /// The app's primary action. Reads differently once there's a saved
    /// profile, because coming back to a form you've already filled in should
    /// feel like picking up, not starting over.
    private var findSomethingPanel: some View {
        Button { showFindSomething = true } label: {
            VStack(alignment: .leading, spacing: 14) {
                Text(tasteStore.profile.isUsable
                     ? "Ready when you are."
                     : "Tell me what you love and I'll find your next one.")
                    .font(.dmSerif(28, relativeTo: .title))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(tasteStore.profile.isUsable ? "Find me something" : "Start")
                        .font(.dearBellaButton)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(Theme.ink)
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Theme.cyan)
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
        .environmentObject(NotificationService.shared)
        .environmentObject(TasteProfileStore())
}
