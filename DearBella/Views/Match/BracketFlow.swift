import SwiftUI

/// Presents the bracket from inside Match.
///
/// `BracketView` was written as a tab, so it has no way out of its own — it
/// relied on the tab bar being there. Presented modally it needs one, which is
/// all this adds.
struct BracketFlow: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            BracketView()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.cream.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.top, 8)
            .accessibilityLabel("Close")
        }
    }
}
