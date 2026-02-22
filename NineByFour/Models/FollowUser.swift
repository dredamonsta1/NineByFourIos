import Foundation

struct FollowUser: Codable, Identifiable, Sendable {
    let userId: Int
    let username: String
    var email: String?

    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case email
    }
}
