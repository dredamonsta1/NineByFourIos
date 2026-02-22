import Foundation
import Observation

enum DiscoverSection: String, CaseIterable {
    case videos = "Videos"
    case releases = "Upcoming Releases"
}

@Observable
final class DiscoverViewModel {
    var videos: [DiscoverVideo] = []
    var upcomingReleases: [UpcomingRelease] = []
    var isLoading = false
    var errorMessage: String?
    var selectedSection: DiscoverSection = .videos

    @MainActor
    func loadVideos() async {
        isLoading = videos.isEmpty
        errorMessage = nil

        var combined: [VideoPost] = []
        var musicVids: [YouTubeVideo] = []

        // Fetch both endpoints; either can fail gracefully (matches React's Promise.allSettled)
        async let combinedTask: [VideoPost]? = {
            try? await APIClient.shared.request(endpoint: .combinedVideoFeed)
        }()
        async let musicTask: [YouTubeVideo]? = {
            try? await APIClient.shared.request(endpoint: .musicVideos)
        }()

        combined = await combinedTask ?? []
        musicVids = await musicTask ?? []

        let fromCombined = combined.map { DiscoverVideo.fromVideoPost($0) }
        let fromMusic = musicVids.map { DiscoverVideo.fromYouTube($0, source: "music_video") }

        var merged = fromCombined + fromMusic
        merged.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }

        videos = merged

        if videos.isEmpty {
            errorMessage = "No videos available."
        }

        isLoading = false
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
    func loadAll() async {
        isLoading = true
        errorMessage = nil

        async let v: () = loadVideos()
        async let r: () = loadUpcomingReleases()
        _ = await (v, r)

        isLoading = false
    }
}
