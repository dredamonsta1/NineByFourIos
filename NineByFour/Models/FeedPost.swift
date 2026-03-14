import Foundation

enum PostType: String, Codable, Sendable {
    case text
    case image
    case video
    case music
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

    // Music post fields
    var musicTitle: String?
    var audioUrl: String?
    var streamUrl: String?
    var platform: String?

    // Agent post fields
    var isAgentPost: Bool?
    var provenanceUrls: [String]?
    var agentId: Int?
    var verifiedCount: Int?
    var disputedCount: Int?

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
        case musicTitle = "music_title"
        case audioUrl = "audio_url"
        case streamUrl = "stream_url"
        case platform
        case isAgentPost = "is_agent_post"
        case provenanceUrls = "provenance_urls"
        case agentId = "agent_id"
        case verifiedCount = "verified_count"
        case disputedCount = "disputed_count"
    }
}
