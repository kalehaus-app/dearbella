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

    /// Director IDs the user named, in pick order.
    @Published var selectedDirectorIDs: [String] {
        didSet { persistSelections() }
    }

    /// Whether onboarding is finished. Drives which screen the app shows.
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.completed) }
    }

    /// The most films the user may pick on the "top 5" screen.
    let maxFilms = 5

    /// The most directors the user may pick. Fewer than the film cap on
    /// purpose: naming five directors is a much harder ask than naming five
    /// films, and three is already a strong signal.
    let maxDirectors = 3

    private enum Keys {
        static let genres = "onboarding.selectedGenreIDs"
        static let films = "onboarding.selectedFilmIDs"
        static let directors = "onboarding.selectedDirectorIDs"
        static let completed = "onboarding.hasCompleted"
    }

    init() {
        let defaults = UserDefaults.standard
        selectedGenreIDs = Set(defaults.stringArray(forKey: Keys.genres) ?? [])
        selectedFilmIDs = defaults.stringArray(forKey: Keys.films) ?? []
        selectedDirectorIDs = defaults.stringArray(forKey: Keys.directors) ?? []
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

    // MARK: - Directors

    func isDirectorSelected(_ id: String) -> Bool {
        selectedDirectorIDs.contains(id)
    }

    var isDirectorSelectionFull: Bool {
        selectedDirectorIDs.count >= maxDirectors
    }

    /// Adds the director if there's room, or removes them if already picked.
    func toggleDirector(_ id: String) {
        if let index = selectedDirectorIDs.firstIndex(of: id) {
            selectedDirectorIDs.remove(at: index)
        } else if selectedDirectorIDs.count < maxDirectors {
            selectedDirectorIDs.append(id)
        }
    }

    /// The user's picked directors resolved to full `Director` values.
    var selectedDirectors: [Director] {
        selectedDirectorIDs.compactMap { id in
            SampleData.directors.first { $0.id == id }
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
        selectedDirectorIDs = []
        hasCompletedOnboarding = false
    }

    private func persistSelections() {
        let defaults = UserDefaults.standard
        defaults.set(Array(selectedGenreIDs), forKey: Keys.genres)
        defaults.set(selectedFilmIDs, forKey: Keys.films)
        defaults.set(selectedDirectorIDs, forKey: Keys.directors)
    }
}
