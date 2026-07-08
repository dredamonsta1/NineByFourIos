import Foundation

// Anything that can play through AudioPlayer. Decoupled from any single
// content type — FeedPost, Purchase, and future preview clips all fit
// through this abstraction. The `id` is a stable identity string
// (e.g. "feed-post-42", "album-123") so views can check "is the current
// player playing me?" without knowing what kind of source it is.
struct NowPlayingTrack: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let artworkUrl: String?
    let audioUrl: URL
}

extension FeedPost {
    // Bridges a music FeedPost into the generic NowPlayingTrack surface.
    // Returns nil for posts without a playable `audio_url` (e.g. YouTube
    // videos routed elsewhere, or plain text posts).
    var nowPlayingTrack: NowPlayingTrack? {
        guard let raw = audioUrl, let url = URL(string: raw) else { return nil }
        return NowPlayingTrack(
            id: "feed-post-\(id)",
            title: musicTitle ?? "Music post",
            subtitle: username,
            artworkUrl: imageUrl,
            audioUrl: url
        )
    }
}
