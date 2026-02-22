import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    let currentUserId: Int?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username ?? "Unknown")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.Theme.textPrimary)

                    Text(post.createdAt.toDate()?.relativeString() ?? "")
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.textSecondary)
                }

                Spacer()

                if post.userId == currentUserId {
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(Color.Theme.error)
                    }
                }
            }

            // Content based on type
            switch post.postType {
            case .text:
                if let content = post.content, !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .foregroundStyle(Color.Theme.textPrimary)
                }

            case .image:
                if let imageUrl = post.imageUrl {
                    CachedAsyncImage(url: imageUrl.fullImageURL, cornerRadius: 10)
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                }
                if let caption = post.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(Color.Theme.textPrimary)
                }

            case .video:
                if let videoUrl = post.videoUrl, let videoId = extractYouTubeId(from: videoUrl) {
                    YouTubePlayerView(videoId: videoId)
                        .frame(height: 200)
                        .cornerRadius(10)
                }
                if let caption = post.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(Color.Theme.textPrimary)
                }
            }
        }
        .padding(14)
        .background(Color.Theme.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.Theme.borderDefault, lineWidth: 1)
        )
    }

    private func extractYouTubeId(from url: String) -> String? {
        if let components = URLComponents(string: url),
           let queryItem = components.queryItems?.first(where: { $0.name == "v" }) {
            return queryItem.value
        }
        if url.contains("youtu.be/") {
            return url.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }
        return nil
    }
}
