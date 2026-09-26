import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: Int
    let username: String
    var email: String?
    var role: String?
    var profileImage: String?
    // /users/me has returned these all along; the model simply never decoded
    // them, so the personality was on the wire and thrown away on arrival.
    var musicPersonalityTitle: String?
    var musicPersonalityDesc: String?
    var musicPersonalityPublic: Bool?

    /// True once a personality has been generated.
    var hasPersonality: Bool {
        !(musicPersonalityTitle ?? "").isEmpty
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case email
        case role
        case profileImage = "profile_image"
        case musicPersonalityTitle = "music_personality_title"
        case musicPersonalityDesc = "music_personality_desc"
        case musicPersonalityPublic = "music_personality_public"
    }

    init(
        id: Int,
        username: String,
        email: String? = nil,
        role: String? = nil,
        profileImage: String? = nil,
        musicPersonalityTitle: String? = nil,
        musicPersonalityDesc: String? = nil,
        musicPersonalityPublic: Bool? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.role = role
        self.profileImage = profileImage
        self.musicPersonalityTitle = musicPersonalityTitle
        self.musicPersonalityDesc = musicPersonalityDesc
        self.musicPersonalityPublic = musicPersonalityPublic
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
        self.musicPersonalityTitle = try container.decodeIfPresent(String.self, forKey: .musicPersonalityTitle)
        self.musicPersonalityDesc = try container.decodeIfPresent(String.self, forKey: .musicPersonalityDesc)
        self.musicPersonalityPublic = try container.decodeIfPresent(Bool.self, forKey: .musicPersonalityPublic)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(profileImage, forKey: .profileImage)
        try container.encodeIfPresent(musicPersonalityTitle, forKey: .musicPersonalityTitle)
        try container.encodeIfPresent(musicPersonalityDesc, forKey: .musicPersonalityDesc)
        try container.encodeIfPresent(musicPersonalityPublic, forKey: .musicPersonalityPublic)
    }
}

struct LoginResponse: Codable, Sendable {
    let token: String
    let user: User
}
