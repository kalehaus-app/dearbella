import SwiftUI

/// "Whose films do you watch for?" — the third onboarding pick.
///
/// Genres say what shelf to browse and a top five says what a good night looks
/// like, but a director is the only one of the three that describes a
/// *sensibility*. Someone who names Wong Kar-wai and Lynne Ramsay has told
/// Bella more in two taps than the genre grid could in ten, and it's the
/// signal that most reliably produces a recommendation they haven't already
/// heard of.
///
/// Skippable on purpose. Plenty of people who love films couldn't name three
/// directors, and making them fail a quiz on the way in is the wrong first
/// impression — the button says "Skip for now" until they pick someone.
struct DirectorSelectionView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var catalog: MovieCatalog
    let onContinue: () -> Void

    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var filteredDirectors: [Director] {
        guard !searchText.isEmpty else { return SampleData.directors }
        return SampleData.directors.filter { $0.matches(searchText) }
    }

    private var continueTitle: String {
        store.selectedDirectorIDs.isEmpty
            ? "Skip for now"
            : "Continue (\(store.selectedDirectorIDs.count)/\(store.maxDirectors))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            SearchField(placeholder: "Search a name or a film", text: $searchText)
                .padding(.horizontal, 20)

            grid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { footer }
        .task { await catalog.loadDirectorPortraitsIfNeeded() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Whose films do\nyou watch for?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Pick up to \(store.maxDirectors). This is the one that really teaches Bella your taste.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(filteredDirectors) { director in
                    let isSelected = store.isDirectorSelected(director.id)

                    DirectorCard(
                        director: director,
                        profilePath: catalog.profilePath(directorID: director.id),
                        isSelected: isSelected,
                        isDimmed: store.isDirectorSelectionFull && !isSelected
                    ) {
                        store.toggleDirector(director.id)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
        }
    }

    private var footer: some View {
        PrimaryButton(title: continueTitle, action: onContinue)
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

#Preview {
    DirectorSelectionView(onContinue: {})
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
}
