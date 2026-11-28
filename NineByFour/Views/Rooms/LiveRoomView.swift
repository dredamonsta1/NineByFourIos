import SwiftUI
import LiveKit

/// A live room, full screen. Phase 1: listen to and watch the people on
/// stage, chat, raise a hand. Every other person has a menu to report or
/// block them (Guideline 1.2: live content between users needs both).
struct LiveRoomView: View {
    let room: LiveRoom

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(AudioPlayer.self) private var audioPlayer
    @State private var session = LiveRoomSession()
    @State private var chatText = ""
    @State private var reportTarget: RoomPerson?
    @State private var blockTarget: RoomPerson?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()
                content
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Leave") { Task { await leave() } }
                        .foregroundStyle(Color.Theme.error)
                }
                ToolbarItem(placement: .principal) { LiveChip() }
            }
            .toolbarBackground(Color.Theme.bgBase, for: .navigationBar)
        }
        .task {
            // One sound source at a time: a sample or track stops on entry.
            await audioPlayer.stop()
            await session.join(room, myUsername: authManager.currentUser?.username ?? "me")
        }
        .sheet(item: $reportTarget) { person in
            if let userId = person.userId {
                ReportSheet(targetType: "user", targetId: userId, reportedUserId: userId, preview: person.name)
            }
        }
        .confirmationDialog(
            "Block \(blockTarget?.name ?? "")?",
            isPresented: Binding(get: { blockTarget != nil }, set: { if !$0 { blockTarget = nil } }),
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                if let userId = blockTarget?.userId { Task { await session.block(userId: userId) } }
                blockTarget = nil
            }
        } message: {
            Text("You won't see or hear them in rooms, and they're blocked across StanBox.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .idle, .connecting:
            VStack(spacing: 12) {
                ProgressView().tint(Color.Theme.accent)
                Text("Joining \(room.title)…").foregroundStyle(Color.Theme.textSecondary)
            }
        case .failed(let message), .ended(let message?):
            VStack(spacing: 16) {
                Text(message).foregroundStyle(Color.Theme.textPrimary).multilineTextAlignment(.center)
                Button("Back to rooms") { dismiss() }.foregroundStyle(Color.Theme.accentLight)
            }
            .padding(32)
        case .ended(nil):
            Color.clear.onAppear { dismiss() }
        case .connected:
            connected
        }
    }

    private var connected: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if session.invitedToSpeak { speakBanner }
                    section("On stage (\(session.stage.count))") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(session.stage) { person in
                                StageTile(person: person, handUp: session.handsUp.contains(person.id))
                                    .contextMenu { personMenu(person) }
                            }
                        }
                    }
                    if !session.listeners.isEmpty {
                        section("Listening (\(session.listeners.count))") {
                            FlowLayoutRow(people: session.listeners, handsUp: session.handsUp) { person in
                                personMenu(person)
                            }
                        }
                    }
                    section("Chat") { chatList }
                }
                .padding(16)
            }
            controls
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.liveRoom?.title ?? room.title)
                .font(.title3.bold())
                .foregroundStyle(Color.Theme.textPrimary)
            if let description = session.liveRoom?.description, !description.isEmpty {
                Text(description).font(.subheadline).foregroundStyle(Color.Theme.textSecondary)
            }
            if let host = session.liveRoom?.hostUsername ?? room.hostUsername {
                Text("Hosted by \(host)").font(.caption).foregroundStyle(Color.Theme.textSecondary)
            }
        }
    }

    private var speakBanner: some View {
        Text("The host invited you to speak. Speaking from the app is coming soon. Join from onstanbox.com to take the mic.")
            .font(.footnote)
            .foregroundStyle(Color.Theme.textPrimary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Theme.accent.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var chatList: some View {
        VStack(alignment: .leading, spacing: 6) {
            if session.chat.isEmpty {
                Text("No messages yet. Say hi.")
                    .font(.footnote)
                    .foregroundStyle(Color.Theme.textSecondary)
            }
            ForEach(session.chat) { line in
                (Text(line.from).bold().foregroundColor(line.isMe ? Color.Theme.contrast : Color.Theme.accentLight)
                 + Text("  \(line.text)").foregroundColor(Color.Theme.textPrimary))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                Task { await session.toggleHand() }
            } label: {
                Image(systemName: session.myHandUp ? "hand.raised.fill" : "hand.raised")
                    .font(.title3)
                    .foregroundStyle(session.myHandUp ? Color.Theme.contrast : Color.Theme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.Theme.bgCard)
                    .clipShape(Circle())
            }
            .accessibilityLabel(session.myHandUp ? "Lower your hand" : "Raise your hand")

            TextField("Message the room", text: $chatText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.Theme.bgInput)
                .clipShape(Capsule())
                .foregroundStyle(Color.Theme.textPrimary)
                .submitLabel(.send)
                .onSubmit(sendChat)

            Button(action: sendChat) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(Color.Theme.bgBase)
                    .frame(width: 44, height: 44)
                    .background(Color.Theme.contrast)
                    .clipShape(Circle())
            }
            .disabled(chatText.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(12)
        .background(Color.Theme.bgCard)
    }

    @ViewBuilder
    private func personMenu(_ person: RoomPerson) -> some View {
        if !person.isMe, person.userId != nil {
            Button { reportTarget = person } label: { Label("Report \(person.name)", systemImage: "flag") }
            Button(role: .destructive) { blockTarget = person } label: { Label("Block \(person.name)", systemImage: "hand.raised.slash") }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(Color.Theme.textSecondary)
            content()
        }
    }

    private func sendChat() {
        let text = chatText
        chatText = ""
        Task { await session.sendChat(text) }
    }

    private func leave() async {
        await session.leave()
        dismiss()
    }
}

private struct StageTile: View {
    let person: RoomPerson
    let handUp: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let video = person.video {
                SwiftUIVideoView(video, layoutMode: .fill)
            } else {
                Color.Theme.bgCard
                UserAvatar(imagePath: nil, name: person.name, size: 56)
            }
            HStack(spacing: 4) {
                Text(person.name).font(.caption.bold()).lineLimit(1)
                Text(person.role).font(.caption2)
                if handUp { Image(systemName: "hand.raised.fill").font(.caption2) }
            }
            .foregroundStyle(Color.Theme.textBright)
            .padding(6)
            .background(.black.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(6)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(person.isSpeaking ? Color.Theme.contrast : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), \(person.role)\(person.isSpeaking ? ", speaking" : "")")
    }
}

private struct FlowLayoutRow<Menu: View>: View {
    let people: [RoomPerson]
    let handsUp: Set<String>
    @ViewBuilder let menu: (RoomPerson) -> Menu

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
            ForEach(people) { person in
                VStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        UserAvatar(imagePath: nil, name: person.name, size: 44)
                        if handsUp.contains(person.id) {
                            Image(systemName: "hand.raised.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.Theme.contrast)
                        }
                    }
                    Text(person.name)
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .lineLimit(1)
                }
                .contextMenu { menu(person) }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
