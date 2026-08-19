import SwiftUI

/// "Tell me what you love and I'll find your next one."
///
/// One box, not a form. Three labelled fields with `optional` tags read as a
/// signup flow, and asking someone to fill in a form before they can ask a
/// question is the opposite of the point.
///
/// So the box takes anything — a film, a director, or a sentence about the
/// evening you want — and works out which it was: matches become chips you can
/// see and remove, and anything you don't pick from is kept as your own words.
/// Refining is adding another chip rather than opening another field.
struct FindSomethingView: View {
    let context: TasteContext

    @EnvironmentObject private var watchlist: WatchlistStore
    @EnvironmentObject private var tasteStore: TasteProfileStore
    @EnvironmentObject private var onboarding: OnboardingStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = FindSomethingViewModel()
    @StateObject private var search = TasteSearchViewModel()

    @State private var query = ""
    @FocusState private var isTyping: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            if let pick = viewModel.pick {
                result(pick)
            } else {
                ask
            }

            closeButton
        }
        .onAppear { if tasteStore.profile.isEmpty { isTyping = true } }
    }

    // MARK: - Ask

    private var ask: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("What are you in the mood for?")
                    .font(.dmSerif(30))
                    .foregroundStyle(Theme.cream)
                    .padding(.top, 56)
                    .fixedSize(horizontal: false, vertical: true)

                searchField

                if !search.films.isEmpty || !search.people.isEmpty {
                    results
                } else {
                    chosen
                    reasonChips
                }

                if let error = viewModel.error {
                    Text(error)
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.accent)
                }

                findButton
                    .padding(.top, 4)

                // Below the button on purpose: browsing is the alternative to
                // asking, not a step before it.
                if search.films.isEmpty && search.people.isEmpty && !search.browse.isEmpty {
                    wall
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .task { await search.loadBrowse(saved: watchlist.films) }
    }

    /// Art on the screen from the moment it opens, and a way in that needs no
    /// typing at all.
    private var wall: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OR START FROM A FILM")
                .font(.inter(11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)
                .padding(.top, 12)

            PosterWall(films: search.browse) { film in
                tasteStore.profile.favouriteFilm = film.title
                clearSearch()
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.cream.opacity(0.5))

            ZStack(alignment: .leading) {
                if query.isEmpty {
                    Text("A film, a director, or a feeling…")
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream.opacity(0.35))
                        .allowsHitTesting(false)
                }
                TextField("", text: $query)
                    .focused($isTyping)
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                    .submitLabel(.search)
            }

            if !query.isEmpty {
                Button {
                    query = ""
                    search.clearFilms()
                    search.clearPeople()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.cream.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.cream.opacity(0.16), lineWidth: 1)
        )
        .onChange(of: query) { _, text in
            search.searchFilms(text)
            search.searchPeople(text)
        }
    }

    /// Films and people for whatever is being typed. Picking one turns it into
    /// a chip and empties the box, ready for the next thing.
    private var results: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilmResultRow(films: search.films) { film in
                tasteStore.profile.favouriteFilm = film.title ?? ""
                clearSearch()
            }
            PersonResultRow(people: search.people) { person in
                tasteStore.profile.director = person.name
                clearSearch()
            }
        }
    }

    /// What Bella has been told so far, each removable. Showing it as chips
    /// rather than filled-in fields keeps the screen a question with answers
    /// attached, instead of a form in a half-completed state.
    @ViewBuilder
    private var chosen: some View {
        let items = [
            (tasteStore.profile.favouriteFilm, "film"),
            (tasteStore.profile.director, "person"),
            (tasteStore.profile.why, "why"),
        ].filter { !$0.0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if !items.isEmpty {
            FlowChips(items: items.map(\.0)) { value in
                remove(value)
            }
        }
    }

    private var reasonChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OR WHAT YOU'RE AFTER")
                .font(.inter(11, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)

            SuggestionChips(options: TasteSuggestions.reasons) { reason in
                appendReason(reason)
            }
        }
    }

    private var findButton: some View {
        Button {
            isTyping = false
            commitQueryIfUnmatched()
            Task { await viewModel.find(taste: tasteStore.profile, context: context) }
        } label: {
            Group {
                if viewModel.isThinking {
                    HStack(spacing: 10) {
                        ProgressView().tint(Theme.ink)
                        Text("Bella's thinking…")
                    }
                } else {
                    Text("Find me something")
                }
            }
        }
        .buttonStyle(.pill(.primary))
        .opacity(canSearch ? 1 : 0.4)
        .disabled(!canSearch || viewModel.isThinking)
    }

    private var canSearch: Bool {
        tasteStore.profile.isUsable
            || !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Editing what was said

    private func clearSearch() {
        query = ""
        search.clearFilms()
        search.clearPeople()
        isTyping = false
    }

    /// Anything typed and not picked from the results is taken at face value —
    /// "something slow and sad" is a real request, not a failed search.
    private func commitQueryIfUnmatched() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appendReason(trimmed)
        clearSearch()
    }

    private func appendReason(_ text: String) {
        let current = tasteStore.profile.why.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !current.isEmpty else {
            tasteStore.profile.why = text
            return
        }
        guard !current.localizedCaseInsensitiveContains(text) else { return }
        tasteStore.profile.why = "\(current), \(text.lowercasedFirst)"
    }

    private func remove(_ value: String) {
        if tasteStore.profile.favouriteFilm == value { tasteStore.profile.favouriteFilm = "" }
        if tasteStore.profile.director == value { tasteStore.profile.director = "" }
        if tasteStore.profile.why == value { tasteStore.profile.why = "" }
    }

    // MARK: - Result

    private func result(_ film: RecommendedFilm) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Watch this next")
                    .font(.inter(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.highlight)
                    .clipShape(Capsule())
                    .padding(.top, 56)

                PosterImage(posterPath: film.posterPath, seed: film.title)
                    .frame(width: 150, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(film.displayTitle)
                    .font(.dmSerif(26))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(film.reason)
                    .font(.inter(15))
                    .foregroundStyle(Theme.cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 20)

                actions(film)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
    }

    private func actions(_ film: RecommendedFilm) -> some View {
        let saved = watchlist.isSaved(film.savedFilm.id)

        return VStack(spacing: 8) {
            Button {
                watchlist.save(film.savedFilm)
            } label: {
                Label(
                    saved ? "In your list" : "Add to my list",
                    systemImage: saved ? "checkmark" : "plus"
                )
            }
            .buttonStyle(.pill(.primary))
            .opacity(saved ? 0.6 : 1)
            .disabled(saved)

            Link(destination: WatchlistStore.watchURL(for: film.savedFilm)) {
                Label("Where to watch", systemImage: "play.rectangle")
            }
            .buttonStyle(.pill(.secondary))

            Button {
                Task {
                    viewModel.reset()
                    await viewModel.find(taste: tasteStore.profile, context: context)
                }
            } label: {
                Text("Not this one — try again")
            }
            .buttonStyle(.pill(.tertiary))
        }
        .padding(.horizontal, 12)
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.cream.opacity(0.75))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
        .padding(.top, 8)
        .accessibilityLabel("Close")
    }
}
