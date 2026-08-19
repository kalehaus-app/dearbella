import SwiftUI

/// Advertises the Friends feature before it exists, and measures whether
/// anyone actually wants it.
///
/// "Notify me" is recorded on-device, so once someone has answered, the card
/// thanks them and then retires itself — an ad for something you've already
/// signed up for is just clutter on a screen you visit often. If a waitlist
/// form is configured it also opens, which is where a real signal (and a way
/// to reach people when it ships) comes from, but the card works fine without
/// one so the teaser can go live before the form exists.
struct FriendsTeaserCard: View {
    @AppStorage("friends.notifyMe") private var isOnWaitlist = false
    @Environment(\.openURL) private var openURL

    /// Shows the thank-you for a moment before the card goes. Separate from
    /// `isOnWaitlist` so returning to this screen later skips the animation
    /// and simply renders nothing.
    @State private var isDismissing = false

    var body: some View {
        if !isOnWaitlist || isDismissing {
            card
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.highlight)
                Text("Watch with friends")
                    .font(.dmSerif(22, relativeTo: .title3))
                    .foregroundStyle(Theme.cream)
                Spacer()
                Text("Coming soon")
                    .font(.inter(10, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.highlight)
                    .clipShape(Capsule())
            }

            Text("Compare lists, see what your friends rated, and swap picks for the weekend.")
                .font(.dearBellaCaption)
                .foregroundStyle(Theme.cream.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            notifyButton
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.highlight.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var notifyButton: some View {
        if isOnWaitlist {
            Label("We'll let you know", systemImage: "checkmark.circle.fill")
                .font(.inter(13, weight: .semibold))
                .foregroundStyle(Theme.highlight)
                .padding(.top, 2)
        } else {
            Button {
                if let url = ExternalLinks.friendsWaitlist { openURL(url) }
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDismissing = true
                    isOnWaitlist = true
                }
                // Long enough to read the thank-you, short enough not to nag.
                Task {
                    try? await Task.sleep(nanoseconds: 2_200_000_000)
                    withAnimation(.easeInOut(duration: 0.35)) { isDismissing = false }
                }
            } label: {
                Text("Notify me")
                    .font(.inter(14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Theme.highlight)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}
