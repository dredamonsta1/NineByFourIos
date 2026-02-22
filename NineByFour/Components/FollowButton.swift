import SwiftUI

struct FollowButton: View {
    var userId: Int
    @Binding var isFollowing: Bool
    @State private var isLoading = false

    var body: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .tint(isFollowing ? .white : Color.Theme.accent)
                        .scaleEffect(0.7)
                }
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption.bold())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isFollowing ? Color.Theme.accent : Color.clear)
            .foregroundStyle(isFollowing ? .white : Color.Theme.accent)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.Theme.accent, lineWidth: isFollowing ? 0 : 1)
            )
        }
        .disabled(isLoading)
    }

    @MainActor
    private func toggleFollow() async {
        isLoading = true
        do {
            if isFollowing {
                try await APIClient.shared.requestVoid(endpoint: .unfollow(userId: userId))
                isFollowing = false
            } else {
                try await APIClient.shared.requestVoid(endpoint: .follow(userId: userId))
                isFollowing = true
            }
        } catch {
            // Silently fail
        }
        isLoading = false
    }
}
