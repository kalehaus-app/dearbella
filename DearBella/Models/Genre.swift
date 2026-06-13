import Foundation

/// A film genre the user can pick during onboarding.
///
/// `id` is a stable lowercase key (e.g. "rom-com") that we save to disk and
/// will later map to TMDB's genre IDs. `name` is what we show on screen.
struct Genre: Identifiable, Hashable {
    let id: String
    let name: String
}

/// A film shown in the "Select your top 5" grid.
///
/// For Step 2 these come from a hardcoded sample list. In Step 4 we'll
/// replace the source with real TMDB results, but this shape stays the same
/// so the screens don't need to change.
struct SampleFilm: Identifiable, Hashable {
    let id: String
    let title: String
    let year: Int
}
