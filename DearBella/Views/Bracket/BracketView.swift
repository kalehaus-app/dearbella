import SwiftUI

/// The Bracket tab: a movie tournament picker. Switches between genre selection,
/// loading, head-to-head matchups, and the winner screen.
struct BracketView: View {
    @StateObject private var viewModel = BracketViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch viewModel.stage {
            case .genre:
                BracketGenrePicker(viewModel: viewModel)
            case .loading:
                loadingState
            case .playing:
                BracketMatchupView(viewModel: viewModel)
            case .finished:
                if let winner = viewModel.winner {
                    BracketWinnerView(viewModel: viewModel, winner: winner)
                }
            case .failed:
                failedState
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Theme.highlight)
            Text("Building your bracket…")
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream.opacity(0.7))
        }
    }

    private var failedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Theme.cream.opacity(0.5))
            Text("Couldn't build a bracket for that genre right now.")
                .font(.dearBellaCaption)
                .foregroundStyle(Theme.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                viewModel.reset()
            } label: {
                Text("Try another genre")
                    .font(.dearBellaButton)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.highlight)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    BracketView()
        .environmentObject(WatchlistStore())
        .environmentObject(HiddenFilmsStore.shared)
}
