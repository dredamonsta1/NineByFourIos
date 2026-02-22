import Foundation
import Observation

@Observable
final class FeedViewModel {
    var posts: [FeedPost] = []
    var isLoading = false
    var errorMessage: String?
    var newPostContent = ""

    @MainActor
    func loadFeed() async {
        isLoading = true
        errorMessage = nil

        do {
            posts = try await APIClient.shared.request(endpoint: .feed)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load feed."
        }

        isLoading = false
    }

    @MainActor
    func createTextPost() async -> Bool {
        guard !newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        do {
            let body = TextPostBody(content: newPostContent)
            let _: FeedPost = try await APIClient.shared.request(
                endpoint: .feedText,
                body: body
            )
            newPostContent = ""
            await loadFeed()
            return true
        } catch {
            errorMessage = "Failed to create post."
            return false
        }
    }

    @MainActor
    func deletePost(type: String, id: Int) async {
        do {
            try await APIClient.shared.requestVoid(endpoint: .deleteFeedPost(type: type, id: id))
            posts.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete post."
        }
    }
}

private struct TextPostBody: Encodable {
    let content: String
}
