import SwiftUI

/// A tappable capsule used for mood / feeling / control options.
struct PillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

/// A DearBella message (gray, left-aligned).
struct BellaBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3)
            .lineSpacing(4)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A user message (blue, right-aligned).
struct UserBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3)
            .lineSpacing(4)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// A single recommended film: poster, witty reason, save + where-to-watch.
struct PickCard: View {
    let film: RecommendedFilm
    @EnvironmentObject private var watchlist: WatchlistStore

    var body: some View {
        let saved = watchlist.isSaved(film.savedFilm.id)

        HStack(alignment: .top, spacing: 12) {
            PosterImage(posterPath: film.posterPath, seed: film.title)
                .frame(width: 70, height: 105)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(film.year != nil ? "\(film.title) (\(film.year!))" : film.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text(film.reason)
                    .font(.body)
                    .lineSpacing(3)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 12) {
                    Button {
                        watchlist.toggle(film.savedFilm)
                    } label: {
                        Label(saved ? "Saved" : "Save", systemImage: saved ? "checkmark" : "plus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(saved ? Theme.background : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(saved ? Theme.accent : Theme.surface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Link(destination: WatchlistStore.watchURL(for: film.savedFilm)) {
                        Label("Where to watch", systemImage: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
