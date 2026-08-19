import SwiftUI

/// The way into Match: what kind of evening do you want?
///
/// Asking first is the whole difference between Match and a plain deck. A deck
/// of popular films has to guess; once someone has said "wreck me" or "horror",
/// every card after that is already in the right neighbourhood.
///
/// Two ways in, under their own headings. The moods are the interesting half
/// and lead — but a screen of nothing but abstract phrases gives a first-time
/// user nothing familiar to grab, so genres sit underneath as the plain answer
/// for someone who already knows what they want.
struct MatchVibePicker: View {
    let onSelect: (MatchSource) -> Void
    let onBracket: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                moodSection
                genreSection
                bracketEntry
            }
            .padding(.bottom, 32)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Match")
                .font(.dearBellaTitle)
                .foregroundStyle(Theme.cream)
            Text("Tell Bella what you're after and she'll deal you a deck.")
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Moods

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("What kind of night is it?")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(MatchVibe.all) { vibe in
                    moodCard(vibe)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func moodCard(_ vibe: MatchVibe) -> some View {
        Button {
            onSelect(.vibe(vibe))
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

    // MARK: - Genres

    /// Deliberately plainer than the mood cards — smaller, no art, no copy.
    /// This is the shortcut for someone who already knows, and it shouldn't
    /// compete with the half of the screen that's actually differentiated.
    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Or just pick a genre")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TMDBGenre.all, id: \.id) { genre in
                        Button {
                            onSelect(.genre(id: genre.id, name: genre.name))
                        } label: {
                            Text(genre.name)
                                .font(.inter(14, weight: .semibold))
                                .foregroundStyle(Theme.cream)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Theme.cream.opacity(0.18), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Bracket

    /// Bracket, as a third way to decide rather than a tab of its own. It
    /// belongs here because "I can't choose" is the same problem the moods
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
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.inter(11, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)
            .tracking(0.8)
            .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        MatchVibePicker(onSelect: { _ in }, onBracket: {})
    }
}
