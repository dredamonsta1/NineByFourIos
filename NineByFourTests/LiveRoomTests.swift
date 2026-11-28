import Foundation
import Testing
@testable import NineByFour

// Live rooms, Phase 1. iPhone and web users share LiveKit rooms, so the data
// messages must match the web's JSON exactly (src/components/Rooms/Room.jsx).
struct RoomMessageTests {
    private func json(_ message: RoomMessage) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: message.encoded()) as? [String: Any])
    }

    @Test func encodesChatLikeTheWeb() throws {
        let obj = try json(.chat(username: "andrew3", text: "🔥 this set"))
        #expect(obj["type"] as? String == "chat")
        let payload = try #require(obj["payload"] as? [String: Any])
        #expect(payload["username"] as? String == "andrew3")
        #expect(payload["text"] as? String == "🔥 this set")
    }

    @Test func encodesHandsLikeTheWeb() throws {
        #expect(try json(.raiseHand)["type"] as? String == "raise_hand")
        #expect(try json(.lowerHand)["type"] as? String == "lower_hand")
    }

    @Test func decodesWhatTheWebSends() {
        let chat = Data(#"{"type":"chat","payload":{"username":"paperhand","text":"yo"}}"#.utf8)
        #expect(RoomMessage.decode(chat) == .chat(username: "paperhand", text: "yo"))
        #expect(RoomMessage.decode(Data(#"{"type":"raise_hand"}"#.utf8)) == .raiseHand)
        let approved = Data(#"{"type":"hand_approved","payload":{"identity":"12"}}"#.utf8)
        #expect(RoomMessage.decode(approved) == .handApproved(identity: "12"))
    }

    @Test func ignoresJunkEmptyChatAndUnknownTypes() {
        #expect(RoomMessage.decode(Data("not json".utf8)) == nil)
        #expect(RoomMessage.decode(Data(#"{"type":"chat","payload":{"text":"   "}}"#.utf8)) == nil)
        #expect(RoomMessage.decode(Data(#"{"type":"dance"}"#.utf8)) == nil)
    }

    @Test func capsLongChatBothWays() throws {
        let long = String(repeating: "a", count: RoomMessage.maxChatLength + 50)
        let payload = try #require(try json(.chat(username: "x", text: long))["payload"] as? [String: Any])
        #expect((payload["text"] as? String)?.count == RoomMessage.maxChatLength)
        let incoming = Data(#"{"type":"chat","payload":{"username":"x","text":"\#(long)"}}"#.utf8)
        if case .chat(_, let text)? = RoomMessage.decode(incoming) {
            #expect(text.count == RoomMessage.maxChatLength)
        } else {
            Issue.record("expected chat")
        }
    }
}

struct RoomParticipantMetaTests {
    @Test func readsTheBackendsTokenMetadata() {
        let meta = RoomParticipantMeta.parse(#"{"role":"host","userId":12,"username":"andrew3"}"#)
        #expect(meta.role == "host")
        #expect(meta.userId == 12)
        #expect(meta.username == "andrew3")
        #expect(meta.isOnStage)
    }

    @Test func treatsMissingOrBrokenMetadataAsAListener() {
        #expect(RoomParticipantMeta.parse(nil).role == "listener")
        #expect(RoomParticipantMeta.parse("{oops").isOnStage == false)
    }
}

struct LiveRoomModelTests {
    @Test func decodesTheRoomsList() throws {
        let json = #"""
        [{"room_id":8,"host_id":1,"title":"Friday listening party","description":null,
          "livekit_room_name":"room_1_1764","status":"live","created_at":"2026-11-27T20:00:00.000Z",
          "host_username":"andrew3","participant_count":4}]
        """#
        let rooms = try JSONDecoder().decode([LiveRoom].self, from: Data(json.utf8))
        #expect(rooms.first?.roomId == 8)
        #expect(rooms.first?.hostUsername == "andrew3")
        #expect(rooms.first?.participantCount == 4)
    }

    @Test func decodesTheJoinToken() throws {
        let json = #"""
        {"token":"eyJ.x.y","role":"listener","livekit_url":"wss://stanbox.livekit.cloud",
         "room":{"room_id":8,"title":"Friday listening party","status":"live"}}
        """#
        let join = try JSONDecoder().decode(RoomJoinResponse.self, from: Data(json.utf8))
        #expect(join.role == "listener")
        #expect(join.livekitUrl == "wss://stanbox.livekit.cloud")
    }

    @Test func endpointsMatchTheBackend() {
        #expect(APIEndpoint.liveRooms.path == "/rooms")
        #expect(APIEndpoint.roomToken(roomId: 8).path == "/rooms/8/token")
        #expect(APIEndpoint.roomToken(roomId: 8).method == .POST)
        #expect(APIEndpoint.liveRooms.requiresAuth)
    }
}

// The session's message handling, without connecting to LiveKit.
extension StubServerSuites {
    @MainActor
    @Suite(.serialized)
    struct LiveRoomSessionTests {
        init() {
            URLProtocol.registerClass(StubURLProtocol.self)
            StubURLProtocol.reset()
            // Blocking is a signed-in request; without a token it never leaves.
            KeychainHelper.shared.saveToken("test-token")
        }

        @Test func showsChatAndTracksRaisedHands() {
            let session = LiveRoomSession()
            session.received(RoomMessage.chat(username: "paperhand", text: "yo").encoded(), fromIdentity: "5")
            session.received(RoomMessage.raiseHand.encoded(), fromIdentity: "5")

            #expect(session.chat.map(\.text) == ["yo"])
            #expect(session.handsUp.contains("5"))

            session.received(RoomMessage.lowerHand.encoded(), fromIdentity: "5")
            #expect(!session.handsUp.contains("5"))
        }

        @Test func dropsEverythingFromSomeoneYouBlock() async {
            StubURLProtocol.stub("POST", "/moderation/block/5", status: 201)
            let session = LiveRoomSession()
            await session.block(userId: 5)

            session.received(RoomMessage.chat(username: "troll", text: "spam").encoded(), fromIdentity: "5")
            session.received(RoomMessage.raiseHand.encoded(), fromIdentity: "5")

            #expect(session.chat.isEmpty)
            #expect(session.handsUp.isEmpty)
            #expect(StubURLProtocol.calls.contains("POST /moderation/block/5"))
        }
    }
}
