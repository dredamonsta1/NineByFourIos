import SwiftUI

struct VideoCard: View {
    let video: DiscoverVideo
    var onTap: () -> Void

    private var thumbnailURL: URL? {
        if let thumb = video.thumbnailUrl, !thumb.isEmpty {
            return URL(string: thumb)
        }
        return URL(string: "https://img.youtube.com/vi/\(video.youtubeId)/hqdefault.jpg")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    CachedAsyncImage(url: thumbnailURL, cornerRadius: 12)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.85))
                }

                VStack(alignment: .leading, spacing: 4) {
                    if !video.title.isEmpty {
                        Text(video.title)
                            .font(.subheadline)
                            .foregroundStyle(Color.Theme.textPrimary)
                            .lineLimit(2)
                    }

                    HStack {
                        if let username = video.username, !username.isEmpty {
                            Text(username)
                                .font(.caption)
                                .foregroundStyle(Color.Theme.accent)
                        }
                        Spacer()
                        if let date = video.createdAt {
                            Text(date.toDate()?.relativeString() ?? "")
                                .font(.caption2)
                                .foregroundStyle(Color.Theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(Color.Theme.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
