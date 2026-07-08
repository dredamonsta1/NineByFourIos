import Foundation
import Observation

// App-level navigation state. Owns which bottom tab is selected so
// non-tab views (like the album Buy button in ArtistDetailSheet) can
// programmatically switch tabs — e.g. tapping "Owned" on a bought
// album routes into the Library tab.
@Observable
final class Router {
    enum Tab: Int, Hashable {
        case home
        case feed
        case discover
        case messages
        case library
        case profile
    }

    var selectedTab: Tab = .home

    @MainActor
    func openLibrary() {
        selectedTab = .library
    }
}
