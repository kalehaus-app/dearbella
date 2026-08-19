import SwiftUI
import UIKit

/// Search TMDB and put a film straight on the list.
///
/// Every other route into My List goes through a recommendation — swipe,
/// bracket, "find me something". That's fine until you already know what you
/// want: you saw a trailer, a friend named a film, you finally watched
/// something and want it logged. Without this, the only way to record a film
/// you already have in mind is to hope the app suggests it.
///
/// The shelf picker is the point of the "already watched" half. Logging what
/// you've seen is what teaches Bella your taste, and someone in a logging mood
/// will add five in a row — so the choice sits at the top and stays put
/// between adds rather than resetting to Watchlist each time.
struct AddFilmSheet: View {
    /// Which shelf new films land on. Seeded from the tab they opened this
    /// from, since that's almost always the one they meant.
    @State var shelf: FilmStatus

    @EnvironmentObject private var watchlist: WatchlistStore
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [TMDBMovie] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var justAdded: Set<Int> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 14) {
                    shelfPicker
                    SearchField(placeholder: "Search a film", text: $query)
                        .padding(.horizontal, 20)
                    content
                }
                .padding(.top, 12)
            }
            .navigationTitle("Add a film")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.highlight)
                }
            }
        }
        .onChange(of: query) { _, new in
            search(new)
        }
        .onDisappear { searchTask?.cancel() }
    }

    private var shelfPicker: some View {
        HStack(spacing: 8) {
            ForEach([FilmStatus.watchlist, .watched], id: \.self) { option in
                Button {
                    shelf = option
                } label: {
                    Text(option == .watchlist ? "Want to watch" : "Already watched")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(kind: shelf == option ? .primary : .secondary))
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var content: some View {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            hint
        } else if results.isEmpty && isSearching {
            Spacer()
            ProgressView().tint(Theme.highlight)
            Spacer()
        } else if results.isEmpty {
            emptyResults
        } else {
            resultList
        }
    }

    private var hint: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Type a title")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Anything you've seen, or anything you've been meaning to.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("Nothing found")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Try a shorter title, or check the spelling.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results) { movie in
                    row(for: movie)
                    Divider()
                        .background(Theme.cream.opacity(0.08))
                        .padding(.leading, 84)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func row(for movie: TMDBMovie) -> some View {
        let saved = watchlist.isSaved(String(movie.id)) || justAdded.contains(movie.id)

        return Button {
            add(movie)
        } label: {
            HStack(spacing: 12) {
                PosterImage(posterPath: movie.posterPath, seed: String(movie.id), size: "w185")
                    .frame(width: 48, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    Text(movie.title ?? "Untitled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let year = movie.releaseDate?.prefix(4), !year.isEmpty {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: saved ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(saved ? Theme.highlight : Theme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(saved)
    }

    // MARK: - Actions

    /// Debounced so typing a title doesn't fire a request per keystroke.
    private func search(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            let found = await TMDBClient.shared.searchMovies(query: trimmed, limit: 20)
            guard !Task.isCancelled else { return }

            results = found
            isSearching = false
        }
    }

    private func add(_ movie: TMDBMovie) {
        guard let film = SwipeMovie(from: movie)?.savedFilm else { return }

        var placed = film
        placed.status = shelf
        if shelf == .watched { placed.watchedAt = Date() }

        watchlist.save(placed)
        justAdded.insert(movie.id)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    AddFilmSheet(shelf: .watchlist)
        .environmentObject(WatchlistStore())
}
