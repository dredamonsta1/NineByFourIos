import SwiftUI

@main
struct StanboxApp: App {
    @State private var authManager = AuthManager()
    @State private var audioPlayer = AudioPlayer()
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environment(authManager)
                .environment(audioPlayer)
                .environment(router)
                .preferredColorScheme(.dark)
        }
    }
}
