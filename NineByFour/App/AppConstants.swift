import Foundation

enum AppConstants: Sendable {
    nonisolated static let apiBaseURL = "https://ninebyfourapi.herokuapp.com/api"
    nonisolated static let keychainService = "com.9by4.NineByFour"
    nonisolated static let keychainTokenKey = "auth_token"
    nonisolated static let defaultPageSize = 20
}
