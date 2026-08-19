import SwiftUI

/// Film search results as a row of posters.
///
/// Posters rather than a text list: recognising cover art is faster than
/// reading titles, and it confirms you've found the right film when several
/// share a name.
struct FilmResultRow: View {
    let films: [TMDBMovie]
    let onPick: (TMDBMovie) -> Void

    var body: some View {
        if !films.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(films) { film in
                        Button { onPick(film) } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                PosterImage(
                                    posterPath: film.posterPath,
                                    seed: film.title ?? "",
                                    size: "w185"
                                )
                                .frame(width: 68, height: 102)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(film.title ?? "")
                                    .font(.inter(11, weight: .medium))
                                    .foregroundStyle(Theme.cream)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                if let year = film.releaseDate?.prefix(4), !year.isEmpty {
                                    Text(String(year))
                                        .font(.inter(10))
                                        .foregroundStyle(Theme.cream.opacity(0.45))
                                }
                            }
                            .frame(width: 68)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.top, 2)
            }
        }
    }
}

/// Person search results as name chips, with their role where TMDB knows it —
/// two people share a name often enough that "Director" earns its place.
struct PersonResultRow: View {
    let people: [TMDBPerson]
    let onPick: (TMDBPerson) -> Void

    var body: some View {
        if !people.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(people) { person in
                        Button { onPick(person) } label: {
                            HStack(spacing: 6) {
                                Text(person.name)
                                    .font(.inter(13, weight: .semibold))
                                    .foregroundStyle(Theme.cream)
                                if let role = person.role {
                                    Text(role)
                                        .font(.inter(10))
                                        .foregroundStyle(Theme.cream.opacity(0.45))
                                }
                            }
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Theme.cyan.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.top, 2)
            }
        }
    }
}
