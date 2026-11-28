import Foundation
import Testing
@testable import NineByFour

// Story 47: catalog albums play Apple Music's 30s sample. The app must ask
// for Apple only (provider=apple, never a Deezer clip that has no credit
// link), for the right album, and read the listen link it credits.
extension StubServerSuites {
    @MainActor
    @Suite(.serialized)
    struct AppleSampleTests {
        init() {
            URLProtocol.registerClass(StubURLProtocol.self)
            StubURLProtocol.reset()
        }

        private func fetchSample(album: String) async throws -> AppleSampleResponse {
            try await APIClient.shared.request(
                endpoint: .artistSample(artistId: 130474),
                queryItems: AppleSampleResponse.query(album: album)
            )
        }

        @Test func asksForTheAlbumFromAppleOnly() async throws {
            StubURLProtocol.stub("GET", "/artists/130474/preview", body: #"""
            {"provider":"apple","track_name":"Money in My Pocket","album_name":"Words of Wisdom",
             "preview_url":"https://audio-ssl.itunes.apple.com/x.m4a",
             "listen_url":"https://music.apple.com/us/album/x?i=1","album_art_url":null,"cached":true}
            """#)

            let sample = try await fetchSample(album: "Words of Wisdom")

            let url = try #require(StubURLProtocol.requests.last?.url)
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            #expect(items.contains(URLQueryItem(name: "album", value: "Words of Wisdom")))
            #expect(items.contains(URLQueryItem(name: "provider", value: "apple")))

            #expect(sample.previewUrl == "https://audio-ssl.itunes.apple.com/x.m4a")
            #expect(sample.listenUrl == "https://music.apple.com/us/album/x?i=1")
            #expect(sample.trackName == "Money in My Pocket")
        }

        @Test func reportsNoSampleAsA404SoTheButtonCanSaySo() async {
            StubURLProtocol.stub("GET", "/artists/130474/preview", status: 404,
                                 body: #"{"message":"No Apple Music preview for this release."}"#)
            do {
                _ = try await fetchSample(album: "Super Reggae & Soul Hits")
                Issue.record("expected a 404")
            } catch let APIError.httpError(statusCode, _) {
                #expect(statusCode == 404)
            } catch {
                Issue.record("expected httpError(404), got \(error)")
            }
        }

        @Test func needsNoSignIn() {
            #expect(APIEndpoint.artistSample(artistId: 1).requiresAuth == false)
        }
    }
}
