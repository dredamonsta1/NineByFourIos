import Foundation
import Observation

@Observable
final class ArtistDetailViewModel {
    var artist: Artist?
    var isLoading = false
    var errorMessage: String?
    var hasClout = false

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
    func toggleClout() async {
        guard let artistId = artist?.artistId else { return }

        do {
            if hasClout {
                let response: CloutResponse = try await APIClient.shared.request(
                    endpoint: .removeClout(id: artistId)
                )
                artist?.count = response.newCloutCount
                hasClout = false
            } else {
                let response: CloutResponse = try await APIClient.shared.request(
                    endpoint: .clout(id: artistId)
                )
                artist?.count = response.newCloutCount
                hasClout = true
            }
        } catch {
            // Silently fail — user may not be authenticated
        }
    }
}
