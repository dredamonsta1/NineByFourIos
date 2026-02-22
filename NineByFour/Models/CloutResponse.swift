import Foundation

struct CloutResponse: Codable, Sendable {
    let message: String
    let artistId: String
    let newCloutCount: Int

    enum CodingKeys: String, CodingKey {
        case message
        case artistId = "artist_id"
        case newCloutCount = "new_clout_count"
    }
}
