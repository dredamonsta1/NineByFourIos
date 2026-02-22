import Foundation
import Observation

@Observable
final class ArtistListViewModel {
    var artists: [Artist] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var currentPage = 1
    var hasMore = true

    private var isLoadingMore = false

    @MainActor
    func loadArtists() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "\(AppConstants.defaultPageSize)")
            ]
            let response: PaginatedArtistResponse = try await APIClient.shared.request(
                endpoint: .artists,
                queryItems: queryItems
            )
            artists = response.artists
            hasMore = response.hasMore ?? (response.artists.count >= AppConstants.defaultPageSize)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load artists."
        }

        isLoading = false
    }

    @MainActor
    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true

        let nextPage = currentPage + 1
        do {
            var queryItems = [
                URLQueryItem(name: "page", value: "\(nextPage)"),
                URLQueryItem(name: "limit", value: "\(AppConstants.defaultPageSize)")
            ]
            if !searchText.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: searchText))
            }
            let response: PaginatedArtistResponse = try await APIClient.shared.request(
                endpoint: .artists,
                queryItems: queryItems
            )
            artists.append(contentsOf: response.artists)
            currentPage = nextPage
            hasMore = response.hasMore ?? (response.artists.count >= AppConstants.defaultPageSize)
        } catch {
            // Silently fail on pagination errors
        }

        isLoadingMore = false
    }

    @MainActor
    func search() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            var queryItems = [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "limit", value: "\(AppConstants.defaultPageSize)")
            ]
            if !searchText.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: searchText))
            }
            let response: PaginatedArtistResponse = try await APIClient.shared.request(
                endpoint: .artists,
                queryItems: queryItems
            )
            artists = response.artists
            hasMore = response.hasMore ?? (response.artists.count >= AppConstants.defaultPageSize)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Search failed."
        }

        isLoading = false
    }
}
