import SwiftUI

/// A quiet invitation to fill in the feedback survey.
///
/// Deliberately understated — it sits at the bottom of a screen people reach
/// by choice, so it doesn't need to shout, and shouting would make it feel
/// like a growth prompt rather than a genuine ask. Disappears entirely when no
/// form URL is configured.
struct FeedbackLink: View {
    /// Where in the app this was opened from, recorded against the response.
    let source: String

    var body: some View {
        if let url = ExternalLinks.feedbackForm(source: source) {
            Link(destination: url) {
                VStack(spacing: 4) {
                    Text("Tell us what to build next")
                        .font(.inter(14, weight: .semibold))
                        .foregroundStyle(Theme.cyan)
                    Text("Two minutes, and it genuinely shapes what gets built.")
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
    }
}
