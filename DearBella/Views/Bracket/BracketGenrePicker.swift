import SwiftUI

/// Genre selection for the bracket — compact icon cards, 3 per row, on true
/// black. Each card is an SF Symbol (cyan) over the genre name. Picking one
/// kicks off the bracket.
struct BracketGenrePicker: View {
    @ObservedObject var viewModel: BracketViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bracket")
                .font(.dmSerif(32))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Text("Pick a genre to build your 8-movie bracket.")
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream.opacity(0.7))
                .padding(.horizontal, 20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(TMDBGenre.all, id: \.id) { genre in
                        Button {
                            Task { await viewModel.start(genreID: genre.id) }
                        } label: {
                            genreCard(name: genre.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func genreCard(name: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: Self.icon(for: name))
                .font(.system(size: 26))
                .foregroundStyle(Theme.highlight)
            Text(name)
                .font(.inter(13, weight: .medium))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08)))
    }

    /// A fitting SF Symbol per TMDB genre.
    private static func icon(for genre: String) -> String {
        switch genre {
        case "Action":      return "flame.fill"
        case "Adventure":   return "map.fill"
        case "Animation":   return "sparkles"
        case "Comedy":      return "theatermasks.fill"
        case "Crime":       return "exclamationmark.shield.fill"
        case "Documentary": return "doc.fill"
        case "Drama":       return "theatermasks"
        case "Family":      return "person.3.fill"
        case "Fantasy":     return "wand.and.stars"
        case "History":     return "book.closed.fill"
        case "Horror":      return "moon.stars.fill"
        case "Music":       return "music.note"
        case "Mystery":     return "magnifyingglass"
        case "Romance":     return "heart.fill"
        case "Sci-Fi":      return "atom"
        case "Thriller":    return "bolt.fill"
        case "War":         return "shield.fill"
        case "Western":     return "mountain.2.fill"
        default:            return "film.fill"
        }
    }
}
