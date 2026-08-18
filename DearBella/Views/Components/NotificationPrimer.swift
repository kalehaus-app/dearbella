import SwiftUI

/// Makes the case for weekly reminders before iOS asks.
///
/// The system permission dialog can only ever be shown once, so spending it on
/// a cold launch — before anyone knows what the app does — throws away the
/// only chance to ask. This appears at a moment when the value is obvious:
/// right after Bella has just decided what to watch. Declining here costs
/// nothing, because iOS was never asked.
struct NotificationPrimer: View {
    let onDecision: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.cyan)

                Text("Want this every Friday?")
                    .font(.dmSerif(28))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)

                Text("Bella can have a pick waiting at 6:30 on Friday and Saturday evenings — right when you're deciding, instead of whenever you remember to look.")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)

                buttons
                    .padding(.top, 6)
            }
            .padding(28)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.75))
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    isRequesting = true
                    await NotificationService.shared.enable()
                    finish()
                }
            } label: {
                Group {
                    if isRequesting {
                        ProgressView().tint(Theme.ink)
                    } else {
                        Text("Remind me")
                    }
                }
                .font(.dearBellaButton)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.cyan)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isRequesting)

            Button {
                NotificationService.shared.declineOffer()
                finish()
            } label: {
                Text("No thanks")
                    .font(.inter(15, weight: .medium))
                    .foregroundStyle(Theme.cream.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .disabled(isRequesting)
        }
    }

    private func finish() {
        onDecision()
        dismiss()
    }
}
