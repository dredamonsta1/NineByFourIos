import Foundation
import Observation

@Observable
final class AuthViewModel {
    var username = ""
    var password = ""
    var email = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func login(authManager: AuthManager) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password."
            return
        }

        isLoading = true
        errorMessage = nil
        await authManager.login(username: username, password: password)

        if let error = authManager.errorMessage {
            errorMessage = error
        }
        isLoading = false
    }

    @MainActor
    func register(authManager: AuthManager) async {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let body = RegisterBody(username: username, email: email, password: password)
            let _: LoginResponse = try await APIClient.shared.request(
                endpoint: .register,
                body: body
            )
            // Auto-login after registration
            await authManager.login(username: username, password: password)

            if let error = authManager.errorMessage {
                errorMessage = error
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Registration failed. Please try again."
        }

        isLoading = false
    }
}

private struct RegisterBody: Encodable {
    let username: String
    let email: String
    let password: String
}
