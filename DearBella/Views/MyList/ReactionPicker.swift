import SwiftUI

/// The one-tap "how was it?" row. Tapping the selected reaction again clears
/// it, so there's always a way back out without a separate reset control.
struct ReactionPicker: View {
    let selection: FilmReaction?
    let onSelect: (FilmReaction?) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FilmReaction.allCases) { reaction in
                button(for: reaction)
            }
        }
    }

    private func button(for reaction: FilmReaction) -> some View {
        let isSelected = selection == reaction

        return Button {
            onSelect(isSelected ? nil : reaction)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: reaction.symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(reaction.title)
                    .font(.inter(13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Theme.ink : Theme.cream)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.cyan : Color.white.opacity(0.06))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isSelected ? Color.clear : Theme.cream.opacity(0.22),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reaction.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}


/// Icon-only reactions, sized for a grid card.
///
/// The full picker is too wide for a two-column grid, but making someone open
/// a sheet to answer "did you like it?" is what stops them answering at all.
struct CompactReactionRow: View {
    let selection: FilmReaction?
    let onSelect: (FilmReaction?) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(FilmReaction.allCases) { reaction in
                let isSelected = selection == reaction

                Button {
                    onSelect(isSelected ? nil : reaction)
                } label: {
                    Image(systemName: reaction.symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.ink : Theme.cream.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(isSelected ? Theme.cyan : Color.white.opacity(0.07))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(reaction.title)
            }
        }
    }
}
