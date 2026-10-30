import Foundation
import Testing
@testable import NineByFour

// Adding an artist to the Top 20, end to end through APIClient against a
// stubbed server. Clout is counted on the server from Top 20 entries
// (nineByFourApi #160): the app must make exactly one request, read the new
// clout from its response, and never call the old /clout endpoints.
//
// Serialized because the stub server is shared state.
@MainActor
@Suite(.serialized)
struct TopTwentyTests {
    private static let artistJSON = #"{"artist_id":85,"artist_name":"Michael Jackson","count":5}"#

    init() {
        URLProtocol.registerClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        KeychainHelper.shared.saveToken("test-token")
    }

    private func artist() throws -> Artist {
        try JSONDecoder().decode(Artist.self, from: Data(Self.artistJSON.utf8))
    }

    @Test func profileTabAddShowsTheServersClout() async throws {
        StubURLProtocol.stub("POST", "/profile/list/85", status: 201, body: #"{"position":1,"clout":6}"#)
        let vm = ProfileViewModel()

        await vm.addToProfileList(artist: try artist())

        #expect(StubURLProtocol.calls == ["POST /profile/list/85"])
        #expect(vm.profileList.map(\.artistId) == [85])
        #expect(vm.profileList.first?.count == 6)
    }

    @Test func profileTabAddStillWorksWithoutCloutInTheResponse() async throws {
        // Regression: #160 changed the clout endpoint's response and this add
        // saved on the server but never showed in the list.
        StubURLProtocol.stub("POST", "/profile/list/85", status: 201, body: #"{"position":1}"#)
        let vm = ProfileViewModel()

        await vm.addToProfileList(artist: try artist())

        #expect(vm.profileList.first?.count == 6)
    }

    @Test func profileTabLeavesTheListAloneIfTheAddFails() async throws {
        StubURLProtocol.stub("POST", "/profile/list/85", status: 500, body: #"{"message":"Server error"}"#)
        let vm = ProfileViewModel()

        await vm.addToProfileList(artist: try artist())

        #expect(vm.profileList.isEmpty)
    }

    @Test func artistSheetAddUpdatesTheFlameCount() async throws {
        StubURLProtocol.stub("POST", "/profile/list/85", status: 201, body: #"{"position":4,"clout":6}"#)
        let vm = ArtistDetailViewModel()
        vm.artist = try artist()

        await vm.addToProfileList(isAuthenticated: true)

        #expect(StubURLProtocol.calls == ["POST /profile/list/85"])
        #expect(vm.isInProfileList)
        #expect(vm.artist?.count == 6)
    }

    @Test func artistSheetUndoesTheOptimisticAddOnFailure() async throws {
        StubURLProtocol.stub("POST", "/profile/list/85", status: 500, body: #"{"message":"Server error"}"#)
        let vm = ArtistDetailViewModel()
        vm.artist = try artist()

        await vm.addToProfileList(isAuthenticated: true)

        #expect(!vm.isInProfileList)
        #expect(vm.profileListCount == 0)
        #expect(vm.artist?.count == 5)
    }

    @Test func noRequestsAreMadeWhenSignedOut() async throws {
        let vm = ArtistDetailViewModel()
        vm.artist = try artist()

        await vm.addToProfileList(isAuthenticated: false)

        #expect(StubURLProtocol.calls.isEmpty)
    }
}
