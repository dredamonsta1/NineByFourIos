import Foundation
import Observation

enum DiscoverSection: String, CaseIterable {
    case videos = "Videos"
    case releases = "Releases"
    case events = "Events"
}

/// Discover → Videos tabs (Story 31), matching the web /videos page.
enum VideoTab: String, CaseIterable {
    case all = "All"
    case following = "Following"
}

@Observable
final class DiscoverViewModel {
    var videos: [PlatformVideo] = []
    var videoTab: VideoTab = .all
    var musicOnly = false
    var nextBefore: Int?
    var isLoadingMore = false
    /// Following is selected while signed out.
    var videosNeedSignIn = false
    var upcomingReleases: [UpcomingRelease] = []
    var isLoading = false
    var errorMessage: String?
    var selectedSection: DiscoverSection = .videos

    private func videoQuery(before: Int?) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "tab", value: videoTab == .following ? "following" : "all")]
        if musicOnly { items.append(URLQueryItem(name: "type", value: "music")) }
        if let before { items.append(URLQueryItem(name: "before", value: String(before))) }
        return items
    }

    /// Platform uploads from GET /api/videos. An empty list is an empty
    /// state, not an error.
    @MainActor
    func loadVideos(isAuthenticated: Bool) async {
        errorMessage = nil
        if videoTab == .following && !isAuthenticated {
            videosNeedSignIn = true
            videos = []
            nextBefore = nil
            return
        }
        videosNeedSignIn = false
        isLoading = videos.isEmpty

        do {
            let page: VideosPage = try await APIClient.shared.request(endpoint: .videos, queryItems: videoQuery(before: nil))
            videos = page.videos
            nextBefore = page.nextBefore
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load videos."
        }

        isLoading = false
    }

    @MainActor
    func loadMoreVideos() async {
        guard let before = nextBefore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        if let page: VideosPage = try? await APIClient.shared.request(endpoint: .videos, queryItems: videoQuery(before: before)) {
            videos.append(contentsOf: page.videos)
            nextBefore = page.nextBefore
        }
    }

    @MainActor
    func loadUpcomingReleases() async {
        isLoading = upcomingReleases.isEmpty
        errorMessage = nil

        do {
            upcomingReleases = try await APIClient.shared.request(endpoint: .upcomingReleases)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load upcoming releases."
        }

        isLoading = false
    }

    @MainActor
    func loadAll(isAuthenticated: Bool) async {
        isLoading = true
        errorMessage = nil

        async let v: () = loadVideos(isAuthenticated: isAuthenticated)
        async let r: () = loadUpcomingReleases()
        _ = await (v, r)

        isLoading = false
    }
}
