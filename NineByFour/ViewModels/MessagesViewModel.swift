import Foundation
import Observation

@Observable
final class MessagesViewModel {
    var conversations: [Conversation] = []
    var unreadCount: Int = 0
    var isLoading = false
    var errorMessage: String?

    private var pollingTask: Task<Void, Never>?

    @MainActor
    func loadConversations() async {
        isLoading = conversations.isEmpty
        errorMessage = nil

        do {
            conversations = try await APIClient.shared.request(endpoint: .conversations)
        } catch let error as APIError {
            if conversations.isEmpty {
                errorMessage = error.errorDescription
            }
        } catch {
            if conversations.isEmpty {
                errorMessage = "Failed to load conversations."
            }
        }

        isLoading = false
    }

    @MainActor
    func loadUnreadCount() async {
        do {
            let response: UnreadCountResponse = try await APIClient.shared.request(endpoint: .unreadCount)
            unreadCount = response.count
        } catch {
            // Silently fail on badge count
        }
    }

    func startPolling() {
        stopPolling()
        pollingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { break }
                await self.loadUnreadCount()

                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await self.loadConversations()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
