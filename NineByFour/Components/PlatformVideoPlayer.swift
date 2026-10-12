import AVKit
import SwiftUI

/// Native playback for an uploaded video. Doesn't autoplay unless asked —
/// the audio player owns sound, and a feed that starts playing beside it is
/// a bad surprise (decided 2026-09-13). Pauses when it leaves the screen.
struct PlatformVideoPlayer: View {
    let url: URL
    var autoplay = false
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                if player == nil { player = AVPlayer(url: url) }
                if autoplay { player?.play() }
            }
            .onDisappear { player?.pause() }
    }
}
