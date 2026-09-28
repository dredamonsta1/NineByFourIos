import Foundation
import Observation

/// Which filter pill is active. Exactly one at a time, matching the web —
/// the pills are a browse mechanism, not a query builder.
enum ArtistFilter: Equatable {
    case all
    case genre(String)
    case region(String)

    var queryItem: URLQueryItem? {
        switch self {
        case .all: return nil
        case .genre(let g): return URLQueryItem(name: "genre", value: g)
        case .region(let r): return URLQueryItem(name: "region", value: r)
        }
    }
}

@Observable
final class ArtistListViewModel {
    var artists: [Artist] = []
    var searchText = ""
    var filter: ArtistFilter = .all
    var isLoading = false
    var errorMessage: String?
    var currentPage = 1
    var hasMore = true

    private var isLoadingMore = false

    /// One place that builds the query.
    ///
    /// This used to be three near-identical copies, and they had already
    /// drifted: loadArtists() omitted the search term while loadMore()
    /// included it, so paginating a search silently changed what was being
    /// asked for. A filter added to three copies would drift the same way.
    private func queryItems(page: Int) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(AppConstants.defaultPageSize)"),
        ]
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            items.append(URLQueryItem(name: "search", value: trimmed))
        }
        // Searching is a deliberate act and should not be silently narrowed
        // by a pill the user tapped a minute ago.
        else if let filterItem = filter.queryItem {
            items.append(filterItem)
        }
        return items
    }

    @MainActor
    private func load(page: Int, replacing: Bool) async {
        if replacing { isLoading = true; errorMessage = nil } else { isLoadingMore = true }
        defer { if replacing { isLoading = false } else { isLoadingMore = false } }

        do {
            let response: PaginatedArtistResponse = try await APIClient.shared.request(
                endpoint: .artists,
                queryItems: queryItems(page: page)
            )
            if replacing {
                artists = response.artists
                currentPage = 1
            } else {
                artists.append(contentsOf: response.artists)
                currentPage = page
            }
            hasMore = response.hasMore ?? (response.artists.count >= AppConstants.defaultPageSize)
        } catch let error as APIError {
            // Pagination failures stay quiet — the list already on screen is
            // still valid, and an error banner over it would be worse.
            if replacing { errorMessage = error.errorDescription }
        } catch {
            if replacing { errorMessage = "Failed to load artists." }
        }
    }

    @MainActor
    func loadArtists() async { await load(page: 1, replacing: true) }

    @MainActor
    func search() async { await load(page: 1, replacing: true) }

    @MainActor
    func apply(filter newFilter: ArtistFilter) async {
        filter = newFilter
        // Clearing the search is what makes the pill feel like it did
        // something; leaving a stale term would show an unrelated result set.
        searchText = ""
        await load(page: 1, replacing: true)
    }

    @MainActor
    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        await load(page: currentPage + 1, replacing: false)
    }
}
