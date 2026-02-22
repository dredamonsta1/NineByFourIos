import Foundation
import Observation

@Observable
final class AuthManager {
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    init() {
        if KeychainHelper.shared.getToken() != nil {
            isAuthenticated = true
            Task { await loadCurrentUser() }
        }
    }

    @MainActor
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let body = LoginBody(username: username, password: password)
            let response: LoginResponse = try await APIClient.shared.request(
                endpoint: .login,
                body: body
            )
            KeychainHelper.shared.saveToken(response.token)
            currentUser = response.user
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred."
        }

        isLoading = false
    }

    @MainActor
    func logout() {
        KeychainHelper.shared.deleteToken()
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }

    @MainActor
    func loadCurrentUser() async {
        do {
            let user: User = try await APIClient.shared.request(endpoint: .me)
            currentUser = user
            isAuthenticated = true
        } catch {
            // Token is invalid or expired
            logout()
        }
    }
}

private struct LoginBody: Encodable {
    let username: String
    let password: String
}
