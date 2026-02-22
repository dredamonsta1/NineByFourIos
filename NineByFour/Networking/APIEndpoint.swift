import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case GET, POST, PUT, PATCH, DELETE
}

nonisolated enum APIEndpoint: Sendable {
    // MARK: - Auth
    case register
    case login
    case me
    case userProfile(userId: Int)
    case uploadProfileImage

    // MARK: - Artists
    case artists
    case artist(id: Int)
    case createArtist
    case updateArtist(id: Int)
    case deleteArtist(id: Int)
    case uploadArtistImage
    case updateArtistImage(id: Int)
    case addAlbums(artistId: Int)
    case deleteAlbum(artistId: Int, albumId: Int)
    case clout(id: Int)
    case removeClout(id: Int)

    // MARK: - Feed
    case feed
    case feedText
    case feedImage
    case feedVideo
    case feedVideoUrl
    case deleteFeedPost(type: String, id: Int)

    // MARK: - Posts (legacy)
    case posts
    case createPost
    case updatePost(id: Int)
    case deletePost(id: Int)

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

    // MARK: - Profile List
    case profileList
    case userProfileList(userId: Int)
    case addToProfileList(artistId: Int)
    case removeFromProfileList(artistId: Int)

    // MARK: - Follows
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

    // MARK: - Waitlist
    case waitlistJoin
    case waitlistVerify
    case waitlistEntries
    case waitlistApprove(id: Int)
    case waitlistReject(id: Int)
    case waitlistToggle
    case waitlistDelete(id: Int)

    // MARK: - Admin
    case adminStats
    case adminApproveCreator
    case adminWaitlistEntries
    case adminResetUser

    var path: String {
        switch self {
        // Auth
        case .register: return "/users/register"
        case .login: return "/users/login"
        case .me: return "/users/me"
        case .userProfile(let userId): return "/users/\(userId)/profile"
        case .uploadProfileImage: return "/users/profile-image"

        // Artists
        case .artists: return "/artists"
        case .artist(let id): return "/artists/\(id)"
        case .createArtist: return "/artists"
        case .updateArtist(let id): return "/artists/\(id)"
        case .deleteArtist(let id): return "/artists/\(id)"
        case .uploadArtistImage: return "/artists/upload-image"
        case .updateArtistImage(let id): return "/artists/\(id)/image"
        case .addAlbums(let artistId): return "/artists/\(artistId)/albums"
        case .deleteAlbum(let artistId, let albumId): return "/artists/\(artistId)/albums/\(albumId)"
        case .clout(let id): return "/artists/\(id)/clout"
        case .removeClout(let id): return "/artists/\(id)/clout/remove"

        // Feed
        case .feed: return "/feed"
        case .feedText: return "/feed/text"
        case .feedImage: return "/feed/image"
        case .feedVideo: return "/feed/video"
        case .feedVideoUrl: return "/feed/video-url"
        case .deleteFeedPost(let type, let id): return "/feed/\(type)/\(id)"

        // Posts
        case .posts: return "/posts"
        case .createPost: return "/posts"
        case .updatePost(let id): return "/posts/\(id)"
        case .deletePost(let id): return "/posts/\(id)"

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
        case .waitlistEntries: return "/waitlist"
        case .waitlistApprove(let id): return "/waitlist/\(id)/approve"
        case .waitlistReject(let id): return "/waitlist/\(id)/reject"
        case .waitlistToggle: return "/waitlist/toggle"
        case .waitlistDelete(let id): return "/waitlist/\(id)"

        // Admin
        case .adminStats: return "/admin/stats"
        case .adminApproveCreator: return "/admin/approve-creator"
        case .adminWaitlistEntries: return "/admin/waitlist-entries"
        case .adminResetUser: return "/admin/reset-user"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register, .login, .uploadProfileImage,
             .createArtist, .uploadArtistImage, .addAlbums,
             .feedText, .feedImage, .feedVideo, .feedVideoUrl,
             .createPost, .createImagePost,
             .addToProfileList, .follow,
             .createConversation, .sendMessage,
             .waitlistJoin, .waitlistVerify, .waitlistApprove, .waitlistReject, .waitlistToggle,
             .adminApproveCreator:
            return .POST

        case .updateArtist, .updateArtistImage, .clout, .removeClout, .updatePost:
            return .PUT

        case .markConversationRead, .adminResetUser:
            return .PATCH

        case .deleteArtist, .deleteAlbum, .deleteFeedPost, .deletePost, .deleteImagePost,
             .removeFromProfileList, .unfollow, .waitlistDelete:
            return .DELETE

        default:
            return .GET
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .register, .login,
             .artists, .artist,
             .imagePosts,
             .youtubeFeed, .musicVideos,
             .upcomingReleases,
             .followers, .following,
             .waitlistJoin, .waitlistVerify:
            return false
        default:
            return true
        }
    }
}
