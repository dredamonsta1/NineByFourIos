import SwiftUI

/// The small vinyl mark, for the navigation bar.
///
/// StanBox uses a two-mark system: the full mark is the auth-page hero, and
/// this small vinyl mark is for navbar, favicon and app icon. `VinylMark` has
/// been sitting in the asset catalog referenced by nothing, while `StanBoxLogo`
/// appeared only on Login and Waitlist — both pre-auth. So once a user signed
/// in, the brand vanished completely, which is precisely the "no StanBox
/// branding on the screens" complaint.
///
/// Sits beside the title rather than replacing it. A phone has little
/// horizontal room, and a wordmark where "Messages" should be costs the user
/// orientation to buy presence the app icon already provides.
struct BrandNavMark: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Image("VinylMark")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(height: 22)
                .accessibilityLabel("StanBox")
        }
    }
}

extension View {
    /// Puts the vinyl mark in the nav bar and keeps the tab's own title as the
    /// large heading beneath it.
    func brandedNavBar() -> some View {
        toolbar { BrandNavMark() }
    }
}
