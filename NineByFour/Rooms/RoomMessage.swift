import Foundation

/// The data messages a room's participants send each other. Same JSON as the
/// web room (src/components/Rooms/Room.jsx, `MSG`), so iPhone and browser
/// users chat and raise hands in the same room:
///
///     {"type":"chat","payload":{"username":"andrew3","text":"🔥"}}
///     {"type":"raise_hand"}   {"type":"lower_hand"}
///     {"type":"hand_approved","payload":{"identity":"12"}}
enum RoomMessage: Equatable, Sendable {
    case chat(username: String, text: String)
    case raiseHand
    case lowerHand
    case handApproved(identity: String)
    case handDenied(identity: String)

    private struct Wire: Codable {
        let type: String
        var payload: Payload?
    }

    private struct Payload: Codable {
        var username: String?
        var text: String?
        var identity: String?
    }

    /// The longest chat message we'll send or show. Keeps one participant
    /// from flooding everyone's screen.
    static let maxChatLength = 500

    func encoded() -> Data {
        let wire: Wire
        switch self {
        case .chat(let username, let text):
            wire = Wire(type: "chat", payload: Payload(username: username, text: String(text.prefix(Self.maxChatLength))))
        case .raiseHand:
            wire = Wire(type: "raise_hand")
        case .lowerHand:
            wire = Wire(type: "lower_hand")
        case .handApproved(let identity):
            wire = Wire(type: "hand_approved", payload: Payload(identity: identity))
        case .handDenied(let identity):
            wire = Wire(type: "hand_denied", payload: Payload(identity: identity))
        }
        return (try? JSONEncoder().encode(wire)) ?? Data()
    }

    /// nil for anything malformed or unknown; the web ignores those too.
    static func decode(_ data: Data) -> RoomMessage? {
        guard let wire = try? JSONDecoder().decode(Wire.self, from: data) else { return nil }
        switch wire.type {
        case "chat":
            guard let text = wire.payload?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return nil }
            return .chat(username: wire.payload?.username ?? "someone",
                         text: String(text.prefix(maxChatLength)))
        case "raise_hand": return .raiseHand
        case "lower_hand": return .lowerHand
        case "hand_approved": return wire.payload?.identity.map { .handApproved(identity: $0) }
        case "hand_denied": return wire.payload?.identity.map { .handDenied(identity: $0) }
        default: return nil
        }
    }
}

/// A participant's role, from the JSON metadata the backend puts in their
/// LiveKit token: {"role":"host"|"speaker"|"listener", "userId":12, "username":"…"}.
struct RoomParticipantMeta: Equatable, Sendable {
    let role: String
    let userId: Int?
    let username: String?

    var isOnStage: Bool { role == "host" || role == "speaker" }

    static func parse(_ metadata: String?) -> RoomParticipantMeta {
        guard let data = metadata?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return RoomParticipantMeta(role: "listener", userId: nil, username: nil)
        }
        let userId = (json["userId"] as? Int) ?? (json["userId"] as? String).flatMap(Int.init)
        return RoomParticipantMeta(role: json["role"] as? String ?? "listener",
                                   userId: userId,
                                   username: json["username"] as? String)
    }
}
