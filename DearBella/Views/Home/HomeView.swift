import SwiftUI

/// The home feed, and the app's front door.
///
/// It opens on the ask itself rather than a panel advertising it. A hero card
/// is a poster for the feature; the field is the feature, and putting it here
/// costs a tap less and no explaining. Browsing sits underneath.
struct HomeView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var watchlist: WatchlistStore
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var tasteStore: TasteProfileStore
    @EnvironmentObject private var router: AppRouter
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
            onboardingFilms: store.selectedFilms.map(\.title),
            onboardingDirectors: store.selectedDirectors.map(\.name)
        )
    }

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 28) {
                    header
                    findSomethingPanel
                    startYourListPanel
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
                .environmentObject(store)
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

    /// Shown only while the list is empty.
    ///
    /// Everything downstream — picking a film for tonight, what Bella learns,
    /// the rows further down this screen — needs a list to work from, so a new
    /// user's most useful next tap is the one that starts one. Once there's
    /// something saved this disappears rather than nagging.
    @ViewBuilder
    private var startYourListPanel: some View {
        if watchlist.films.isEmpty {
            Button {
                router.tab = .discover
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.highlight)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start your list")
                            .font(.inter(15, weight: .semibold))
                            .foregroundStyle(Theme.cream)
                        Text("Swipe through films and save the ones you'd watch.")
                            .font(.dearBellaCaption)
                            .foregroundStyle(Theme.cream.opacity(0.55))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.cream.opacity(0.35))
                }
                .padding(14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.cream.opacity(0.14), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
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
        VStack(alignment: .leading, spacing: 12) {
            askField

            if !quickPicks.isEmpty {
                quickPickRow
            }
        }
    }

    /// Looks like a field and behaves like one — tapping opens the real thing
    /// with the keyboard already up. A live text field here would mean two
    /// places holding the same answer.
    private var askField: some View {
        Button { showFindSomething = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.highlight)

                Text(tasteStore.profile.isUsable
                     ? tasteStore.profile.summary
                     : "Name a film, director, or a feeling…")
                    .font(.inter(15))
                    .foregroundStyle(tasteStore.profile.isUsable
                                     ? Theme.cream
                                     : Theme.cream.opacity(0.42))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.cream.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// Their own films, one tap from an answer. A chip fills the film in and
    /// opens straight to it, so the common case never involves typing.
    private var quickPickRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPicks, id: \.self) { title in
                    Button {
                        tasteStore.profile.favouriteFilm = title
                        showFindSomething = true
                    } label: {
                        Text(title)
                            .font(.inter(12, weight: .semibold))
                            .foregroundStyle(Theme.cream.opacity(0.85))
                            .lineLimit(1)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Theme.cream.opacity(0.16), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quickPicks: [String] {
        Array(
            TasteSuggestions.films(
                onboarding: store.selectedFilms.map(\.title),
                saved: watchlist.films.map(\.title)
            ).prefix(6)
        )
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
        .environmentObject(AppRouter())
}
