import Foundation
import LiveKit
import Observation

/// One person in a room, as the screen shows them.
struct RoomPerson: Identifiable {
    let id: String            // LiveKit identity = StanBox user id, as a string
    let userId: Int?
    let name: String
    let role: String
    let isSpeaking: Bool
    let video: VideoTrack?
    let isMe: Bool

    var isOnStage: Bool { role == "host" || role == "speaker" }
}

struct RoomChatLine: Identifiable, Equatable {
    let id = UUID()
    let from: String
    let text: String
    let isMe: Bool
}

/// A joined live room (Phase 1: listen, watch, chat, raise a hand). Wraps a
/// LiveKit `Room` and turns its callbacks into plain state for SwiftUI.
///
/// Interoperates with the web room: same LiveKit room, same data-message
/// JSON (RoomMessage). Listeners can't publish audio or video (the backend's
/// token says so); they can send chat and raised hands.
///
/// Blocked users (GET /moderation/blocks, plus anyone blocked from inside the
/// room) are left out of the stage, the listener list and the chat.
@MainActor
@Observable
final class LiveRoomSession {
    enum Phase: Equatable {
        case idle, connecting, connected, ended(String?), failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var liveRoom: LiveRoom?
    private(set) var stage: [RoomPerson] = []
    private(set) var listeners: [RoomPerson] = []
    private(set) var chat: [RoomChatLine] = []
    private(set) var handsUp: Set<String> = []
    private(set) var myHandUp = false
    /// The host promoted us. Speaking from the phone comes in Phase 2.
    private(set) var invitedToSpeak = false
    private(set) var blockedUserIds: Set<Int> = []

    private let room = Room()
    private var myUsername = ""
    private var delegateBridge: RoomDelegateBridge?

    func join(_ target: LiveRoom, myUsername: String) async {
        guard phase == .idle || phase.isOver else { return }
        phase = .connecting
        liveRoom = target
        self.myUsername = myUsername
        chat = []
        handsUp = []
        myHandUp = false
        invitedToSpeak = false

        await loadBlockedUsers()

        do {
            let join: RoomJoinResponse = try await APIClient.shared.request(
                endpoint: .roomToken(roomId: target.roomId)
            )
            liveRoom = join.room
            let bridge = RoomDelegateBridge(session: self)
            delegateBridge = bridge
            room.add(delegate: bridge)
            try await room.connect(url: join.livekitUrl, token: join.token)
            phase = .connected
            refresh()
        } catch let APIError.httpError(statusCode, _) where statusCode == 410 {
            phase = .ended("This room has ended.")
        } catch {
            phase = .failed("Couldn't join the room. Check your connection and try again.")
        }
    }

    func leave() async {
        if myHandUp { await send(.lowerHand) }
        await room.disconnect()
        if let bridge = delegateBridge { room.remove(delegate: bridge) }
        delegateBridge = nil
        phase = .ended(nil)
    }

    func sendChat(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, phase == .connected else { return }
        let capped = String(trimmed.prefix(RoomMessage.maxChatLength))
        chat.append(RoomChatLine(from: myUsername, text: capped, isMe: true))
        await send(.chat(username: myUsername, text: capped))
    }

    func toggleHand() async {
        guard phase == .connected else { return }
        myHandUp.toggle()
        await send(myHandUp ? .raiseHand : .lowerHand)
    }

    /// Block from inside the room: hidden here at once, and blocked across
    /// StanBox (feed, messages, profile) through the usual endpoint.
    func block(userId: Int) async {
        blockedUserIds.insert(userId)
        refresh()
        try? await APIClient.shared.requestVoid(endpoint: .blockUser(userId: userId))
    }

    // MARK: - Callbacks (from RoomDelegateBridge, on the main actor)

    func refresh() {
        var people: [RoomPerson] = []
        let local = room.localParticipant
        let localMeta = RoomParticipantMeta.parse(local.metadata)
        if localMeta.role == "speaker" { invitedToSpeak = true }
        people.append(person(local, meta: localMeta, isMe: true))

        for participant in room.remoteParticipants.values {
            let meta = RoomParticipantMeta.parse(participant.metadata)
            let userId = meta.userId ?? participant.identity.flatMap { Int($0.stringValue) }
            if let userId, blockedUserIds.contains(userId) { continue }
            people.append(person(participant, meta: meta, isMe: false))
        }

        // Host first, then speakers, then by name, so tiles don't reshuffle.
        let order: (RoomPerson, RoomPerson) -> Bool = {
            if ($0.role == "host") != ($1.role == "host") { return $0.role == "host" }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        stage = people.filter(\.isOnStage).sorted(by: order)
        listeners = people.filter { !$0.isOnStage }.sorted(by: order)
        handsUp = handsUp.filter { id in people.contains { $0.id == id } }
    }

    func received(_ data: Data, fromIdentity identity: String?) {
        guard let message = RoomMessage.decode(data) else { return }
        if let identity, let userId = Int(identity), blockedUserIds.contains(userId) { return }
        switch message {
        case .chat(let username, let text):
            chat.append(RoomChatLine(from: username, text: text, isMe: false))
            if chat.count > 200 { chat.removeFirst(chat.count - 200) }
        case .raiseHand:
            if let identity { handsUp.insert(identity) }
        case .lowerHand:
            if let identity { handsUp.remove(identity) }
        case .handApproved(let target):
            if target == room.localParticipant.identity?.stringValue {
                myHandUp = false
                invitedToSpeak = true
            }
            handsUp.remove(target)
        case .handDenied(let target):
            if target == room.localParticipant.identity?.stringValue { myHandUp = false }
            handsUp.remove(target)
        }
    }

    func disconnected(_ reason: String?) {
        if phase == .connected { phase = .ended(reason ?? "The room has ended.") }
    }

    // MARK: - Private

    private func person(_ participant: Participant, meta: RoomParticipantMeta, isMe: Bool) -> RoomPerson {
        let identity = participant.identity?.stringValue ?? UUID().uuidString
        let name = participant.name?.nilIfEmpty ?? meta.username ?? "Guest"
        return RoomPerson(
            id: identity,
            userId: meta.userId ?? Int(identity),
            name: isMe ? "\(name) (you)" : name,
            role: meta.role,
            isSpeaking: participant.isSpeaking,
            video: participant.firstCameraVideoTrack,
            isMe: isMe
        )
    }

    private func send(_ message: RoomMessage) async {
        try? await room.localParticipant.publish(
            data: message.encoded(),
            options: DataPublishOptions(reliable: true)
        )
    }

    private func loadBlockedUsers() async {
        if let response: BlockedUsersResponse = try? await APIClient.shared.request(endpoint: .blockedUsers) {
            blockedUserIds = Set(response.blocks.map(\.userId))
        }
    }
}

private extension LiveRoomSession.Phase {
    var isOver: Bool {
        switch self {
        case .ended, .failed: return true
        default: return false
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// LiveKit calls its delegates off the main thread. This forwards the events
/// the screen cares about to the session on the main actor.
final class RoomDelegateBridge: NSObject, RoomDelegate, @unchecked Sendable {
    private weak var session: LiveRoomSession?

    init(session: LiveRoomSession) { self.session = session }

    private func refresh() {
        Task { @MainActor [weak session] in session?.refresh() }
    }

    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) { refresh() }
    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) { refresh() }
    nonisolated func room(_ room: Room, participant: Participant, didUpdateMetadata metadata: String?) { refresh() }
    nonisolated func room(_ room: Room, participant: Participant, didUpdateName name: String) { refresh() }
    nonisolated func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) { refresh() }
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) { refresh() }
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) { refresh() }
    nonisolated func room(_ room: Room, participant: Participant, trackPublication: TrackPublication, didUpdateIsMuted isMuted: Bool) { refresh() }

    nonisolated func room(_ room: Room, participant: RemoteParticipant?, didReceiveData data: Data, forTopic topic: String, encryptionType: EncryptionType) {
        let identity = participant?.identity?.stringValue
        Task { @MainActor [weak session] in session?.received(data, fromIdentity: identity) }
    }

    nonisolated func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        Task { @MainActor [weak session] in session?.disconnected(nil) }
    }
}
