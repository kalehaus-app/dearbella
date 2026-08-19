import Foundation

/// A director the user can name as one of their own.
///
/// Genres describe a shelf and a top five describes a night; a director
/// describes a *sensibility*, which is the thing that actually predicts what
/// someone will love next. Someone who picks Wong Kar-wai and Céline Sciamma
/// has told us more in two taps than a genre grid could in ten.
///
/// `knownFor` is a single signature film. It's there so the name is
/// recognizable to someone who knows the work but not the credit — plenty of
/// people love *Parasite* without being able to place Bong Joon-ho — and it's
/// searchable alongside the name for exactly that reason.
struct Director: Identifiable, Hashable {
    let id: String
    let name: String
    let knownFor: String

    /// Matches on either the name or the film, so "parasite" finds Bong
    /// Joon-ho and "bong" does too.
    func matches(_ query: String) -> Bool {
        name.localizedCaseInsensitiveContains(query)
            || knownFor.localizedCaseInsensitiveContains(query)
    }
}
