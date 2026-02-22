import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let imageUrl = conversation.otherProfileImage, !imageUrl.isEmpty {
                CachedAsyncImage(url: imageUrl.fullImageURL, cornerRadius: 22)
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.Theme.textSecondary)
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUsername ?? "Unknown")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.Theme.textPrimary)

                    Spacer()

                    if let lastAt = conversation.lastMessageAt {
                        Text(lastAt.toDate()?.relativeString() ?? "")
                            .font(.caption2)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                }

                HStack {
                    Text(conversation.lastMessage ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    if let unread = conversation.unreadCount, unread > 0 {
                        Text("\(unread)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.Theme.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.Theme.bgCard)
        .cornerRadius(10)
    }
}
