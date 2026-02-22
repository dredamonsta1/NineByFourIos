import Foundation

struct Artist: Codable, Identifiable, Sendable {
    let artistId: Int
    let artistName: String
    var aka: String?
    var genre: String?
    var count: Int?
    var state: String?
    var region: String?
    var label: String?
    var imageUrl: String?
    var albums: [Album]?

    var id: Int { artistId }

    enum CodingKeys: String, CodingKey {
        case artistId = "artist_id"
        case artistName = "artist_name"
        case aka
        case genre
        case count
        case state
        case region
        case label
        case imageUrl = "image_url"
        case albums
    }
}

struct SingleArtistResponse: Codable, Sendable {
    let artist: Artist
}

struct PaginatedArtistResponse: Codable, Sendable {
    let artists: [Artist]
    var page: Int?
    var limit: Int?
    var totalCount: Int?
    var totalPages: Int?
    var hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case artists
        case page
        case limit
        case totalCount = "total_count"
        case totalPages = "total_pages"
        case hasMore = "has_more"
    }
}
