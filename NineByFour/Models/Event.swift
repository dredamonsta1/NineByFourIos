import Foundation

struct Event: Codable, Identifiable, Sendable {
    let id: Int
    let userId: Int
    let title: String
    let eventDate: String
    var eventTime: String?
    var venue: String?
    var city: String?
    var flyerUrl: String?
    let createdAt: String
    var username: String?

    enum CodingKeys: String, CodingKey {
        case id = "event_id"
        case userId = "user_id"
        case title
        case eventDate = "event_date"
        case eventTime = "event_time"
        case venue
        case city
        case flyerUrl = "flyer_url"
        case createdAt = "created_at"
        case username
    }
}
