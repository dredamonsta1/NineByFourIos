import Foundation

struct VideoPost: Codable, Identifiable, Sendable {
    let id: Int
    var userId: Int?
    let videoUrl: String
    let videoType: String
    var caption: String?
    var thumbnailUrl: String?
    let createdAt: String
    var username: String?
    var source: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case videoUrl = "video_url"
        case videoType = "video_type"
        case caption
        case thumbnailUrl = "thumbnail_url"
        case createdAt = "created_at"
        case username
        case source
    }
}

/// Response model for /art/music-videos and /art/youtube-feed
struct YouTubeVideo: Codable, Sendable {
    let videoId: String
    let title: String
    var thumbnail: String?
    var artist: String?
    var publishedAt: String?
    var channelTitle: String?
}

/// Unified display model for the Discover tab video list
struct DiscoverVideo: Identifiable, Sendable {
    let id: String
    let youtubeId: String
    let title: String
    var thumbnailUrl: String?
    var username: String?
    var createdAt: String?
    var source: String

    /// Create from a YouTube API response
    static func fromYouTube(_ yt: YouTubeVideo, source: String) -> DiscoverVideo {
        DiscoverVideo(
            id: "\(source)-\(yt.videoId)",
            youtubeId: yt.videoId,
            title: yt.title,
            thumbnailUrl: yt.thumbnail,
            username: yt.artist ?? yt.channelTitle,
            createdAt: yt.publishedAt,
            source: source
        )
    }

    /// Create from a VideoPost (combined-video-feed)
    static func fromVideoPost(_ vp: VideoPost) -> DiscoverVideo {
        let ytId = extractYouTubeId(from: vp.videoUrl) ?? vp.videoUrl
        return DiscoverVideo(
            id: "combined-\(vp.id)",
            youtubeId: ytId,
            title: vp.caption ?? "",
            thumbnailUrl: vp.thumbnailUrl ?? "https://img.youtube.com/vi/\(ytId)/hqdefault.jpg",
            username: vp.username,
            createdAt: vp.createdAt,
            source: vp.source ?? "combined"
        )
    }

    private static func extractYouTubeId(from url: String) -> String? {
        if let components = URLComponents(string: url),
           let queryItem = components.queryItems?.first(where: { $0.name == "v" }) {
            return queryItem.value
        }
        if url.contains("youtu.be/") {
            return url.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }
        // If it doesn't look like a URL, it's probably already a video ID
        if !url.contains("/") && !url.contains(".") {
            return url
        }
        return nil
    }
}
