import SwiftUI

/// #1 — Horizontal genre filter pills for My List. "All" plus one pill per
/// genre present among saved films. Selected pill is filled cyan with dark
/// text; unselected pills are dark with cream text and a subtle border.
struct GenreFilterPills: View {
    /// Genres present among saved films (no "All" — added here).
    let genres: [String]
    /// `nil` means "All".
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill(title: "All", isSelected: selected == nil) { selected = nil }
                ForEach(genres, id: \.self) { genre in
                    pill(title: genre, isSelected: selected == genre) { selected = genre }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func pill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.inter(13, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.ink : Theme.cream)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.highlight : Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.clear : Theme.cream.opacity(0.25),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }
}
