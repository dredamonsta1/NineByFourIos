import Foundation
import AVFoundation
import MediaPlayer
import Observation

@Observable
@MainActor
final class AudioPlayer {
    // MARK: - Published state

    private(set) var currentTrack: NowPlayingTrack?
    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var fftBars: [Float] = Array(repeating: 0, count: FFTAnalyzer.barCount)
    private(set) var errorMessage: String?

    // MARK: - Private

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var downloadTask: URLSessionDataTask?
    private var cachedFile: URL?
    private let fft = FFTAnalyzer()
    private var didConfigureSession = false

    init() {
        engine.attach(playerNode)
        configureRemoteCommands()
    }

    // MARK: - Public API

    // Convenience for the feed path. Builds a NowPlayingTrack from a
    // music FeedPost and hands off. No-op if the post has no audioUrl.
    func play(post: FeedPost) async {
        guard let track = post.nowPlayingTrack else {
            errorMessage = "This post has no playable audio."
            return
        }
        await play(track: track)
    }

    // Canonical playback entry point. All sources (feed music post, library
    // album, preview clip) route through here.
    func play(track: NowPlayingTrack) async {
        await stop()

        isLoading = true
        errorMessage = nil
        currentTrack = track

        do {
            let localURL = try await download(track.audioUrl)
            cachedFile = localURL
            try configureSessionIfNeeded()
            try startPlayback(of: localURL)
            isPlaying = true
            updateNowPlaying()
        } catch {
            errorMessage = "Could not play this track."
            currentTrack = nil
        }

        isLoading = false
    }

    func togglePlayPause() {
        guard currentTrack != nil else { return }
        if isPlaying {
            playerNode.pause()
            isPlaying = false
        } else {
            do {
                if !engine.isRunning { try engine.start() }
                playerNode.play()
                isPlaying = true
            } catch {
                errorMessage = "Could not resume playback."
            }
        }
        updateNowPlaying()
    }

    func stop() async {
        downloadTask?.cancel()
        downloadTask = nil
        if playerNode.isPlaying { playerNode.stop() }
        playerNode.reset()
        if engine.isRunning {
            playerNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioFile = nil
        if let cachedFile { try? FileManager.default.removeItem(at: cachedFile) }
        cachedFile = nil
        currentTrack = nil
        isPlaying = false
        fftBars = Array(repeating: 0, count: FFTAnalyzer.barCount)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Download

    private func download(_ url: URL) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let dest = tempDir.appendingPathComponent("stanbox-\(UUID().uuidString)-\(url.lastPathComponent)")

        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                do {
                    try data.write(to: dest)
                    continuation.resume(returning: dest)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            self.downloadTask = task
            task.resume()
        }
    }

    // MARK: - Engine + playback

    private func configureSessionIfNeeded() throws {
        guard !didConfigureSession else { return }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        didConfigureSession = true
    }

    private func startPlayback(of url: URL) throws {
        let file = try AVAudioFile(forReading: url)
        self.audioFile = file

        let format = file.processingFormat
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        // Install FFT tap. The tap fires on a high-priority audio thread,
        // so we hop back to the main actor for the @Observable assignment.
        playerNode.removeTap(onBus: 0)
        playerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let bars = self.fft.analyze(buffer: buffer)
            Task { @MainActor [weak self] in
                self?.fftBars = bars
            }
        }

        try engine.start()
        playerNode.scheduleFile(file, at: nil) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handlePlaybackFinished()
            }
        }
        playerNode.play()
    }

    private func handlePlaybackFinished() async {
        // Only treat as finished if we were the active player (avoid race
        // with a user-initiated stop()).
        guard isPlaying else { return }
        await stop()
    }

    // MARK: - Now Playing

    private func updateNowPlaying() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = track.title
        info[MPMediaItemPropertyArtist] = track.subtitle ?? ""
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func configureRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.togglePlayPause() }
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.togglePlayPause() }
            return .success
        }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.togglePlayPause() }
            return .success
        }
    }
}
