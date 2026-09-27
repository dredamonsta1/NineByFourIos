import SwiftUI

/// The StanBox wordmark, for the navigation bar.
///
/// Text, not an image — which is what the web does too
/// (`<span class="logoText">StanBox</span>`), and for the same reason: a nav
/// bar gives you roughly 22pt of height, and neither brand asset survives it.
///
/// `VinylMark` is a detailed record whose label carries real type ("2. THE
/// BEAT", "3. VINYL SOUL"). The detail IS the design, so shrinking it to 22pt
/// leaves a black dot with a green speck. `StanBoxLogo` is worse for this job:
/// a 1024x1229 VERTICAL lockup with three discs stacked above the box, so at
/// nav height it renders ~18pt wide with 4pt-tall lettering.
///
/// Both remain correct where they are used — the full lockup is the auth-page
/// hero. Neither is a wordmark, which is the thing a nav bar actually wants.
///
/// Matches the web's treatment: heavy weight, slight negative tracking, and
/// WHITE rather than chartreuse. The brand rule reserves the contrast colour
/// for action; a chartreuse wordmark would make identity compete with the
/// things it sits above.
struct BrandNavMark: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("StanBox")
                .font(.system(size: 19, weight: .heavy))
                .kerning(-0.2)
                .foregroundStyle(Color.Theme.textBright)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

extension View {
    /// Puts the wordmark in the nav bar, keeping the tab's own title as the
    /// large heading beneath it.
    func brandedNavBar() -> some View {
        toolbar { BrandNavMark() }
    }
}
