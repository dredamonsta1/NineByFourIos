import Foundation

/// A video uploaded to StanBox — GET /api/videos (Story 31).
/// YouTube was removed on 2026-09-13; these are platform uploads only.
struct PlatformVideo: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let userId: Int
    var username: String?
    var profileImage: String?
    var title: String?
    var caption: String?
    let videoUrl: String
    /// The same upload served as MP4. Chrome records WebM, which iOS can't
    /// play, so always prefer this.
    var playbackUrl: String?
    var thumbnailUrl: String?
    var isMusicVideo: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case profileImage = "profile_image"
        case title
        case caption
        case videoUrl = "video_url"
        case playbackUrl = "playback_url"
        case thumbnailUrl = "thumbnail_url"
        case isMusicVideo = "is_music_video"
        case createdAt = "created_at"
    }

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        if let caption, !caption.isEmpty { return caption }
        return "Untitled video"
    }

    var playURL: URL? { URL(string: playbackUrl ?? videoUrl) }

    var posterURL: URL? {
        if let thumbnailUrl, let url = URL(string: thumbnailUrl) { return url }
        return PlatformVideo.posterURL(for: playbackUrl ?? videoUrl)
    }

    /// Cloudinary serves a frame of any uploaded video as a JPG at the same
    /// path with a .jpg extension. Nil for anything else.
    static func posterURL(for videoURL: String?) -> URL? {
        guard let videoURL, videoURL.contains("res.cloudinary.com"), videoURL.contains("/video/upload/") else { return nil }
        guard let dot = videoURL.lastIndex(of: "."), let slash = videoURL.lastIndex(of: "/"), dot > slash else {
            return URL(string: videoURL + ".jpg")
        }
        return URL(string: String(videoURL[..<dot]) + ".jpg")
    }
}

/// A page of GET /api/videos.
struct VideosPage: Codable, Sendable {
    let videos: [PlatformVideo]
    let nextBefore: Int?

    enum CodingKeys: String, CodingKey {
        case videos
        case nextBefore = "next_before"
    }
}
