import Foundation
import Observation

@Observable
final class ChatViewModel {
    var messages: [Message] = []
    var newMessageText = ""
    var isLoading = false
    var errorMessage: String?
    var hasMore = false

    private var pollingTask: Task<Void, Never>?
    private var currentPage = 1

    @MainActor
    func loadMessages(conversationId: Int) async {
        isLoading = messages.isEmpty
        errorMessage = nil
        currentPage = 1

        do {
            let response: MessagesResponse = try await APIClient.shared.request(
                endpoint: .conversationMessages(id: conversationId),
                queryItems: [URLQueryItem(name: "page", value: "1")]
            )
            messages = Array(response.messages.reversed())
            hasMore = response.hasMore
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load messages."
        }

        isLoading = false
    }

    @MainActor
    func sendMessage(conversationId: Int) async {
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        do {
            let body = SendMessageBody(content: text)
            let message: Message = try await APIClient.shared.request(
                endpoint: .sendMessage(conversationId: conversationId),
                body: body
            )
            messages.append(message)
            newMessageText = ""
        } catch {
            errorMessage = "Failed to send message."
        }
    }

    @MainActor
    func markAsRead(conversationId: Int) async {
        do {
            try await APIClient.shared.requestVoid(endpoint: .markConversationRead(id: conversationId))
        } catch {
            // Silently fail
        }
    }

    @MainActor
    func loadMore(conversationId: Int) async {
        guard hasMore else { return }
        let nextPage = currentPage + 1

        do {
            let response: MessagesResponse = try await APIClient.shared.request(
                endpoint: .conversationMessages(id: conversationId),
                queryItems: [URLQueryItem(name: "page", value: "\(nextPage)")]
            )
            let older = Array(response.messages.reversed())
            messages.insert(contentsOf: older, at: 0)
            currentPage = nextPage
            hasMore = response.hasMore
        } catch {
            // Silently fail on pagination
        }
    }

    func startPolling(conversationId: Int) {
        stopPolling()
        pollingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await self.refreshLatest(conversationId: conversationId)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @MainActor
    private func refreshLatest(conversationId: Int) async {
        do {
            let response: MessagesResponse = try await APIClient.shared.request(
                endpoint: .conversationMessages(id: conversationId),
                queryItems: [URLQueryItem(name: "page", value: "1")]
            )
            let latest = Array(response.messages.reversed())
            if latest.count != messages.suffix(latest.count).count || latest.last?.messageId != messages.last?.messageId {
                messages = latest
            }
        } catch {
            // Silently fail on poll
        }
    }
}

private struct SendMessageBody: Encodable {
    let content: String
}
