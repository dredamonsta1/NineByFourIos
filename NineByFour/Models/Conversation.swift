import Foundation

struct Conversation: Codable, Identifiable, Hashable, Sendable {
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

    init(
        conversationId: Int,
        userOne: Int,
        userTwo: Int,
        updatedAt: String? = nil,
        otherUsername: String? = nil,
        otherUserId: Int? = nil,
        otherProfileImage: String? = nil,
        lastMessage: String? = nil,
        lastMessageAt: String? = nil,
        lastSenderId: Int? = nil,
        unreadCount: Int? = nil
    ) {
        self.conversationId = conversationId
        self.userOne = userOne
        self.userTwo = userTwo
        self.updatedAt = updatedAt
        self.otherUsername = otherUsername
        self.otherUserId = otherUserId
        self.otherProfileImage = otherProfileImage
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.lastSenderId = lastSenderId
        self.unreadCount = unreadCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conversationId = try container.decode(Int.self, forKey: .conversationId)
        userOne = try container.decode(Int.self, forKey: .userOne)
        userTwo = try container.decode(Int.self, forKey: .userTwo)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        otherUsername = try container.decodeIfPresent(String.self, forKey: .otherUsername)
        otherUserId = try container.decodeIfPresent(Int.self, forKey: .otherUserId)
        otherProfileImage = try container.decodeIfPresent(String.self, forKey: .otherProfileImage)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        lastMessageAt = try container.decodeIfPresent(String.self, forKey: .lastMessageAt)
        lastSenderId = try container.decodeIfPresent(Int.self, forKey: .lastSenderId)

        // PostgreSQL COUNT(*) returns bigint which node-pg serializes as a string
        if let intVal = try? container.decodeIfPresent(Int.self, forKey: .unreadCount) {
            unreadCount = intVal
        } else if let strVal = try? container.decodeIfPresent(String.self, forKey: .unreadCount) {
            unreadCount = Int(strVal)
        } else {
            unreadCount = nil
        }
    }
}
