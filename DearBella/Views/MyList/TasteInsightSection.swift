import SwiftUI

/// #3 — A short, AI-generated "your taste" summary. Generated only on demand
/// (tap the button), then cached by the view model so it doesn't regenerate on
/// every visit. Handles loading and failure states.
struct TasteInsightSection: View {
    @ObservedObject var viewModel: MyListViewModel
    let context: TasteContext

    /// Expanded by default; remembered for the session.
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let summary = viewModel.tasteSummary {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Text("YOUR TASTE")
                            .font(.inter(12, weight: .semibold))
                            .foregroundStyle(Theme.cream.opacity(0.6))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.cyan)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Text(summary)
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else if viewModel.isLoadingSummary {
                HStack(spacing: 8) {
                    ProgressView().tint(Theme.cyan)
                    Text("Reading your taste…")
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.7))
                }
            } else {
                Button {
                    Task { await viewModel.generateTasteSummary(context: context) }
                } label: {
                    Label("My taste", systemImage: "sparkles")
                        .font(.inter(14, weight: .semibold))
                        .foregroundStyle(Theme.cyan)
                }
                .buttonStyle(.plain)
            }

            if let error = viewModel.summaryError {
                Text(error)
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
}
