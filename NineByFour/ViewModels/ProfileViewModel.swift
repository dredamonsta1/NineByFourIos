import Foundation
import Observation

@Observable
final class ProfileViewModel {
    var profileList: [Artist] = []
    var followers: [FollowUser] = []
    var following: [FollowUser] = []
    var tasteSuggestions: [TasteSuggestion] = []
    var isLoading = false
    var errorMessage: String?

    // Artist search
    var searchText = ""
    var searchResults: [Artist] = []
    var searchLoading = false

    private static let maxListSize = 20

    var isListFull: Bool { profileList.count >= Self.maxListSize }
    var profileListIds: Set<Int> { Set(profileList.map(\.artistId)) }

    @MainActor
    func loadProfileList() async {
        isLoading = profileList.isEmpty
        errorMessage = nil

        do {
            let response: ProfileListResponse = try await APIClient.shared.request(endpoint: .profileList)
            profileList = response.list
        } catch let error as APIError {
            if profileList.isEmpty {
                errorMessage = error.errorDescription
            }
        } catch {
            if profileList.isEmpty {
                errorMessage = "Failed to load profile list."
            }
        }

        isLoading = false
    }

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
            let cloutResponse: CloutResponse = try await APIClient.shared.request(endpoint: .clout(id: artist.artistId))
            var updatedArtist = artist
            updatedArtist.count = cloutResponse.newCloutCount
            profileList.append(updatedArtist)
        } catch {
            // Silently fail
        }
    }

    @MainActor
    func loadFollowers(userId: Int) async {
        do {
            followers = try await APIClient.shared.request(endpoint: .followers(userId: userId))
        } catch {
            // Silently fail
        }
    }

    @MainActor
    func loadFollowing(userId: Int) async {
        do {
            following = try await APIClient.shared.request(endpoint: .following(userId: userId))
        } catch {
            // Silently fail
        }
    }

    @MainActor
    func removeFromProfileList(artistId: Int) async {
        do {
            try await APIClient.shared.requestVoid(endpoint: .removeFromProfileList(artistId: artistId))
            profileList.removeAll { $0.artistId == artistId }
        } catch {
            errorMessage = "Failed to remove artist."
        }
    }

    @MainActor
    func loadTasteSuggestions() async {
        do {
            tasteSuggestions = try await APIClient.shared.request(endpoint: .profileSuggestions)
        } catch {
            // Silently fail
        }
    }
}

struct TasteSuggestion: Codable, Identifiable, Sendable {
    let userId: Int
    let username: String
    let profileImage: String?
    let overlapCount: Int

    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case profileImage = "profile_image"
        case overlapCount = "overlap_count"
    }
}

private struct ProfileListResponse: Codable {
    let list: [Artist]
}
