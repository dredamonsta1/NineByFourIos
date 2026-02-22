import Foundation

struct AdminStats: Codable, Sendable {
    let totalUsers: Int
    let pendingWaitlist: Int
    let totalPosts: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case pendingWaitlist = "pending_waitlist"
        case totalPosts = "total_posts"
    }
}
