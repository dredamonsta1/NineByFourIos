import Foundation

struct Conversation: Codable, Identifiable, Sendable {
    let conversationId: Int
    let userOne: Int
    let userTwo: Int
    var updatedAt: String?
    var otherUsername: String?
    var otherUserId: Int?
    var otherProfileImage: String?
    var lastMessage: String?
    var lastMessageAt: String?
    var lastSenderId: Int?
    var unreadCount: Int?

    var id: Int { conversationId }

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case userOne = "user_one"
        case userTwo = "user_two"
        case updatedAt = "updated_at"
        case otherUsername = "other_username"
        case otherUserId = "other_user_id"
        case otherProfileImage = "other_profile_image"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case lastSenderId = "last_sender_id"
        case unreadCount = "unread_count"
    }
}
