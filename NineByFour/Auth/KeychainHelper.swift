import Foundation
@preconcurrency import KeychainAccess

nonisolated final class KeychainHelper: Sendable {
    nonisolated static let shared = KeychainHelper()

    private let keychain: Keychain

    private init() {
        self.keychain = Keychain(service: AppConstants.keychainService)
            .accessibility(.afterFirstUnlock)
    }

    func saveToken(_ token: String) {
        try? keychain.set(token, key: AppConstants.keychainTokenKey)
    }

    func getToken() -> String? {
        try? keychain.get(AppConstants.keychainTokenKey)
    }

    func deleteToken() {
        try? keychain.remove(AppConstants.keychainTokenKey)
    }
}
