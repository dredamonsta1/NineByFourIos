import Foundation

struct Message: Codable, Identifiable, Sendable {
    let messageId: Int
    let conversationId: Int
    let senderId: Int
    let content: String
    let isRead: Bool
    let createdAt: String
    var senderUsername: String?

    var id: Int { messageId }

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case isRead = "is_read"
        case createdAt = "created_at"
        case senderUsername = "sender_username"
    }
}

struct MessagesResponse: Codable, Sendable {
    let messages: [Message]
    let hasMore: Bool
}

struct UnreadCountResponse: Codable, Sendable {
    let count: Int
}

struct CheckDMResponse: Codable, Sendable {
    let canDM: Bool
    var conversationId: Int?
    var reason: String?
}
