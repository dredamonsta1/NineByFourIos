import Foundation

struct Album: Codable, Identifiable, Sendable {
    let albumId: Int
    let artistId: Int?
    let albumName: String
    var year: String?
    var certifications: String?
    var albumImageUrl: String?
    var spotifyUrl: String?
    var appleMusicUrl: String?
    // Pillar B commerce fields. Present on every album row but null for
    // most; the trio must all be non-null for an album to be "on sale".
    var priceCents: Int?
    var downloadEnabled: Bool?
    var audioCloudinaryPublicId: String?

    var id: Int { albumId }

    var isOnSale: Bool {
        (priceCents ?? 0) > 0
            && (downloadEnabled ?? false)
            && !(audioCloudinaryPublicId?.isEmpty ?? true)
    }

    enum CodingKeys: String, CodingKey {
        case albumId = "album_id"
        case artistId = "artist_id"
        case albumName = "album_name"
        case year
        case certifications
        case albumImageUrl = "album_image_url"
        case spotifyUrl = "spotify_url"
        case appleMusicUrl = "apple_music_url"
        case priceCents = "price_cents"
        case downloadEnabled = "download_enabled"
        case audioCloudinaryPublicId = "audio_cloudinary_public_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        albumId = try container.decode(Int.self, forKey: .albumId)
        artistId = try container.decodeIfPresent(Int.self, forKey: .artistId)
        albumName = try container.decode(String.self, forKey: .albumName)

        // year comes back as Int from the API but we store as String
        if let intYear = try? container.decodeIfPresent(Int.self, forKey: .year) {
            year = String(intYear)
        } else {
            year = try container.decodeIfPresent(String.self, forKey: .year)
        }

        certifications = try container.decodeIfPresent(String.self, forKey: .certifications)
        albumImageUrl = try container.decodeIfPresent(String.self, forKey: .albumImageUrl)
        spotifyUrl = try container.decodeIfPresent(String.self, forKey: .spotifyUrl)
        appleMusicUrl = try container.decodeIfPresent(String.self, forKey: .appleMusicUrl)
        priceCents = try container.decodeIfPresent(Int.self, forKey: .priceCents)
        downloadEnabled = try container.decodeIfPresent(Bool.self, forKey: .downloadEnabled)
        audioCloudinaryPublicId = try container.decodeIfPresent(String.self, forKey: .audioCloudinaryPublicId)
    }
}

// Fan's owned album (Pillar B). Returned by GET /users/me/purchases.
struct Purchase: Codable, Identifiable, Sendable {
    let id: Int
    let albumId: Int
    let artistId: Int
    let amountCents: Int?
    let createdAt: String?
    let albumName: String?
    let artistName: String?
    let albumImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case albumId = "album_id"
        case artistId = "artist_id"
        case amountCents = "amount_cents"
        case createdAt = "created_at"
        case albumName = "album_name"
        case artistName = "artist_name"
        case albumImageUrl = "album_image_url"
    }
}

struct PurchasesResponse: Codable, Sendable {
    let purchases: [Purchase]
}

// Return payload from POST /albums/:id/checkout. `checkout_url` is the
// Stripe-hosted page we open in SFSafariViewController.
struct AlbumCheckoutResponse: Codable, Sendable {
    let checkoutUrl: String
    let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case checkoutUrl = "checkout_url"
        case sessionId = "session_id"
    }
}
