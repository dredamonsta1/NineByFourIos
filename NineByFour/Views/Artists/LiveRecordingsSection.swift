import SwiftUI

/// Internet Archive bootleg concerts for an artist.
///
/// The web has had this on the artist page since the live-recordings
/// pipeline landed; iOS never got it. That mattered more than it looked:
/// the Library needs a purchase and album previews need audio uploaded to
/// Cloudinary, so on iOS a brand-new user had no reachable audio at all.
/// Bootlegs are free Archive.org streams and roughly 200 catalog artists
/// have them.
///
/// Renders nothing when an artist has no recordings, which is most of them
/// — an empty "Live Recordings" header on every artist page would be worse
/// than no section.
struct LiveRecordingsSection: View {
    let artistId: Int

    @Environment(AudioPlayer.self) private var audioPlayer
    @State private var recordings: [LiveRecording] = []
    @State private var expanded: LiveRecording?
    @State private var tracks: [LiveRecordingTrack] = []
    @State private var isLoadingRecordings = false
    @State private var isLoadingTracks = false
    @State private var loadError: String?

    var body: some View {
        Group {
            if isLoadingRecordings && recordings.isEmpty {
                EmptyView()
            } else if !recordings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Owned here rather than by the caller so an artist with
                    // no recordings gets no divider either.
                    Divider().background(Color.Theme.borderDefault)

                    Text("Live Recordings")
                        .font(.headline)
                        .foregroundStyle(Color.Theme.textPrimary)

                    ForEach(recordings) { recording in
                        recordingRow(recording)
                    }

                    if let loadError {
                        Text(loadError)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .task(id: artistId) { await loadRecordings() }
    }

    @ViewBuilder
    private func recordingRow(_ recording: LiveRecording) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await toggle(recording) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: expanded == recording ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .frame(width: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recording.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.Theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if !recording.subtitle.isEmpty {
                            Text(recording.subtitle)
                                .font(.caption2)
                                .foregroundStyle(Color.Theme.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if isLoadingTracks && expanded == recording {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.Theme.accent)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .buttonStyle(.plain)

            if expanded == recording, !tracks.isEmpty {
                // Playing any track queues the whole set from that point, so
                // a concert runs on rather than stopping after one song.
                ForEach(tracks) { track in
                    trackRow(track, in: recording)
                }
            }
        }
        .padding(.vertical, 6)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.Theme.borderDefault),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private func trackRow(_ track: LiveRecordingTrack, in recording: LiveRecording) -> some View {
        let trackId = "live-\(recording.recordingId)-\(track.trackIndex)"
        let isActive = audioPlayer.currentTrack?.id == trackId

        Button {
            Task { await play(from: track, in: recording) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isActive
                      ? (audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                      : "play.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.accent)

                Text(track.title)
                    .font(.caption)
                    .foregroundStyle(isActive ? Color.Theme.accent : Color.Theme.textSecondary)
                    .lineLimit(1)

                Spacer()

                if let length = track.length, !length.isEmpty {
                    Text(length)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
            .padding(.leading, 20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadRecordings() async {
        guard recordings.isEmpty else { return }
        isLoadingRecordings = true
        defer { isLoadingRecordings = false }
        do {
            recordings = try await APIClient.shared.request(
                endpoint: .liveRecordings(artistId: artistId)
            )
        } catch {
            // Silent: most artists have no recordings, and a failure here
            // shouldn't put an error on an artist page that otherwise works.
            recordings = []
        }
    }

    private func toggle(_ recording: LiveRecording) async {
        if expanded == recording {
            expanded = nil
            tracks = []
            return
        }
        expanded = recording
        tracks = []
        loadError = nil
        isLoadingTracks = true
        defer { isLoadingTracks = false }
        do {
            let response: LiveRecordingTracksResponse = try await APIClient.shared.request(
                endpoint: .liveRecordingTracks(recordingId: recording.recordingId)
            )
            tracks = response.tracks
            if tracks.isEmpty {
                loadError = "No playable audio on this recording."
            }
        } catch {
            loadError = "Couldn't load this recording."
        }
    }

    private func play(from track: LiveRecordingTrack, in recording: LiveRecording) async {
        let trackId = "live-\(recording.recordingId)-\(track.trackIndex)"
        if audioPlayer.currentTrack?.id == trackId {
            audioPlayer.togglePlayPause()
            return
        }
        // Queue the full set and start where they tapped — the point of
        // queue support is that a bootleg plays through unattended.
        let queue = tracks.compactMap { $0.nowPlayingTrack(recording: recording) }
        guard let startIndex = tracks.firstIndex(of: track) else { return }
        await audioPlayer.play(queue: queue, startIndex: startIndex)
    }
}
