import Foundation

/// A live room from GET /api/rooms (web: src/components/Rooms). Hosted on
/// LiveKit; the backend only tracks which rooms are live and hands out
/// join tokens.
struct LiveRoom: Decodable, Identifiable, Sendable, Hashable {
    let roomId: Int
    let title: String
    let description: String?
    let hostId: Int?
    let hostUsername: String?
    let participantCount: Int?
    let status: String?
    let createdAt: String?

    var id: Int { roomId }

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case title, description, status
        case hostId = "host_id"
        case hostUsername = "host_username"
        case participantCount = "participant_count"
        case createdAt = "created_at"
    }
}

/// POST /api/rooms/:id/token. Everyone but the host joins as a listener:
/// subscribe only, plus data messages (chat, raised hands).
struct RoomJoinResponse: Decodable, Sendable {
    let token: String
    let role: String
    let livekitUrl: String
    let room: LiveRoom

    enum CodingKeys: String, CodingKey {
        case token, role, room
        case livekitUrl = "livekit_url"
    }
}
