import SwiftUI

@main
struct StanboxApp: App {
    @State private var authManager = AuthManager()
    @State private var audioPlayer = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environment(authManager)
                .environment(audioPlayer)
                .preferredColorScheme(.dark)
        }
    }
}
