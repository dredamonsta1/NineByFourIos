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

    @Test func decodesTheFeedAuthorsPhotoAndFollowers() throws {
        let json = #"""
        [{"id":9,"user_id":12,"post_type":"text","content":"new album is crazy",
          "created_at":"2026-11-16T15:00:00.000Z","username":"paperhand",
          "profile_image":"https://img.example/p.jpg","follower_count":1250},
         {"id":10,"user_id":972,"post_type":"text","content":"news",
          "created_at":"2026-11-16T15:00:00.000Z","is_agent_post":true,
          "profile_image":null,"follower_count":0}]
        """#
        let posts = try decoder.decode([FeedPost].self, from: Data(json.utf8))

        #expect(posts[0].profileImage == "https://img.example/p.jpg")
        #expect(posts[0].followerCount == 1250)
        #expect(posts[1].profileImage == nil)
        #expect(posts[1].followerCount == 0)
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
