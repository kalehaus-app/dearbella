import SwiftUI

/// A director's portrait with their name and one signature film beneath it.
///
/// Deliberately not a `SelectableCard`: a face wants a taller, narrower crop
/// than a poster, and the name has to sit *outside* the image rather than over
/// it — a name burned across someone's face reads as a caption on a photograph
/// instead of a thing you can tap.
struct DirectorCard: View {
    let director: Director
    var profilePath: String? = nil
    let isSelected: Bool
    var isDimmed: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                portrait
                label
            }
        }
        .buttonStyle(.plain)
        .opacity(isDimmed ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var portrait: some View {
        Color.clear
            .aspectRatio(0.74, contentMode: .fit)
            .overlay {
                Color.clear
                    .overlay {
                        PosterImage(posterPath: profilePath, seed: director.id, size: "w342")
                    }
                    .clipped()
            }
            .overlay {
                // Faces come off TMDB at wildly different exposures. A soft
                // bottom scrim settles them into one grid instead of a patchwork.
                LinearGradient(
                    colors: [.clear, .black.opacity(0.35)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Theme.accent))
                        .padding(6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .stroke(Theme.accent, lineWidth: isSelected ? 3 : 0)
            )
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(director.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)

            Text(director.knownFor)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DirectorCard(
        director: Director(id: "wes-anderson", name: "Wes Anderson", knownFor: "The Grand Budapest Hotel"),
        isSelected: true,
        action: {}
    )
    .frame(width: 110)
    .padding()
    .background(Theme.background)
}
