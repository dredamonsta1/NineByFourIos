import Foundation
import Observation

@Observable
final class ArtistDetailViewModel {
    var artist: Artist?
    var isLoading = false
    var errorMessage: String?
    var hasClout = false
    var isInProfileList = false
    var profileListCount = 0
    var isAddingToProfileList = false

    private static let profileListMax = 20

    var isProfileListFull: Bool { profileListCount >= Self.profileListMax }

    @MainActor
    func loadArtist(id: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: SingleArtistResponse = try await APIClient.shared.request(endpoint: .artist(id: id))
            artist = response.artist
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load artist details."
        }

        isLoading = false
    }

    @MainActor
    func checkProfileList() async {
        do {
            let response: DetailProfileListResponse = try await APIClient.shared.request(endpoint: .profileList)
            let ids = Set(response.list.map(\.artistId))
            profileListCount = response.list.count
            if let artistId = artist?.artistId {
                isInProfileList = ids.contains(artistId)
            }
        } catch {
            // Not logged in or no list
        }
    }

    @MainActor
    func addToProfileList(isAuthenticated: Bool) async {
        guard isAuthenticated,
              let artist,
              !isInProfileList,
              !isProfileListFull,
              !isAddingToProfileList else { return }

        isAddingToProfileList = true
        isInProfileList = true
        profileListCount += 1

        do {
            try await APIClient.shared.requestVoid(
                endpoint: .addToProfileList(artistId: artist.artistId)
            )
        } catch {
            isInProfileList = false
            profileListCount = max(0, profileListCount - 1)
        }

        isAddingToProfileList = false
    }

    @MainActor
    func toggleClout(isAuthenticated: Bool) async {
        guard isAuthenticated, let artist = artist else { return }

        do {
            if hasClout {
                let response: CloutResponse = try await APIClient.shared.request(
                    endpoint: .removeClout(id: artist.artistId)
                )
                self.artist?.count = response.newCloutCount
                hasClout = false
            } else {
                let response: CloutResponse = try await APIClient.shared.request(
                    endpoint: .clout(id: artist.artistId)
                )
                self.artist?.count = response.newCloutCount
                hasClout = true

                // Also add to profile list if not already there and there's room.
                // The explicit "+ Top 20" button on the sheet handles the list-full
                // messaging; clout should never silently overfill the list.
                if !isInProfileList && !isProfileListFull {
                    try? await APIClient.shared.requestVoid(
                        endpoint: .addToProfileList(artistId: artist.artistId)
                    )
                    isInProfileList = true
                    profileListCount += 1
                }
            }
        } catch {
            // Silently fail
        }
    }
}

private struct DetailProfileListResponse: Codable {
    let list: [DetailProfileListArtist]

    struct DetailProfileListArtist: Codable {
        let artistId: Int

        enum CodingKeys: String, CodingKey {
            case artistId = "artist_id"
        }
    }
}
