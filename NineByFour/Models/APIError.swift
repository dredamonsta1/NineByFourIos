import Foundation

nonisolated enum APIError: LocalizedError, Sendable {
    case unauthorized
    /// The server's own explanation when it sends one (e.g. "Invalid or
    /// unapproved invite code."), so people see why, not just that.
    case forbidden(message: String?)
    case httpError(statusCode: Int, message: String)
    case decodingError
    case networkError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please log in again."
        case .forbidden(let message):
            if let message, !message.isEmpty { return message }
            return "You don't have permission to perform this action."
        case .httpError(let statusCode, let message):
            return "Error \(statusCode): \(message)"
        case .decodingError:
            return "Failed to process server response."
        case .networkError:
            return "Network connection failed. Please check your internet."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}
