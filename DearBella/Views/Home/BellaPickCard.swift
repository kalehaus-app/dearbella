import SwiftUI

/// "Bella's Pick Today" — the dashboard's daily-return card. Shows one
/// personalized pick (cached per day), a Save action, a "Not tonight" escape
/// hatch for a fresh pick, and the daily streak. Replaces the old Film Fact card.
struct BellaPickCard: View {
    @EnvironmentObject private var store: OnboardingStore
    @EnvironmentObject private var watchlist: WatchlistStore
    @StateObject private var viewModel = DailyPickViewModel()
    @StateObject private var streak = StreakStore.shared

    private let cardBackground = Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)   // #1A1A1A
    private let cardBorder = Color(red: 42 / 255, green: 42 / 255, blue: 42 / 255)       // #2A2A2A
    private let streakYellow = Color(red: 1, green: 1, blue: 1 / 255)                    // #FFFF01

    /// Taste signals: what they've rated and reacted to, seeded with their
    /// onboarding genres and films.
    private var tasteContext: TasteContext {
        TasteContext(
            films: watchlist.films,
            onboardingGenres: SampleData.genres
                .filter { store.selectedGenreIDs.contains($0.id) }
                .map(\.name),
            onboardingFilms: store.selectedFilms.map(\.title)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(cardBorder, lineWidth: 1))
        .task {
            streak.registerEngagement()
            await viewModel.loadIfNeeded(context: tasteContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("TODAY · BELLA'S PICK")
                .font(.inter(12, weight: .semibold))
                .foregroundStyle(Theme.cyan)
            Spacer()
            if streak.count > 0 {
                Text("🔥 \(streak.count) day streak")
                    .font(.inter(12, weight: .bold))
                    .foregroundStyle(streakYellow)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let pick = viewModel.pick {
            pickContent(pick)
        } else if viewModel.isLoading {
            HStack(spacing: 8) {
                ProgressView().tint(Theme.cyan)
                Text("Bella's choosing tonight's pick…")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.error ?? "No pick yet.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.7))
                notTonightButton(title: "Try again")
            }
        }
    }

    private func pickContent(_ pick: DailyPick) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Color.clear
                    .frame(width: 90, height: 135)
                    .overlay { PosterImage(posterPath: pick.posterPath, seed: pick.title) }
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 6) {
                    Text(pick.year != nil ? "\(pick.title) (\(pick.year!))" : pick.title)
                        .font(.dmSerif(24))
                        .foregroundStyle(Theme.cream)
                    if !pick.genres.isEmpty {
                        Text(pick.genres.prefix(3).joined(separator: ", "))
                            .font(.inter(13, weight: .medium))
                            .foregroundStyle(Theme.cream.opacity(0.6))
                    }
                }
                Spacer(minLength: 0)
            }

            if !pick.reason.isEmpty {
                Text(pick.reason)
                    .font(.inter(15))
                    .foregroundStyle(Theme.cream)
                    .lineSpacing(2)
            }

            HStack(spacing: 12) {
                saveButton(pick)
                notTonightButton(title: "Not tonight → show another")
            }
        }
    }

    // MARK: - Actions

    private func saveButton(_ pick: DailyPick) -> some View {
        let saved = watchlist.isSaved(pick.savedFilm.id)
        return Button {
            watchlist.save(pick.savedFilm)
        } label: {
            Label(saved ? "Saved" : "Save", systemImage: saved ? "checkmark" : "plus")
                .font(.dearBellaButton)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.cyan)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(saved)
        .opacity(saved ? 0.7 : 1)
    }

    private func notTonightButton(title: String) -> some View {
        Button {
            Task { await viewModel.notTonight(context: tasteContext) }
        } label: {
            Text(title)
                .font(.inter(14, weight: .semibold))
                .foregroundStyle(Theme.cream.opacity(0.7))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }
}

#Preview {
    BellaPickCard()
        .environmentObject(OnboardingStore())
        .environmentObject(WatchlistStore())
        .padding()
        .background(Color.black)
}
