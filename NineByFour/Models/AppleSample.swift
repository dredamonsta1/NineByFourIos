import Foundation

/// GET /artists/:id/preview?album=<name>&provider=apple: Apple Music's 30s
/// clip for one release. `listenUrl` is the track on Apple Music, which the
/// app links to as the credit Apple's preview terms ask for.
struct AppleSampleResponse: Decodable, Sendable {
    let previewUrl: String
    let listenUrl: String?
    let trackName: String?
    let albumArtUrl: String?
    let provider: String?

    enum CodingKeys: String, CodingKey {
        case previewUrl = "preview_url"
        case listenUrl = "listen_url"
        case trackName = "track_name"
        case albumArtUrl = "album_art_url"
        case provider
    }

    /// Query for one album, Apple only (never Deezer: no credit link).
    static func query(album: String) -> [URLQueryItem] {
        [URLQueryItem(name: "album", value: album), URLQueryItem(name: "provider", value: "apple")]
    }
}
