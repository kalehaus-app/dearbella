import SwiftUI

/// Genre selection for the bracket — same tile style as onboarding's genre
/// picker (SelectableCard grid). Picking one genre kicks off the bracket.
struct BracketGenrePicker: View {
    @ObservedObject var viewModel: BracketViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
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
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(TMDBGenre.all, id: \.id) { genre in
                        SelectableCard(
                            title: genre.name,
                            seed: genre.name,
                            isSelected: false,
                            aspectRatio: 0.8,
                            titleProminence: .prominent
                        ) {
                            Task { await viewModel.start(genreID: genre.id) }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
