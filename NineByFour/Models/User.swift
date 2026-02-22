import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: Int
    let username: String
    var email: String?
    var role: String?
    var profileImage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case email
        case role
        case profileImage = "profile_image"
    }

    init(id: Int, username: String, email: String? = nil, role: String? = nil, profileImage: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.role = role
        self.profileImage = profileImage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Backend returns "id" from login and "user_id" from /me
        if let id = try? container.decode(Int.self, forKey: .id) {
            self.id = id
        } else {
            self.id = try container.decode(Int.self, forKey: .userId)
        }
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.role = try container.decodeIfPresent(String.self, forKey: .role)
        self.profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(profileImage, forKey: .profileImage)
    }
}

struct LoginResponse: Codable, Sendable {
    let token: String
    let user: User
}
