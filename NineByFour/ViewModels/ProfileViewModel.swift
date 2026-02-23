import Foundation
import Observation

@Observable
final class ProfileViewModel {
    var profileList: [Artist] = []
    var followers: [FollowUser] = []
    var following: [FollowUser] = []
    var isLoading = false
    var errorMessage: String?

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
}

private struct ProfileListResponse: Codable {
    let list: [Artist]
}
