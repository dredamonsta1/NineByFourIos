import Foundation

/// Public counts (clout, followers…) are only shown once they're big enough
/// to help. Below the threshold a visitor reads "1" or "2" as "nobody is
/// here", which says more about how early StanBox is than about the artist.
/// Hidden, never faked: each number reappears by itself once it passes.
/// Matches the web app's `PUBLIC_COUNT_THRESHOLD` (src/utils/publicCounts.js).
/// Your own Profile tab keeps its real numbers.
enum PublicCount {
    static let threshold = 100

    static func shows(_ count: Int?) -> Bool {
        (count ?? 0) >= threshold
    }
}
