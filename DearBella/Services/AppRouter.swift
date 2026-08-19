import Foundation

/// Which tab is showing.
///
/// Held outside `MainTabView` so screens can send people somewhere useful —
/// an empty list pointing at Discover, a reminder opening tonight's pick —
/// without every one of them owning a copy of the tab state.
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Int, Hashable {
        case home = 0
        case discover = 1
        case myList = 2
    }

    @Published var tab: Tab = .home
}
