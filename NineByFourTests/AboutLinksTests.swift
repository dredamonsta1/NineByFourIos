import Foundation
import Testing
@testable import NineByFour

// The in-app credit and legal links. MusicBrainz's CC BY-NC-SA tags require
// attribution, and the Terms/Privacy links must reach the live pages.
@MainActor
struct AboutLinksTests {
    @Test func creditNamesAndLinksAllThreeSources() {
        let credit = AboutLinks.credit
        let text = String(credit.characters)

        #expect(text == "Music data from MusicBrainz and ListenBrainz, projects of the MetaBrainz Foundation.")
        let links = credit.runs.compactMap(\.link)
        #expect(links == [AboutURL.musicBrainz, AboutURL.listenBrainz, AboutURL.metaBrainz])
    }

    @Test(arguments: [
        (AboutURL.terms, "https://onstanbox.com/terms"),
        (AboutURL.privacy, "https://onstanbox.com/privacy"),
        (AboutURL.support, "https://onstanbox.com/support"),
    ])
    func legalLinksPointAtTheLiveSite(url: URL, expected: String) {
        #expect(url.absoluteString == expected)
    }
}
