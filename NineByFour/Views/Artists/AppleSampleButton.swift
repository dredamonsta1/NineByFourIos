import SwiftUI

/// Story 47: a 30-second Apple Music sample for a catalog release, on albums
/// the artist hasn't uploaded audio for. Plays through the shared AudioPlayer,
/// so the PlayerBar and lock screen work as for any other track.
///
/// Apple's preview terms ask for a credit and a link back, so once a clip has
/// loaded a small "Apple Music" link appears beside the button. That's the one
/// exception to the no-link-outs rule (9by4app #195): without it the clip
/// can't be shown. Deezer is never used here for the same reason.
///
/// No clip for a release isn't an error worth an alert: the button just
/// settles into "No sample".
struct AppleSampleButton: View {
    let album: Album
    let artistId: Int

    @Environment(AudioPlayer.self) private var audioPlayer
    @Environment(\.openURL) private var openURL

    enum State: Equatable {
        case idle, fetching, ready(listenUrl: URL?), unavailable, failed
    }

    @SwiftUI.State private var state: State = .idle

    private var trackId: String { "sample-\(album.albumId)" }
    private var isActive: Bool { audioPlayer.currentTrack?.id == trackId }
    private var isBusy: Bool { state == .fetching || (isActive && audioPlayer.isLoading) }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: handleTap) {
                HStack(spacing: 4) {
                    if isBusy {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.Theme.accent)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: iconName).font(.caption2)
                    }
                    Text(labelText).font(.caption2.weight(.semibold))
                }
                .foregroundStyle(state == .unavailable ? Color.Theme.textSecondary : Color.Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((state == .unavailable ? Color.Theme.textSecondary : Color.Theme.accent).opacity(0.12))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(isBusy || state == .unavailable)
            .accessibilityLabel(accessibilityText)

            if case .ready(let listenUrl?) = state {
                Button {
                    openURL(listenUrl)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "applelogo").font(.caption2)
                        Text("Music").font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(Color.Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Listen on Apple Music")
            }
        }
    }

    private var iconName: String {
        switch state {
        case .unavailable: return "speaker.slash"
        case .failed: return "arrow.clockwise"
        default:
            if isActive { return audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill" }
            return "play.circle.fill"
        }
    }

    private var labelText: String {
        switch state {
        case .unavailable: return "No sample"
        case .failed: return "Try again"
        default:
            if isActive { return audioPlayer.isPlaying ? "Playing" : "Paused" }
            return "Sample"
        }
    }

    private var accessibilityText: String {
        switch state {
        case .unavailable: return "No sample available for \(album.albumName)"
        default: return "Play a 30-second sample of \(album.albumName)"
        }
    }

    private func handleTap() {
        if isActive {
            audioPlayer.togglePlayPause()
            return
        }
        Task { await startSample() }
    }

    @MainActor
    private func startSample() async {
        guard state != .fetching else { return }
        state = .fetching
        do {
            let response: AppleSampleResponse = try await APIClient.shared.request(
                endpoint: .artistSample(artistId: artistId),
                queryItems: AppleSampleResponse.query(album: album.albumName)
            )
            guard let url = URL(string: response.previewUrl) else {
                state = .unavailable
                return
            }
            state = .ready(listenUrl: response.listenUrl.flatMap(URL.init(string:)))
            let track = NowPlayingTrack(
                id: trackId,
                title: (response.trackName ?? album.albumName) + " · Sample",
                subtitle: album.albumName,
                artworkUrl: album.albumImageUrl ?? response.albumArtUrl,
                audioUrl: url
            )
            await audioPlayer.play(track: track)
        } catch let APIError.httpError(statusCode, _) where statusCode == 404 {
            state = .unavailable
        } catch {
            state = .failed
        }
    }
}
