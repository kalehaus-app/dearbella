import SwiftUI

/// Advertises the Friends feature before it exists, and measures whether
/// anyone actually wants it.
///
/// "Notify me" is recorded on-device so the card can acknowledge the tap
/// straight away and stay acknowledged. If a waitlist form is configured it
/// also opens, which is where a real signal (and a way to reach people when it
/// ships) comes from — but the card works fine without one, so the teaser can
/// go live before the form exists.
struct FriendsTeaserCard: View {
    @AppStorage("friends.notifyMe") private var isOnWaitlist = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.cyan)
                Text("Watch with friends")
                    .font(.dmSerif(22, relativeTo: .title3))
                    .foregroundStyle(Theme.cream)
                Spacer()
                Text("Coming soon")
                    .font(.inter(10, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.cyan)
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
                .stroke(Theme.cyan.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var notifyButton: some View {
        if isOnWaitlist {
            Label("We'll let you know", systemImage: "checkmark.circle.fill")
                .font(.inter(13, weight: .semibold))
                .foregroundStyle(Theme.cyan)
                .padding(.top, 2)
        } else {
            Button {
                isOnWaitlist = true
                if let url = ExternalLinks.friendsWaitlist { openURL(url) }
            } label: {
                Text("Notify me")
                    .font(.inter(14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Theme.cyan)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}
