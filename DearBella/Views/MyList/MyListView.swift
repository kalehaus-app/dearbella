import SwiftUI

/// Identifies which film's detail sheet is open. Only the id is carried, so
/// the sheet always reads live state from the store rather than a stale copy.
struct FilmSheetTarget: Identifiable, Equatable {
    let id: String
}

/// The "My List" tab: a saved-films library split by status, plus the three
/// AI-assisted pieces — taste insight, genre filter, and "find more like my
/// list" recommendations. The AI pieces only call the API on an explicit tap.
struct MyListView: View {
    @EnvironmentObject private var watchlist: WatchlistStore
    @StateObject private var viewModel = MyListViewModel()

    @State private var status: FilmStatus = .watchlist
    @State private var selectedGenre: String?
    @State private var showShareCard = false
    @State private var sheetTarget: FilmSheetTarget?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    /// Saved films as taste input for the AI features.
    private var tasteContext: TasteContext {
        TasteContext(films: watchlist.films)
    }

    /// The films in the selected status.
    private var statusFilms: [SavedFilm] {
        watchlist.films(in: status)
    }

    /// Genres present in the current status slice, so the pills never offer a
    /// filter that would empty the grid.
    private var presentGenres: [String] {
        Array(Set(statusFilms.flatMap(\.genres))).sorted()
    }

    /// The grid contents after applying the selected genre filter.
    private var filteredFilms: [SavedFilm] {
        guard let selectedGenre else { return statusFilms }
        return statusFilms.filter { $0.genres.contains(selectedGenre) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if watchlist.films.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    firstRunEmptyState
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        statusPicker
                        shareButton
                        TasteInsightSection(viewModel: viewModel, context: tasteContext)
                        if !presentGenres.isEmpty {
                            GenreFilterPills(genres: presentGenres, selected: $selectedGenre)
                        }
                        if filteredFilms.isEmpty {
                            statusEmptyState
                        } else {
                            grid
                        }
                        Divider().background(Theme.cream.opacity(0.1)).padding(.horizontal, 20)
                        RecommendationsSection(viewModel: viewModel, context: tasteContext)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .task {
            // Quietly backfill genres for films saved before genre tracking,
            // so the filter pills populate. No-op once every film has genres.
            await watchlist.backfillGenresIfNeeded()
        }
        .onChange(of: status) { _, _ in
            // A genre pill from the previous tab may not exist in this one.
            if let selectedGenre, !presentGenres.contains(selectedGenre) {
                self.selectedGenre = nil
            }
        }
        .sheet(item: $sheetTarget) { target in
            FilmDetailSheet(filmID: target.id)
                .environmentObject(watchlist)
                .environmentObject(HiddenFilmsStore.shared)
        }
        .fullScreenCover(isPresented: $showShareCard) {
            ShareCardSheet(films: ShareCardData.topTitles(from: watchlist.films))
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("My List")
            .font(.dearBellaTitle)
            .foregroundStyle(Theme.cream)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
    }

    /// Status tabs with live counts, so the size of each shelf is visible
    /// without switching to it.
    private var statusPicker: some View {
        HStack(spacing: 8) {
            ForEach(FilmStatus.allCases) { option in
                let isSelected = status == option
                let count = watchlist.count(of: option)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { status = option }
                } label: {
                    HStack(spacing: 5) {
                        Text(option.shortTitle)
                            .font(.inter(13, weight: .semibold))
                        Text("\(count)")
                            .font(.inter(11, weight: .bold))
                            .foregroundStyle(isSelected ? Theme.ink.opacity(0.6) : Theme.textSecondary)
                    }
                    .foregroundStyle(isSelected ? Theme.ink : Theme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(isSelected ? Theme.cyan : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            isSelected ? Color.clear : Theme.cream.opacity(0.2),
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.title), \(count) films")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 20)
    }

    /// Entry point for the monthly recap share card.
    private var shareButton: some View {
        Button { showShareCard = true } label: {
            Label("Share my month", systemImage: "square.and.arrow.up")
                .font(.dearBellaButton)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.cyan)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    // MARK: - Grid

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredFilms) { film in
                Button {
                    sheetTarget = FilmSheetTarget(id: film.id)
                } label: {
                    card(film)
                }
                .buttonStyle(.plain)
                .contextMenu { menu(for: film) }
            }
        }
        .padding(.horizontal, 20)
    }

    private func card(_ film: SavedFilm) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(0.66, contentMode: .fit)
                .overlay { PosterImage(posterPath: film.posterPath, seed: film.title) }
                .overlay(alignment: .bottomLeading) {
                    RatingBadge(rating: film.rating, reaction: film.reaction)
                        .padding(8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(film.status == .archived ? 0.55 : 1)

            Text(film.title)
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !film.note.isEmpty {
                Label("Note", systemImage: "text.quote")
                    .font(.inter(11, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    /// Quick moves without opening the sheet — the fast path for tidying up.
    @ViewBuilder
    private func menu(for film: SavedFilm) -> some View {
        ForEach(FilmStatus.allCases.filter { $0 != film.status }) { target in
            Button {
                watchlist.setStatus(target, for: film.id)
            } label: {
                Label("Move to \(target.title)", systemImage: target.symbol)
            }
        }

        Link(destination: WatchlistStore.watchURL(for: film)) {
            Label("Where to watch", systemImage: "play.rectangle")
        }

        Button(role: .destructive) {
            watchlist.remove(film)
        } label: {
            Label("Remove from List", systemImage: "trash")
        }
    }

    // MARK: - Empty states

    /// Shown when nothing at all has been saved yet.
    private var firstRunEmptyState: some View {
        emptyState(
            symbol: "bookmark",
            title: "No films saved yet",
            message: "Tap \u{201C}Start Chat\u{201D} on Home, or swipe through some films — everything you save shows up here."
        )
    }

    /// Shown when the library has films but this particular shelf is empty.
    private var statusEmptyState: some View {
        let message: String = {
            if selectedGenre != nil {
                return "Nothing here in that genre. Try another filter."
            }
            switch status {
            case .watchlist: return "Nothing waiting to be watched. Swipe or ask Bella for a pick."
            case .watched:   return "Rate a film you've seen and it'll land here."
            case .archived:  return "Films you're not going to watch end up here, out of the way but still teaching Bella your taste."
            }
        }()

        return emptyState(symbol: status.symbol, title: status.title, message: message)
            .frame(minHeight: 220)
    }

    private func emptyState(symbol: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(Theme.cream.opacity(0.5))
            Text(title)
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream)
            Text(message)
                .font(.dearBellaCaption)
                .foregroundStyle(Theme.cream.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MyListView()
        .environmentObject(WatchlistStore())
}
