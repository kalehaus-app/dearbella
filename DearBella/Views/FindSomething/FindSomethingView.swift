import SwiftUI

/// "Tell me what you love and I'll find your next one."
///
/// The front door of the app. Three questions — a film, optionally a director
/// or actor, and crucially *why* — then one recommendation whose reason
/// answers what they said rather than summarising a plot.
///
/// Answers persist, so a returning user sees them filled in and is one tap
/// from a new pick.
struct FindSomethingView: View {
    let context: TasteContext

    @EnvironmentObject private var watchlist: WatchlistStore
    @EnvironmentObject private var tasteStore: TasteProfileStore
    @EnvironmentObject private var onboarding: OnboardingStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = FindSomethingViewModel()
    @StateObject private var search = TasteSearchViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case film, director, why }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.background.ignoresSafeArea()

            if let pick = viewModel.pick {
                result(pick)
            } else {
                questions
            }

            closeButton
        }
    }

    // MARK: - Questions

    private var questions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tell me what you love")
                        .font(.dmSerif(30))
                        .foregroundStyle(Theme.cream)
                    Text("Any one of these is enough. Fill in more and I'll get sharper.")
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream.opacity(0.6))
                }
                .padding(.top, 56)

                VStack(alignment: .leading, spacing: 8) {
                    field(
                        label: "A film you love",
                        placeholder: "Search any film…",
                        optional: true,
                        text: $tasteStore.profile.favouriteFilm,
                        focus: .film,
                        suggestions: search.films.isEmpty ? filmSuggestions : []
                    )
                    .onChange(of: tasteStore.profile.favouriteFilm) { _, query in
                        search.searchFilms(query)
                    }

                    FilmResultRow(films: search.films) { film in
                        tasteStore.profile.favouriteFilm = film.title ?? ""
                        search.clearFilms()
                        focusedField = nil
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    field(
                        label: "A director or actor you love",
                        placeholder: "Search any name…",
                        optional: true,
                        text: $tasteStore.profile.director,
                        focus: .director,
                        suggestions: search.people.isEmpty ? TasteSuggestions.names : []
                    )
                    .onChange(of: tasteStore.profile.director) { _, query in
                        search.searchPeople(query)
                    }

                    PersonResultRow(people: search.people) { person in
                        tasteStore.profile.director = person.name
                        search.clearPeople()
                        focusedField = nil
                    }
                }

                field(
                    label: "What are you after?",
                    placeholder: "The storyline, and all the old Hollywood",
                    optional: true,
                    multiline: true,
                    text: $tasteStore.profile.why,
                    focus: .why,
                    suggestions: TasteSuggestions.reasons,
                    // Several things can be true at once about why a film
                    // lands, so these add up rather than replace each other.
                    appendsSuggestions: true
                )

                if let error = viewModel.error {
                    Text(error)
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.accent)
                }

                findButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// Films we already know they like, so the row is their taste rather than
    /// a list of famous titles.
    private var filmSuggestions: [String] {
        TasteSuggestions.films(
            onboarding: onboarding.selectedFilms.map(\.title),
            saved: watchlist.films.map(\.title)
        )
    }

    private func field(
        label: String,
        placeholder: String,
        optional: Bool = false,
        multiline: Bool = false,
        text: Binding<String>,
        focus: Field,
        suggestions: [String] = [],
        appendsSuggestions: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(label.uppercased())
                    .font(.inter(11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(0.8)
                if optional {
                    Text("optional")
                        .font(.inter(10))
                        .foregroundStyle(Theme.cream.opacity(0.3))
                }
            }

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream.opacity(0.3))
                        .padding(.horizontal, 14)
                        .padding(.vertical, multiline ? 14 : 12)
                        .allowsHitTesting(false)
                }

                if multiline {
                    TextEditor(text: text)
                        .focused($focusedField, equals: focus)
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 84)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                } else {
                    TextField("", text: text)
                        .focused($focusedField, equals: focus)
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream)
                        .submitLabel(.next)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.cream.opacity(0.15), lineWidth: 1)
            )

            SuggestionChips(options: suggestions) { option in
                apply(option, to: text, appending: appendsSuggestions)
            }
        }
    }

    /// A chip either answers the question or adds to the answer. Replacing
    /// would throw away a considered sentence someone had already typed, so
    /// the "why" field extends instead — and a repeated tap is treated as a
    /// mis-tap rather than duplicated.
    private func apply(_ option: String, to text: Binding<String>, appending: Bool) {
        let current = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard appending, !current.isEmpty else {
            text.wrappedValue = option
            return
        }
        guard !current.localizedCaseInsensitiveContains(option) else { return }
        text.wrappedValue = "\(current), \(option.lowercasedFirst)"
    }

    private var findButton: some View {
        Button {
            focusedField = nil
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
        .opacity(tasteStore.profile.isUsable ? 1 : 0.4)
        .disabled(!tasteStore.profile.isUsable || viewModel.isThinking)
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
                    .background(Theme.cyan)
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

#Preview {
    FindSomethingView(context: TasteContext(films: []))
        .environmentObject(WatchlistStore())
        .environmentObject(TasteProfileStore())
        .environmentObject(OnboardingStore())
}
