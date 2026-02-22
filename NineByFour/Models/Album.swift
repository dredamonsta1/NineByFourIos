import Foundation

struct Album: Codable, Identifiable, Sendable {
    let albumId: Int
    let artistId: Int?
    let albumName: String
    var year: String?
    var certifications: String?
    var albumImageUrl: String?

    var id: Int { albumId }

    enum CodingKeys: String, CodingKey {
        case albumId = "album_id"
        case artistId = "artist_id"
        case albumName = "album_name"
        case year
        case certifications
        case albumImageUrl = "album_image_url"
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
    }
}
