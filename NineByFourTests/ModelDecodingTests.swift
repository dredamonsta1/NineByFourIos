import Foundation
import Testing
@testable import NineByFour

// The models must decode what the server actually sends. These run against
// real responses (Support/Fixtures.swift), so a renamed or retyped field shows
// up as a failing test instead of a silent decodingError in the app.
@MainActor
struct ModelDecodingTests {
    private let decoder = JSONDecoder()

    @Test func decodesTheArtistPage() throws {
        let response = try decoder.decode(SingleArtistResponse.self, from: Fixtures.data(Fixtures.artistDetail))
        let artist = response.artist

        #expect(artist.artistId == 85)
        #expect(artist.artistName == "Michael Jackson")
        #expect(artist.count != nil)
        #expect(artist.albums?.isEmpty == false)
    }

    @Test func decodesTheArtistListWithItsPaging() throws {
        let response = try decoder.decode(PaginatedArtistResponse.self, from: Fixtures.data(Fixtures.artistList))

        #expect(response.artists.count == 1)
        // Regression: these keys were snake_case in the model, but the server
        // sends camelCase, so they always decoded as nil.
        #expect(response.hasMore == true)
        #expect((response.totalCount ?? 0) > 0)
        #expect((response.totalPages ?? 0) > 0)
    }

    @Test func readsTheNewClout() throws {
        let response = try decoder.decode(
            ProfileListChangeResponse.self,
            from: Data(#"{"message":"Artist added to list.","position":3,"clout":6}"#.utf8)
        )
        #expect(response.clout == 6)
    }

    @Test func toleratesAnAddResponseWithoutClout() throws {
        // An older backend sends no clout. The add itself still succeeded,
        // so decoding must not fail.
        let response = try decoder.decode(
            ProfileListChangeResponse.self,
            from: Data(#"{"message":"Artist added to list.","position":3}"#.utf8)
        )
        #expect(response.clout == nil)
    }
}
