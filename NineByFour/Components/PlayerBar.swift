import SwiftUI

struct PlayerBar: View {
    @Environment(AudioPlayer.self) private var player

    var body: some View {
        if let post = player.currentPost {
            HStack(spacing: 12) {
                FrequencyVisualizer(bars: player.fftBars, tint: Color.Theme.accent)
                    .frame(width: 56, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.musicTitle ?? "Music post")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.Theme.textPrimary)
                        .lineLimit(1)
                    if let username = post.username {
                        Text(username)
                            .font(.caption2)
                            .foregroundStyle(Color.Theme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    player.togglePlayPause()
                } label: {
                    if player.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.Theme.accent)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundStyle(Color.Theme.accent)
                            .frame(width: 32, height: 32)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    Task { await player.stop() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.Theme.textSecondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.Theme.bgCardElevated)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.Theme.borderDefault),
                alignment: .top
            )
        }
    }
}

// MARK: - Visualizer

private struct FrequencyVisualizer: View {
    let bars: [Float]
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 1.5) {
                ForEach(0..<bars.count, id: \.self) { index in
                    Capsule()
                        .fill(tint)
                        .frame(height: max(2, proxy.size.height * CGFloat(bars[index])))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(.linear(duration: 0.06), value: bars)
        }
    }
}
