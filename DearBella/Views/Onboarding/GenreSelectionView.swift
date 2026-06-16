import SwiftUI

/// "Select your favorite genres" (wireframe Frame 8). A searchable 2-column
/// grid of multi-select tiles. Continue unlocks once at least one is picked.
struct GenreSelectionView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var catalog: MovieCatalog
    let onContinue: () -> Void

    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var filteredGenres: [Genre] {
        guard !searchText.isEmpty else { return SampleData.genres }
        return SampleData.genres.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select your\nfavorite genres")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            SearchField(placeholder: "Search", text: $searchText)
                .padding(.horizontal, 20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(filteredGenres) { genre in
                        SelectableCard(
                            title: genre.name,
                            seed: genre.id,
                            posterPath: catalog.posterPath(filmID: GenreArt.filmID(for: genre.id)),
                            isSelected: store.isGenreSelected(genre.id),
                            aspectRatio: 0.85
                        ) {
                            store.toggleGenre(genre.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: "Continue",
                isEnabled: !store.selectedGenreIDs.isEmpty,
                action: onContinue
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [Theme.background.opacity(0), Theme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

#Preview {
    GenreSelectionView(onContinue: {})
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
}
