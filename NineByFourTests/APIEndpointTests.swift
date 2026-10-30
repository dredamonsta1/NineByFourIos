import Testing
@testable import NineByFour

// Paths and methods for the endpoints that change data. A wrong method here
// is a 404 at runtime that nothing else would catch.
@MainActor
struct APIEndpointTests {
    @Test(arguments: [
        (APIEndpoint.addToProfileList(artistId: 85), "/profile/list/85", HTTPMethod.POST),
        (APIEndpoint.removeFromProfileList(artistId: 85), "/profile/list/85", HTTPMethod.DELETE),
        (APIEndpoint.profileList, "/profile/list", HTTPMethod.GET),
        (APIEndpoint.artist(id: 85), "/artists/85", HTTPMethod.GET),
        (APIEndpoint.reportContent, "/moderation/report", HTTPMethod.POST),
        (APIEndpoint.blockUser(userId: 7), "/moderation/block/7", HTTPMethod.POST),
        (APIEndpoint.unblockUser(userId: 7), "/moderation/block/7", HTTPMethod.DELETE),
    ])
    func mapsToTheRightRoute(endpoint: APIEndpoint, path: String, method: HTTPMethod) {
        #expect(endpoint.path == path)
        #expect(endpoint.method == method)
    }
}
