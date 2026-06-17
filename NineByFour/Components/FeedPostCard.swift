import SwiftUI

struct FeedPostCard: View {
    let post: FeedPost
    let currentUserId: Int?
    var onTapUsername: ((Int) -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: post.isAgentPost == true ? "cpu.fill" : "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(post.isAgentPost == true ? Color.Theme.textSecondary : Color.Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Button {
                        onTapUsername?(post.userId)
                    } label: {
                        Text(post.username ?? "Unknown")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.Theme.accent)
                    }

                    Text(post.createdAt.toDate()?.relativeString() ?? "")
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.textSecondary)
                }

                Spacer()

                if post.isAgentPost == true {
                    Text("Agent")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.Theme.borderDefault)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .clipShape(Capsule())
                }

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

            case .music:
                MusicPostContent(post: post)
            }

            // Verdict badges
            let verifiedCount = post.verifiedCount ?? 0
            let disputedCount = post.disputedCount ?? 0
            if verifiedCount > 0 || disputedCount > 0 {
                HStack(spacing: 8) {
                    if verifiedCount > 0 {
                        Label("\(verifiedCount) Verified", systemImage: "checkmark.seal.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                    if disputedCount > 0 {
                        Label("\(disputedCount) Disputed", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Provenance links for agent posts
            if post.isAgentPost == true, let urls = post.provenanceUrls, !urls.isEmpty {
                HStack(spacing: 6) {
                    Text("Sources:")
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.textSecondary)
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                        if let link = URL(string: url) {
                            Link("[\(index + 1)]", destination: link)
                                .font(.caption2)
                                .foregroundStyle(Color.Theme.accent)
                        }
                    }
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

// MARK: - Music Post Content

private struct MusicPostContent: View {
    let post: FeedPost
    @Environment(AudioPlayer.self) private var audioPlayer

    private var isActive: Bool {
        audioPlayer.currentPost?.id == post.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = post.musicTitle, !title.isEmpty {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.textPrimary)
            }

            // Prefer in-app playback when audioUrl is present (raw playable
            // file hosted on Cloudinary etc). Fall back to the platform deep
            // link via streamUrl for posts that only reference Spotify /
            // SoundCloud / Apple Music.
            if let audioUrl = post.audioUrl, !audioUrl.isEmpty {
                Button {
                    if isActive {
                        audioPlayer.togglePlayPause()
                    } else {
                        Task { await audioPlayer.play(post: post) }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isActive && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title3)
                        Text(isActive
                             ? (audioPlayer.isPlaying ? "Playing…" : "Paused")
                             : "Play")
                            .font(.subheadline.bold())
                        Spacer()
                        if isActive && audioPlayer.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.Theme.accent)
                        }
                    }
                    .padding(12)
                    .background(Color.Theme.bgInput)
                    .foregroundStyle(Color.Theme.accent)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.Theme.borderDefault, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else if let streamUrl = post.streamUrl, let url = URL(string: streamUrl) {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Image(systemName: platformIcon(for: post.platform))
                            .font(.title3)
                        Text("Listen on \(platformName(for: post.platform))")
                            .font(.subheadline.bold())
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .padding(12)
                    .background(Color.Theme.bgInput)
                    .foregroundStyle(Color.Theme.accent)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.Theme.borderDefault, lineWidth: 1)
                    )
                }
            }

            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.textPrimary)
            }
        }
    }

    private func platformName(for platform: String?) -> String {
        switch platform?.lowercased() {
        case "spotify": return "Spotify"
        case "soundcloud": return "SoundCloud"
        case "apple": return "Apple Music"
        default: return "streaming"
        }
    }

    private func platformIcon(for platform: String?) -> String {
        switch platform?.lowercased() {
        case "spotify": return "music.note"
        case "soundcloud": return "waveform"
        case "apple": return "music.note.list"
        default: return "music.note"
        }
    }
}
