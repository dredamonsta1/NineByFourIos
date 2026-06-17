import SwiftUI

@main
struct StanboxApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environment(authManager)
                .preferredColorScheme(.dark)
        }
    }
}
