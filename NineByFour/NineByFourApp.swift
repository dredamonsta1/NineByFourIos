import SwiftUI

@main
struct VediozApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environment(authManager)
                .preferredColorScheme(.dark)
        }
    }
}
