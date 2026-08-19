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
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = FindSomethingViewModel()
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
                    Text("The more specific you are, the better I get.")
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream.opacity(0.6))
                }
                .padding(.top, 56)

                field(
                    label: "A film you love",
                    placeholder: "Once Upon a Time in Hollywood",
                    text: $tasteStore.profile.favouriteFilm,
                    focus: .film
                )

                field(
                    label: "A director or actor you love",
                    placeholder: "Quentin Tarantino",
                    optional: true,
                    text: $tasteStore.profile.director,
                    focus: .director
                )

                field(
                    label: "What do you love about it?",
                    placeholder: "The storyline, and all the old Hollywood",
                    optional: true,
                    multiline: true,
                    text: $tasteStore.profile.why,
                    focus: .why
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

    private func field(
        label: String,
        placeholder: String,
        optional: Bool = false,
        multiline: Bool = false,
        text: Binding<String>,
        focus: Field
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
        }
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
            .font(.dearBellaButton)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(tasteStore.profile.isUsable ? Theme.cyan : Theme.cyan.opacity(0.35))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                .font(.dearBellaButton)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.cyan)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(saved)

            Link(destination: WatchlistStore.watchURL(for: film.savedFilm)) {
                Label("Where to watch", systemImage: "play.rectangle")
                    .font(.inter(15, weight: .medium))
                    .foregroundStyle(Theme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Capsule())
            }

            Button {
                Task {
                    viewModel.reset()
                    await viewModel.find(taste: tasteStore.profile, context: context)
                }
            } label: {
                Text("Not this one — try again")
                    .font(.inter(15, weight: .medium))
                    .foregroundStyle(Theme.cream.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
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
