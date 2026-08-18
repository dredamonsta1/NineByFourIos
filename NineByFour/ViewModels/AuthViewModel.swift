import Foundation
import Observation

@Observable
final class AuthViewModel {
    enum OTPStep { case email, code }
    /// Login and signup are the same two-step flow; signup just carries a
    /// username + invite code through to the verify call, which is what
    /// tells the backend to create the account.
    enum Mode { case login, signup }

    static let resendCooldownSeconds = 30

    var mode: Mode = .login
    var username = ""
    var email = ""
    var inviteCode = ""
    var code = ""
    var otpStep: OTPStep = .email
    var resendCooldown = 0
    var infoMessage: String?
    var isLoading = false
    var errorMessage: String?

    private var cooldownTask: Task<Void, Never>?

    @MainActor
    func sendOTPCode(authManager: AuthManager, silent: Bool = false) async {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            errorMessage = "Email is required."
            return
        }
        if mode == .signup {
            guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Username and invite code are required."
                return
            }
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

        await authManager.verifyCode(
            email: email,
            code: trimmed,
            username: mode == .signup
                ? username.trimmingCharacters(in: .whitespacesAndNewlines)
                : nil,
            inviteCode: mode == .signup
                ? inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                : nil
        )

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
}
