import Foundation

struct WaitlistEntry: Codable, Identifiable, Sendable {
    var waitlistId: Int?
    let email: String
    var fullName: String?
    let status: String
    var inviteCode: String?
    var createdAt: String?

    var id: Int { waitlistId ?? 0 }

    enum CodingKeys: String, CodingKey {
        case waitlistId = "waitlist_id"
        case email
        case fullName = "full_name"
        case status
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}
