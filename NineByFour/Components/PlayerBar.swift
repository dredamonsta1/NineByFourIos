import SwiftUI

struct PlayerBar: View {
    @Environment(AudioPlayer.self) private var player

    var body: some View {
        if let track = player.currentTrack {
            HStack(spacing: 12) {
                FrequencyVisualizer(bars: player.fftBars, tint: Color.Theme.accent)
                    .frame(width: 56, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.Theme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let subtitle = track.subtitle {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(Color.Theme.textSecondary)
                                .lineLimit(1)
                        }
                        if player.queue.count > 1 {
                            Text("\(player.queueIndex + 1)/\(player.queue.count)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(Color.Theme.textSecondary)
                        }
                    }
                }

                Spacer()

                if player.queue.count > 1 {
                    Button {
                        Task { await player.previous() }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.subheadline)
                            .foregroundStyle(player.hasPrevious
                                             ? Color.Theme.accent
                                             : Color.Theme.textSecondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(!player.hasPrevious)
                }

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

                if player.queue.count > 1 {
                    Button {
                        Task { await player.next() }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.subheadline)
                            .foregroundStyle(player.hasNext
                                             ? Color.Theme.accent
                                             : Color.Theme.textSecondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(!player.hasNext)
                }

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
