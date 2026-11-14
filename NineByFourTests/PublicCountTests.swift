import Testing
@testable import NineByFour

// Public counts hide below 100, matching the web app (src/utils/publicCounts.js).
@MainActor
struct PublicCountTests {
    @Test(arguments: [(nil as Int?, false), (0, false), (14, false), (99, false), (100, true), (112_583, true)])
    func showsOnlyFromTheThreshold(count: Int?, shown: Bool) {
        #expect(PublicCount.threshold == 100)
        #expect(PublicCount.shows(count) == shown)
    }
}
