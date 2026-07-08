import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case GET, POST, PUT, PATCH, DELETE
}

// Endpoint surface for the v1 fan iOS app. Artist-side commerce (uploads,
// pricing, Stripe Connect, YourMusic) and admin tooling stay on the web —
// see project_ios_v1_fan_app.md. The OTP pair (.requestCode/.verifyCode)
// is the iOS sign-in path; .register/.login are orphan legacy kept compiling
// for the unused RegisterView until that view is properly removed.
nonisolated enum APIEndpoint: Sendable {
    // MARK: - Auth
    case requestCode
    case verifyCode
    case register
    case login
    case me
    case userProfile(userId: Int)
    case uploadProfileImage
    case mePurchases

    // MARK: - Artists (read-only on iOS — artist-side management is web)
    case artists
    case artist(id: Int)
    case clout(id: Int)
    case removeClout(id: Int)

    // MARK: - Albums (Pillar B commerce)
    case albumCheckout(id: Int)
    case albumStream(id: Int)
    case albumPreview(id: Int)

    // MARK: - Feed
    case feed
    case feedText
    case feedImage
    case feedVideo
    case feedVideoUrl
    case feedMusic
    case deleteFeedPost(type: String, id: Int)

    // MARK: - Image Posts
    case imagePosts
    case createImagePost
    case deleteImagePost(id: Int)

    // MARK: - Videos
    case youtubeFeed
    case combinedVideoFeed
    case musicVideos

    // MARK: - Music
    case upcomingReleases

    // MARK: - Profile List (Top 20)
    case profileList
    case profileSuggestions
    case userProfileList(userId: Int)
    case addToProfileList(artistId: Int)
    case removeFromProfileList(artistId: Int)

    // MARK: - Follows (user → user)
    case follow(userId: Int)
    case unfollow(userId: Int)
    case followers(userId: Int)
    case following(userId: Int)

    // MARK: - Messages
    case conversations
    case createConversation
    case conversationMessages(id: Int)
    case sendMessage(conversationId: Int)
    case markConversationRead(id: Int)
    case unreadCount
    case checkDM(userId: Int)

    // MARK: - Waitlist (sign-up flow only — admin entries surface is web)
    case waitlistJoin
    case waitlistVerify

    // MARK: - Events
    case events
    case createEvent
    case deleteEvent(id: Int)

    var path: String {
        switch self {
        // Auth
        case .requestCode: return "/auth/send-code"
        case .verifyCode: return "/auth/verify-code"
        case .register: return "/users/register"
        case .login: return "/users/login"
        case .me: return "/users/me"
        case .userProfile(let userId): return "/users/\(userId)/profile"
        case .uploadProfileImage: return "/users/profile-image"
        case .mePurchases: return "/users/me/purchases"

        // Artists
        case .artists: return "/artists"
        case .artist(let id): return "/artists/\(id)"
        case .clout(let id): return "/artists/\(id)/clout"
        case .removeClout(let id): return "/artists/\(id)/clout/remove"

        // Albums
        case .albumCheckout(let id): return "/albums/\(id)/checkout"
        case .albumStream(let id): return "/albums/\(id)/stream"
        case .albumPreview(let id): return "/albums/\(id)/preview"

        // Feed
        case .feed: return "/feed"
        case .feedText: return "/feed/text"
        case .feedImage: return "/feed/image"
        case .feedVideo: return "/feed/video"
        case .feedVideoUrl: return "/feed/video-url"
        case .feedMusic: return "/feed/music"
        case .deleteFeedPost(let type, let id): return "/feed/\(type)/\(id)"

        // Image Posts
        case .imagePosts: return "/image-posts"
        case .createImagePost: return "/image-posts"
        case .deleteImagePost(let id): return "/image-posts/\(id)"

        // Videos
        case .youtubeFeed: return "/art/youtube-feed"
        case .combinedVideoFeed: return "/art/combined-video-feed"
        case .musicVideos: return "/art/music-videos"

        // Music
        case .upcomingReleases: return "/music/upcoming"

        // Profile List
        case .profileList: return "/profile/list"
        case .profileSuggestions: return "/profile/suggestions"
        case .userProfileList(let userId): return "/profile/user/\(userId)"
        case .addToProfileList(let artistId): return "/profile/list/\(artistId)"
        case .removeFromProfileList(let artistId): return "/profile/list/\(artistId)"

        // Follows
        case .follow(let userId): return "/users/\(userId)/follow"
        case .unfollow(let userId): return "/users/\(userId)/unfollow"
        case .followers(let userId): return "/users/\(userId)/followers"
        case .following(let userId): return "/users/\(userId)/following"

        // Messages
        case .conversations: return "/messages/conversations"
        case .createConversation: return "/messages/conversations"
        case .conversationMessages(let id): return "/messages/conversations/\(id)"
        case .sendMessage(let conversationId): return "/messages/conversations/\(conversationId)"
        case .markConversationRead(let id): return "/messages/conversations/\(id)/read"
        case .unreadCount: return "/messages/unread-count"
        case .checkDM(let userId): return "/messages/check-dm/\(userId)"

        // Waitlist
        case .waitlistJoin: return "/waitlist/join"
        case .waitlistVerify: return "/waitlist/verify"

        // Events
        case .events: return "/events"
        case .createEvent: return "/events"
        case .deleteEvent(let id): return "/events/\(id)"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .requestCode, .verifyCode, .register, .login, .waitlistJoin, .waitlistVerify,
             .albumPreview:
            return false
        default:
            return true
        }
    }

    var method: HTTPMethod {
        switch self {
        case .requestCode, .verifyCode, .register, .login, .uploadProfileImage,
             .feedText, .feedImage, .feedVideo, .feedVideoUrl, .feedMusic,
             .createImagePost,
             .albumCheckout,
             .addToProfileList, .follow,
             .createConversation, .sendMessage,
             .waitlistJoin, .waitlistVerify, .createEvent:
            return .POST

        case .clout, .removeClout:
            return .PUT

        case .markConversationRead:
            return .PATCH

        case .deleteFeedPost, .deleteImagePost,
             .removeFromProfileList, .unfollow,
             .deleteEvent:
            return .DELETE

        default:
            return .GET
        }
    }
}
