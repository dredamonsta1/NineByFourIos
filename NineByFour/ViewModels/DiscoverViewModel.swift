import Foundation
import Observation

enum DiscoverSection: String, CaseIterable {
    case artists = "Artists"
    case videos = "Videos"
    case releases = "Releases"
}

@Observable
final class DiscoverViewModel {
    var videos: [DiscoverVideo] = []
    var upcomingReleases: [UpcomingRelease] = []
    var isLoading = false
    var errorMessage: String?
    var selectedSection: DiscoverSection = .artists

    // Artist search
    var searchText = ""
    var searchResults: [Artist] = []
    var searchLoading = false
    var profileListIds: Set<Int> = []
    var profileListCount: Int = 0

    private static let maxListSize = 20

    var isListFull: Bool { profileListCount >= Self.maxListSize }

    @MainActor
    func searchArtists() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchLoading = true

        do {
            let queryItems = [
                URLQueryItem(name: "search", value: query),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "20")
            ]
            let response: PaginatedArtistResponse = try await APIClient.shared.request(
                endpoint: .artists,
                queryItems: queryItems
            )
            searchResults = response.artists
        } catch {
            searchResults = []
        }

        searchLoading = false
    }

    @MainActor
    func addToProfileList(artist: Artist) async {
        guard !isListFull, !profileListIds.contains(artist.artistId) else { return }

        do {
            try await APIClient.shared.requestVoid(endpoint: .addToProfileList(artistId: artist.artistId))
            profileListIds.insert(artist.artistId)
            profileListCount += 1
        } catch {
            // Silently fail
        }
    }

    @MainActor
    func loadProfileListIds() async {
        do {
            let response: ProfileListIdsResponse = try await APIClient.shared.request(endpoint: .profileList)
            profileListIds = Set(response.list.map(\.artistId))
            profileListCount = response.list.count
        } catch {
            // Silently fail — user may not be logged in
        }
    }

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
        async let p: () = loadProfileListIds()
        _ = await (v, r, p)

        isLoading = false
    }
}

private struct ProfileListIdsResponse: Codable {
    let list: [ProfileListArtist]

    struct ProfileListArtist: Codable {
        let artistId: Int

        enum CodingKeys: String, CodingKey {
            case artistId = "artist_id"
        }
    }
}
