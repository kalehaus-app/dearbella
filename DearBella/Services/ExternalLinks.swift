import Foundation

/// Off-app links, in one place so they can be swapped without hunting through
/// views.
///
/// ## Setting the Tally forms
///
/// Create the form in Tally, copy its share URL (it looks like
/// `https://tally.so/r/abc123`), and paste it over the placeholder below.
/// Anything still containing `REPLACE_ME` is treated as unset: the matching
/// entry point disappears from the UI rather than shipping a link that goes
/// nowhere. That means both forms can be filled in independently, whenever
/// each one is ready.
enum ExternalLinks {

    /// General "how are we doing?" feedback survey, linked from About.
    static let feedbackFormURLString = "https://tally.so/r/REPLACE_ME_FEEDBACK"

    /// Waitlist for the Friends feature, opened from the My List teaser.
    static let friendsWaitlistURLString = "https://tally.so/r/REPLACE_ME_FRIENDS"

    static var feedbackForm: URL? { configured(feedbackFormURLString) }
    static var friendsWaitlist: URL? { configured(friendsWaitlistURLString) }

    /// `nil` while the placeholder is still in place, so callers can hide the
    /// entry point instead of offering a broken link.
    private static func configured(_ string: String) -> URL? {
        guard !string.contains("REPLACE_ME") else { return nil }
        return URL(string: string)
    }
}
