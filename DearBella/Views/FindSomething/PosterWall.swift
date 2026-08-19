import SwiftUI

/// A film to start from, shown as art.
struct BrowseFilm: Identifiable, Hashable {
    let id: String
    let title: String
    let posterPath: String?
}

/// A wall of posters under the search box.
///
/// The screen was a heading, a box and black — nothing to look at, no sign the
/// app had a catalogue behind it, and no way in except typing. Posters fix all
/// three: art fills the screen the moment it opens, and tapping one is faster
/// than typing a title you half-remember.
///
/// Their own list leads, because a film they already saved is the likeliest
/// thing they'd reach for.
struct PosterWall: View {
    let films: [BrowseFilm]
    let onPick: (BrowseFilm) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(films) { film in
                Button { onPick(film) } label: {
                    PosterImage(posterPath: film.posterPath, seed: film.title, size: "w185")
                        .aspectRatio(0.66, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(film.title)
            }
        }
    }
}
