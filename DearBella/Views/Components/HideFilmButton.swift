import SwiftUI

/// "Don't suggest this again" — the escape hatch for a film that keeps coming
/// back round in the swipe deck or the bracket.
///
/// Confirms first, because the film disappears from places the user isn't
/// currently looking at, and the copy says where it goes so that isn't a
/// surprise.
struct HideFilmButton: View {
    let title: String
    var label = "Don't suggest this again"
    let onHide: () -> Void

    @State private var confirming = false

    var body: some View {
        Button {
            confirming = true
        } label: {
            Label(label, systemImage: "eye.slash")
                .font(.inter(15, weight: .medium))
                .foregroundStyle(Theme.cream.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "Stop suggesting \(title)?",
            isPresented: $confirming,
            titleVisibility: .visible
        ) {
            Button("Don't suggest again", role: .destructive, action: onHide)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It won't show up in your swipe deck, in brackets, or in Bella's recommendations. You can unhide it in Settings.")
        }
    }
}
