import Foundation
import Observation

@Observable
final class AuthViewModel {
    enum OTPStep { case email, code }

    static let resendCooldownSeconds = 30

    var username = ""
    var password = ""
    var email = ""
    var confirmPassword = ""
    var inviteCode = ""
    var code = ""
    var otpStep: OTPStep = .email
    var resendCooldown = 0
    var infoMessage: String?
    var isLoading = false
    var errorMessage: String?

    private var cooldownTask: Task<Void, Never>?

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
    func sendOTPCode(authManager: AuthManager, silent: Bool = false) async {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            errorMessage = "Email is required."
            return
        }
        errorMessage = nil
        if !silent { infoMessage = nil }
        isLoading = true
        defer { isLoading = false }

        await authManager.requestCode(email: normalized)

        if let error = authManager.errorMessage {
            errorMessage = error
            return
        }

        email = normalized
        otpStep = .code
        startResendCooldown()
        infoMessage = silent
            ? "Code resent. Check your inbox."
            : "We sent a 6-digit code to your email."
    }

    @MainActor
    func verifyOTPCode(authManager: AuthManager) async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 6, trimmed.allSatisfy(\.isNumber) else {
            errorMessage = "Enter the 6-digit code from your email."
            return
        }
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        await authManager.verifyCode(email: email, code: trimmed)

        if let error = authManager.errorMessage {
            errorMessage = error
        }
    }

    @MainActor
    func backToEmailStep() {
        otpStep = .email
        code = ""
        errorMessage = nil
        infoMessage = nil
        cooldownTask?.cancel()
        resendCooldown = 0
    }

    private func startResendCooldown() {
        cooldownTask?.cancel()
        resendCooldown = Self.resendCooldownSeconds
        cooldownTask = Task { @MainActor [weak self] in
            while let self, self.resendCooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                self.resendCooldown -= 1
            }
        }
    }

    @MainActor
    func register(authManager: AuthManager) async {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty, !inviteCode.isEmpty else {
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
            let body = RegisterBody(
                username: username,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password,
                inviteCode: inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            )
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
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case username, email, password
        case inviteCode = "invite_code"
    }
}
