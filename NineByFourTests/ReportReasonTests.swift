import Testing
@testable import NineByFour

// The server rejects any reason outside its allow-list with a 400, which a
// user reads as "reporting is broken". The list below is REPORT_REASONS in
// nineByFourApi src/routes/moderation.ts; if the server changes it, this test
// should change with it.
@MainActor
struct ReportReasonTests {
    private let serverReasons: Set<String> = [
        "spam", "harassment", "hate_speech", "violence", "sexual_content",
        "self_harm", "impersonation", "misinformation", "copyright", "other",
    ]

    @Test func everyReasonIsOneTheServerAccepts() {
        #expect(Set(ReportReason.allCases.map(\.rawValue)) == serverReasons)
    }
}
