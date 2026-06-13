import SwiftUI

/// "Select your top 5 favorite movies" (wireframe Frame 9). A searchable
/// 3-column poster grid. Picks are numbered 1–5 in selection order and capped
/// at 5; unpicked tiles dim once the cap is reached.
struct FilmSelectionView: View {
    @EnvironmentObject private var store: OnboardingStore
    let onContinue: () -> Void

    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var filteredFilms: [SampleFilm] {
        guard !searchText.isEmpty else { return SampleData.films }
        return SampleData.films.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var continueTitle: String {
        store.selectedFilmIDs.isEmpty
            ? "Continue"
            : "Continue (\(store.selectedFilmIDs.count)/\(store.maxFilms))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select your top 5\nfavorites movies")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("(trust us we know this is really hard, you can add more later)")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            SearchField(placeholder: "Search", text: $searchText)
                .padding(.horizontal, 20)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredFilms) { film in
                        let number = store.filmSelectionNumber(film.id)
                        let isSelected = number != nil
                        let isDimmed = store.isFilmSelectionFull && !isSelected

                        SelectableCard(
                            title: film.title,
                            seed: film.id,
                            isSelected: isSelected,
                            badge: number.map(String.init),
                            aspectRatio: 0.66
                        ) {
                            store.toggleFilm(film.id)
                        }
                        .opacity(isDimmed ? 0.45 : 1)
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
                title: continueTitle,
                isEnabled: !store.selectedFilmIDs.isEmpty,
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
    FilmSelectionView(onContinue: {})
        .environmentObject(OnboardingStore())
}
