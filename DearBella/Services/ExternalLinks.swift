import Foundation

/// Off-app links, in one place so they can be swapped without hunting through
/// views.
///
/// ## Setting a Tally form
///
/// Paste the form's share URL (like `https://tally.so/r/abc123`) over the
/// placeholder below. Anything still containing `REPLACE_ME` is treated as
/// unset: the entry point that uses it disappears from the UI rather than
/// shipping a link that goes nowhere. So each form can be filled in
/// independently, whenever it's ready.
enum ExternalLinks {

    /// "Help shape Dear Bella" — the feedback survey.
    static let feedbackFormURLString = "https://tally.so/r/Y57Zg0"

    /// Waitlist for the Friends feature. Not yet built; the teaser card still
    /// records interest on-device without it.
    static let friendsWaitlistURLString = "https://tally.so/r/REPLACE_ME_FRIENDS"

    /// The feedback form, tagged with where in the app it was opened from.
    ///
    /// The form has a matching `source` hidden field, so responses from inside
    /// the app can be told apart from ones opened via a link shared elsewhere —
    /// and one entry point can be told from another. Those are different
    /// populations and tend to answer differently, which is impossible to
    /// reconstruct after the fact if it isn't captured up front.
    static func feedbackForm(source: String) -> URL? {
        configured(feedbackFormURLString, source: source)
    }

    static var friendsWaitlist: URL? {
        configured(friendsWaitlistURLString, source: "ios-friends-teaser")
    }

    /// `nil` while the placeholder is still in place, so callers can hide the
    /// entry point instead of offering a broken link.
    private static func configured(_ string: String, source: String) -> URL? {
        guard !string.contains("REPLACE_ME"),
              var components = URLComponents(string: string) else { return nil }

        components.queryItems = (components.queryItems ?? [])
            + [URLQueryItem(name: "source", value: source)]
        return components.url
    }
}
