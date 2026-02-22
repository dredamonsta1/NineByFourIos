import Foundation

struct ImagePost: Codable, Identifiable, Sendable {
    let postId: Int
    let imageUrl: String
    var caption: String?
    let userId: Int
    let createdAt: String
    var username: String?

    var id: Int { postId }

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case imageUrl = "image_url"
        case caption
        case userId = "user_id"
        case createdAt = "created_at"
        case username
    }
}
