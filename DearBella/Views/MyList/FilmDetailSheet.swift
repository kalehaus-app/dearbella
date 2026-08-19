import SwiftUI

/// Everything the user can record about one saved film: where it sits in their
/// list, what they thought of it, and any note they want to keep.
///
/// It reads the film back out of the store by id on every render rather than
/// holding the copy it was opened with, so edits made here — including the
/// automatic promotion to "watched" when you rate something — are reflected
/// immediately without any local mirroring of store state.
struct FilmDetailSheet: View {
    let filmID: String

    @EnvironmentObject private var watchlist: WatchlistStore
    @EnvironmentObject private var hidden: HiddenFilmsStore
    @Environment(\.dismiss) private var dismiss

    @State private var noteDraft = ""
    @State private var didLoadNote = false
    @State private var showRemoveConfirm = false
    @FocusState private var noteFocused: Bool

    private var film: SavedFilm? { watchlist.film(id: filmID) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let film {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            hero(film)
                            statusSection(film)
                            reactionSection(film)
                            ratingSection(film)
                            noteSection
                            actions(film)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .scrollDismissesKeyboard(.interactively)
                } else {
                    // The film was removed while the sheet was open.
                    Color.clear.onAppear { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        commitNote()
                        dismiss()
                    }
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.highlight)
                }
            }
        }
        .onAppear {
            guard !didLoadNote else { return }
            noteDraft = film?.note ?? ""
            didLoadNote = true
        }
        .onDisappear(perform: commitNote)
    }

    // MARK: - Sections

    private func hero(_ film: SavedFilm) -> some View {
        HStack(alignment: .top, spacing: 16) {
            PosterImage(posterPath: film.posterPath, seed: film.title, size: "w342")
                .frame(width: 110, height: 165)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(film.title)
                    .font(.dmSerif(24, relativeTo: .title2))
                    .foregroundStyle(Theme.cream)
                    .fixedSize(horizontal: false, vertical: true)

                if let year = film.year {
                    Text(String(year))
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.textSecondary)
                }

                if !film.genres.isEmpty {
                    Text(film.genres.prefix(3).joined(separator: " · "))
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let watchedAt = film.watchedAt {
                    Label(
                        watchedAt.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.inter(11, weight: .medium))
                    .foregroundStyle(Theme.highlight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 8)
    }

    private func statusSection(_ film: SavedFilm) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("In my list as")

            Picker("Status", selection: Binding(
                get: { film.status },
                set: { watchlist.setStatus($0, for: filmID) }
            )) {
                ForEach(FilmStatus.allCases) { status in
                    Text(status.shortTitle).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func reactionSection(_ film: SavedFilm) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("How was it?")
            ReactionPicker(selection: film.reaction) { reaction in
                watchlist.setReaction(reaction, for: filmID)
            }
        }
    }

    private func ratingSection(_ film: SavedFilm) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Your rating")
                Spacer()
                if film.rating != nil {
                    Button("Clear") { watchlist.setRating(nil, for: filmID) }
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 12) {
                StarRating(rating: Binding(
                    get: { film.rating },
                    set: { watchlist.setRating($0, for: filmID) }
                ))

                if let rating = film.rating {
                    Text(rating.formatted())
                        .font(.inter(15, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                }
            }
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Notes")

            ZStack(alignment: .topLeading) {
                if noteDraft.isEmpty {
                    Text("What did you think? Who'd you watch it with?")
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream.opacity(0.35))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $noteDraft)
                    .focused($noteFocused)
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 110)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.cream.opacity(0.15), lineWidth: 1)
            )
            .onChange(of: noteFocused) { _, focused in
                if !focused { commitNote() }
            }
        }
    }

    private func actions(_ film: SavedFilm) -> some View {
        VStack(spacing: 12) {
            hideToggle(film)

            Link(destination: WatchlistStore.watchURL(for: film)) {
                Label("Where to watch", systemImage: "play.rectangle.fill")
            }
            .buttonStyle(.pill(.primary))

            Button(role: .destructive) {
                showRemoveConfirm = true
            } label: {
                Label("Remove from my list", systemImage: "trash")
                    .font(.inter(15, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "Remove \(film.title) from your list?",
                isPresented: $showRemoveConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    watchlist.remove(film)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your rating and notes for this film will be deleted. To keep them but tidy your list, move it to Archived instead.")
            }
        }
        .padding(.top, 4)
    }

    /// Reversible, unlike the one-way hide button on the swipe and bracket
    /// cards: from here the film is in front of the user, so a toggle they can
    /// flip back is friendlier than a confirmation they can't undo.
    private func hideToggle(_ film: SavedFilm) -> some View {
        let isHidden = hidden.films.contains { $0.id == film.id }

        return Button {
            if isHidden {
                if let entry = hidden.films.first(where: { $0.id == film.id }) {
                    hidden.unhide(entry)
                }
            } else {
                hidden.hide(film)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isHidden ? "eye.slash.fill" : "eye.slash")
                VStack(alignment: .leading, spacing: 2) {
                    Text(isHidden ? "Hidden from suggestions" : "Don't suggest this again")
                        .font(.inter(15, weight: .medium))
                    Text(isHidden
                         ? "Bella won't bring this up. Tap to undo."
                         : "Keeps it out of swipes, brackets and Bella's picks.")
                        .font(.inter(11))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .foregroundStyle(isHidden ? Theme.highlight : Theme.cream.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.inter(11, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)
            .tracking(0.8)
    }

    /// Writes the note back only when it actually changed, so simply opening
    /// and closing the sheet never touches the store.
    private func commitNote() {
        guard didLoadNote, let film else { return }
        let trimmed = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != film.note else { return }
        watchlist.setNote(trimmed, for: filmID)
    }
}
