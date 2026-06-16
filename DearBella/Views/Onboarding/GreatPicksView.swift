import SwiftUI

/// The closing "Great picks!" reveal (wireframe Frame 42). The user's chosen
/// films fan out with a spring animation, then "Continue" finishes onboarding.
struct GreatPicksView: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var catalog: MovieCatalog
    let onFinished: () -> Void

    @State private var revealed = false

    /// Use the user's picks; fall back to a few samples if somehow empty.
    private var films: [SampleFilm] {
        let picks = store.selectedFilms
        return picks.isEmpty ? Array(SampleData.films.prefix(4)) : picks
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                fannedPosters

                Text("Great picks!")
                    .font(.title).bold()
                    .foregroundStyle(Theme.textPrimary)

                PageDots(count: 3, activeIndex: 2)

                Spacer()

                PrimaryButton(title: "Continue", action: onFinished)
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                revealed = true
            }
        }
    }

    private var fannedPosters: some View {
        let shown = Array(films.prefix(5))
        let middle = Double(shown.count - 1) / 2.0

        return ZStack {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, film in
                let offsetFromCenter = Double(index) - middle
                Color.clear
                    .frame(width: 76, height: 116)
                    .overlay {
                        ZStack(alignment: .bottomLeading) {
                            PosterImage(posterPath: catalog.posterPath(filmID: film.id), seed: film.id)
                            Text(film.title)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(5)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.15)))
                    .rotationEffect(.degrees(revealed ? offsetFromCenter * 9 : 0))
                    .offset(x: revealed ? offsetFromCenter * 36 : 0)
                    .scaleEffect(revealed ? 1 : 0.7)
                    .opacity(revealed ? 1 : 0)
            }
        }
        .frame(height: 150)
    }
}

#Preview {
    GreatPicksView(onFinished: {})
        .environmentObject(OnboardingStore())
        .environmentObject(MovieCatalog())
}
