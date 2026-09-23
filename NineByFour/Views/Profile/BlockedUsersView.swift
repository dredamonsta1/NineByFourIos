import SwiftUI

/// The list of people the user has blocked, and the only way to undo a block.
///
/// Blocking without a way to unblock is a trap: it is reached for in a moment
/// of frustration and is otherwise permanent, with no record of who was
/// blocked or when. App Store Guideline 1.2 asks for the ability to block;
/// leaving it one-way is a bad product regardless of what the rule requires.
struct BlockedUser: Codable, Identifiable {
    let userId: Int
    let username: String?
    let profileImage: String?
    let createdAt: String?

    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case profileImage = "profile_image"
        case createdAt = "created_at"
    }
}

private struct BlockedUsersResponse: Codable {
    let blocks: [BlockedUser]
}

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var blocks: [BlockedUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var unblocking: Set<Int> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(Color.Theme.accent)
                } else if let errorMessage {
                    VStack(spacing: 10) {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.Theme.error)
                        Button("Try again") { Task { await load() } }
                            .font(.footnote)
                            .foregroundStyle(Color.Theme.accent)
                    }
                } else if blocks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.raised.slash")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text("You haven't blocked anyone")
                            .font(.subheadline)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(blocks) { blocked in
                                row(blocked)
                                Divider().overlay(Color.Theme.borderDefault)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle("Blocked")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
        }
        .task { await load() }
    }

    @ViewBuilder
    private func row(_ blocked: BlockedUser) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.Theme.textSecondary)

            Text(blocked.username ?? "Unknown")
                .font(.subheadline)
                .foregroundStyle(Color.Theme.textPrimary)

            Spacer()

            Button {
                Task { await unblock(blocked.userId) }
            } label: {
                Text(unblocking.contains(blocked.userId) ? "…" : "Unblock")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.Theme.accent)
            }
            .disabled(unblocking.contains(blocked.userId))
        }
        .padding(.vertical, 12)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: BlockedUsersResponse = try await APIClient.shared.request(
                endpoint: .blockedUsers
            )
            blocks = response.blocks
        } catch {
            errorMessage = "Couldn't load your blocked list."
        }
        isLoading = false
    }

    private func unblock(_ userId: Int) async {
        unblocking.insert(userId)
        do {
            try await APIClient.shared.requestVoid(endpoint: .unblockUser(userId: userId))
            // Removed locally rather than refetching. Unblocking does not
            // restore the severed follows, so there is nothing else to resync.
            blocks.removeAll { $0.userId == userId }
        } catch {
            errorMessage = "Couldn't unblock that person. Try again."
        }
        unblocking.remove(userId)
    }
}
