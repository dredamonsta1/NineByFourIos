import SwiftUI

/// A video in Discover → Videos. Tap to watch.
struct VideoCard: View {
    let video: PlatformVideo
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Color.black
                    CachedAsyncImage(url: video.posterURL, cornerRadius: 12)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(video.displayTitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.Theme.textPrimary)
                            .lineLimit(2)
                        if video.isMusicVideo {
                            Text("Music video")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.Theme.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(Capsule().stroke(Color.Theme.borderDefault, lineWidth: 1))
                        }
                    }

                    HStack {
                        if let username = video.username, !username.isEmpty {
                            Text("@\(username)")
                                .font(.caption)
                                .foregroundStyle(Color.Theme.accent)
                        }
                        Spacer()
                        Text(video.createdAt.toDate()?.relativeString() ?? "")
                            .font(.caption2)
                            .foregroundStyle(Color.Theme.textSecondary)
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
        .accessibilityLabel("Play \(video.displayTitle)\(video.username.map { " by \($0)" } ?? "")")
    }
}
