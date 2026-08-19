import SwiftUI

/// The way into Match: what kind of evening do you want?
///
/// Asking this first is the whole difference between Match and a plain deck.
/// A deck of popular films has to guess; once someone has said "wreck me" or
/// "something kind", every card afterwards is already in the right
/// neighbourhood — and the question itself is more inviting than a stack of
/// posters, because it's about them rather than the catalogue.
struct MatchVibePicker: View {
    let onSelect: (MatchVibe) -> Void
    let onBracket: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MatchVibe.all) { vibe in
                        card(vibe)
                    }
                }
                .padding(.horizontal, 20)

                bracketEntry
            }
            .padding(.bottom, 32)
        }
    }

    /// Bracket, as a second way to decide rather than a tab of its own. It
    /// belongs here because "I can't choose" is the same problem the vibes
    /// answer, just further along.
    private var bracketEntry: some View {
        Button(action: onBracket) {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Still can't choose?")
                        .font(.inter(15, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                    Text("Put eight head to head and let a bracket settle it.")
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.55))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.cream.opacity(0.35))
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cyan.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Match")
                .font(.dearBellaTitle)
                .foregroundStyle(Theme.cream)
            Text("What kind of night is it?")
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func card(_ vibe: MatchVibe) -> some View {
        Button {
            onSelect(vibe)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: vibe.symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.cyan)

                Text(vibe.title)
                    .font(.dmSerif(19, relativeTo: .title3))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(vibe.tagline)
                    .font(.inter(11))
                    .foregroundStyle(Theme.cream.opacity(0.55))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cream.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(vibe.title). \(vibe.tagline)")
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        MatchVibePicker(onSelect: { _ in }, onBracket: {})
    }
}
