import SwiftUI

/// Holds the user's onboarding choices and saves them on-device.
///
/// This is an `ObservableObject`: any SwiftUI view that watches it
/// (`@EnvironmentObject`) redraws automatically when a value changes.
///
/// Persistence uses `UserDefaults` — Apple's built-in key/value store for
/// small bits of user data. Every time a selection changes we write it out,
/// so the choices survive app relaunches (your "yes to on-device saving").
@MainActor
final class OnboardingStore: ObservableObject {

    /// Genre IDs the user tapped (order doesn't matter, so a Set).
    @Published var selectedGenreIDs: Set<String> {
        didSet { persistSelections() }
    }

    /// Film IDs in the order the user picked them (so we can number them 1–5).
    @Published var selectedFilmIDs: [String] {
        didSet { persistSelections() }
    }

    /// Whether onboarding is finished. Drives which screen the app shows.
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.completed) }
    }

    /// The most films the user may pick on the "top 5" screen.
    let maxFilms = 5

    private enum Keys {
        static let genres = "onboarding.selectedGenreIDs"
        static let films = "onboarding.selectedFilmIDs"
        static let completed = "onboarding.hasCompleted"
    }

    init() {
        let defaults = UserDefaults.standard
        selectedGenreIDs = Set(defaults.stringArray(forKey: Keys.genres) ?? [])
        selectedFilmIDs = defaults.stringArray(forKey: Keys.films) ?? []
        hasCompletedOnboarding = defaults.bool(forKey: Keys.completed)
    }

    // MARK: - Genres

    func isGenreSelected(_ id: String) -> Bool {
        selectedGenreIDs.contains(id)
    }

    func toggleGenre(_ id: String) {
        if selectedGenreIDs.contains(id) {
            selectedGenreIDs.remove(id)
        } else {
            selectedGenreIDs.insert(id)
        }
    }

    // MARK: - Films

    /// The 1-based position of a film in the user's picks, or `nil` if unpicked.
    func filmSelectionNumber(_ id: String) -> Int? {
        guard let index = selectedFilmIDs.firstIndex(of: id) else { return nil }
        return index + 1
    }

    var isFilmSelectionFull: Bool {
        selectedFilmIDs.count >= maxFilms
    }

    /// Adds the film if there's room, or removes it if already picked.
    func toggleFilm(_ id: String) {
        if let index = selectedFilmIDs.firstIndex(of: id) {
            selectedFilmIDs.remove(at: index)
        } else if selectedFilmIDs.count < maxFilms {
            selectedFilmIDs.append(id)
        }
    }

    /// The user's picked films resolved to full `SampleFilm` values.
    var selectedFilms: [SampleFilm] {
        selectedFilmIDs.compactMap { id in
            SampleData.films.first { $0.id == id }
        }
    }

    // MARK: - Lifecycle

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// Wipes all choices — handy for re-running the flow during testing.
    func resetOnboarding() {
        selectedGenreIDs = []
        selectedFilmIDs = []
        hasCompletedOnboarding = false
    }

    private func persistSelections() {
        let defaults = UserDefaults.standard
        defaults.set(Array(selectedGenreIDs), forKey: Keys.genres)
        defaults.set(selectedFilmIDs, forKey: Keys.films)
    }
}
