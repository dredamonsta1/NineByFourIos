import Foundation

enum PostType: String, Codable, Sendable {
    case text
    case image
    case video
}

struct FeedPost: Codable, Identifiable, Sendable {
    let id: Int
    let userId: Int
    var content: String?
    var imageUrl: String?
    var caption: String?
    var videoUrl: String?
    var videoType: String?
    let postType: PostType
    let createdAt: String
    var username: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case imageUrl = "image_url"
        case caption
        case videoUrl = "video_url"
        case videoType = "video_type"
        case postType = "post_type"
        case createdAt = "created_at"
        case username
    }
}
