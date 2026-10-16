import Foundation

struct UpcomingRelease: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    var artist: String?
    var date: String?
    var imageUrl: String?
    var source: String?

    // /music/upcoming sends `image_url`. Without this mapping the decoder
    // looked for `imageUrl`, found nothing, and every card showed the
    // placeholder even though all of them had artwork.
    enum CodingKeys: String, CodingKey {
        case id, title, artist, date, source
        case imageUrl = "image_url"
    }
}
