import Foundation
import Testing
@testable import NineByFour

// A beta tester skipped the waitlist, and signup failed with "You don't have
// permission to perform this action." The server had said why ("Invalid or
// unapproved invite code."), but every 403 was flattened to that generic
// line. The app now shows the server's own message.
extension StubServerSuites {
    @MainActor
    @Suite(.serialized)
    struct SignupErrorTests {
        private struct Body: Encodable {
            let email = "fan@example.com"
            let code = "269702"
            let username = "newfan"
            let invite_code = "NOTREAL"
        }

        init() {
            URLProtocol.registerClass(StubURLProtocol.self)
            StubURLProtocol.reset()
        }

        private func signupError() async -> String? {
            do {
                try await APIClient.shared.requestVoid(endpoint: .verifyCode, body: Body())
                return nil
            } catch {
                return error.localizedDescription
            }
        }

        @Test func showsWhyTheServerRefused() async {
            StubURLProtocol.stub("POST", "/auth/verify-code", status: 403,
                                 body: #"{"message":"Invalid or unapproved invite code."}"#)
            #expect(await signupError() == "Invalid or unapproved invite code.")
        }

        @Test func showsTheExpiredInviteMessageToo() async {
            StubURLProtocol.stub("POST", "/auth/verify-code", status: 403,
                                 body: #"{"message":"That invite expired. Ask for a new one.","reason":"invite_expired"}"#)
            #expect(await signupError() == "That invite expired. Ask for a new one.")
        }

        @Test func fallsBackToTheGenericLineWhenThereIsNoMessage() async {
            StubURLProtocol.stub("POST", "/auth/verify-code", status: 403,
                                 body: "<html><body>Forbidden</body></html>")
            #expect(await signupError() == "You don't have permission to perform this action.")
        }
    }
}
