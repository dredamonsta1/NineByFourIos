import SwiftUI

/// Live rooms, from the 🎙 button in the Feed (web: /rooms). Phase 1 joins
/// rooms to listen, watch, chat and raise a hand; starting a room comes in
/// Phase 2, so for now that's pointed at the website.
struct RoomsListView: View {
    @State private var rooms: [LiveRoom] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var openRoom: LiveRoom?

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()

            if isLoading && rooms.isEmpty {
                ProgressView().tint(Color.Theme.accent)
            } else if let errorMessage, rooms.isEmpty {
                ErrorStateView(message: errorMessage) { Task { await load() } }
            } else if rooms.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(rooms) { room in
                            Button { openRoom = room } label: { RoomRow(room: room) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .refreshable { await load() }
            }
        }
        .navigationTitle("Live rooms")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .fullScreenCover(item: $openRoom, onDismiss: { Task { await load() } }) { room in
            LiveRoomView(room: room)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .font(.system(size: 36))
                .foregroundStyle(Color.Theme.textSecondary)
            Text("No one's live right now")
                .font(.headline)
                .foregroundStyle(Color.Theme.textPrimary)
            Text("Pull down to check again. Hosting a room from the app is coming soon. For now, go live from onstanbox.com.")
                .font(.footnote)
                .foregroundStyle(Color.Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            rooms = try await APIClient.shared.request(endpoint: .liveRooms)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load live rooms."
        }
    }
}

private struct RoomRow: View {
    let room: LiveRoom

    var body: some View {
        HStack(spacing: 12) {
            LiveChip()
            VStack(alignment: .leading, spacing: 4) {
                Text(room.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.textPrimary)
                    .lineLimit(2)
                if let host = room.hostUsername {
                    Text("Hosted by \(host)")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
            Spacer()
            Label("\(room.participantCount ?? 0)", systemImage: "person.2.fill")
                .font(.caption)
                .foregroundStyle(Color.Theme.textSecondary)
                .accessibilityLabel("\(room.participantCount ?? 0) in the room")
        }
        .padding(14)
        .background(Color.Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

struct LiveChip: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(Color.Theme.error).frame(width: 6, height: 6)
            Text("LIVE").font(.caption2.bold())
        }
        .foregroundStyle(Color.Theme.textBright)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.Theme.error.opacity(0.25))
        .clipShape(Capsule())
    }
}
