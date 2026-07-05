import Foundation
import Observation

@Observable
final class AuthManager {
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    // Pillar B fan library. Loaded on hydration + login, cleared on logout.
    // Read by AlbumBuyButton to detect ownership so bought albums flip to
    // "Download" instead of showing a Buy CTA.
    var purchases: [Purchase] = []

    private var purchasedAlbumIds: Set<Int> = []

    func hasPurchased(albumId: Int) -> Bool {
        purchasedAlbumIds.contains(albumId)
    }

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
            await loadPurchases()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred."
        }

        isLoading = false
    }

    // Note: requestCode/verifyCode intentionally do NOT toggle isLoading.
    // AuthGateView shows LoadingStateView while isLoading is true, which
    // would unmount LoginView mid-request and wipe the OTP step + email
    // state. Loading UI lives on the button via AuthViewModel.isLoading.
    @MainActor
    func requestCode(email: String) async {
        errorMessage = nil

        do {
            let body = RequestCodeBody(email: email)
            try await APIClient.shared.requestVoid(endpoint: .requestCode, body: body)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not send code. Try again."
        }
    }

    @MainActor
    func verifyCode(email: String, code: String) async {
        errorMessage = nil

        do {
            let body = VerifyCodeBody(email: email, code: code)
            let response: LoginResponse = try await APIClient.shared.request(
                endpoint: .verifyCode,
                body: body
            )
            KeychainHelper.shared.saveToken(response.token)
            currentUser = response.user
            isAuthenticated = true
            await loadPurchases()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Invalid or expired code."
        }
    }

    @MainActor
    func logout() {
        KeychainHelper.shared.deleteToken()
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        purchases = []
        purchasedAlbumIds = []
    }

    @MainActor
    func loadCurrentUser() async {
        do {
            let user: User = try await APIClient.shared.request(endpoint: .me)
            currentUser = user
            isAuthenticated = true
            await loadPurchases()
        } catch {
            // Token is invalid or expired
            logout()
        }
    }

    @MainActor
    func loadPurchases() async {
        do {
            let response: PurchasesResponse = try await APIClient.shared.request(endpoint: .mePurchases)
            purchases = response.purchases
            purchasedAlbumIds = Set(response.purchases.map(\.albumId))
        } catch {
            // Silently fail — a stale library beats a crash. Refresh happens
            // next time verifyCode or loadCurrentUser runs.
        }
    }
}

private struct LoginBody: Encodable {
    let username: String
    let password: String
}

private struct RequestCodeBody: Encodable {
    let email: String
}

private struct VerifyCodeBody: Encodable {
    let email: String
    let code: String
}
