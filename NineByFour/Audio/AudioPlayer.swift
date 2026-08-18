import Foundation
import AVFoundation
import MediaPlayer
import Observation

@Observable
@MainActor
final class AudioPlayer {
    // MARK: - Published state

    private(set) var currentTrack: NowPlayingTrack?
    /// The set being played through. A single track is a queue of one, so
    /// every source routes through the same path.
    private(set) var queue: [NowPlayingTrack] = []
    private(set) var queueIndex = 0
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
    /// Bumped on every track change. scheduleFile's completion handler fires
    /// both when a file plays out AND when the node is reset — so skipping
    /// or stopping would otherwise look identical to "track finished" and
    /// advance the queue a second time. The handler captures the generation
    /// it was scheduled under and does nothing if it's no longer current.
    private var playbackGeneration = 0

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

    // Canonical single-track entry point. All sources (feed music post,
    // library album, preview clip) route through here. A lone track is a
    // queue of one so there's only one playback path to reason about.
    func play(track: NowPlayingTrack) async {
        await play(queue: [track], startIndex: 0)
    }

    /// Play a set, e.g. every track of a live concert. Out-of-range start
    /// indices are clamped rather than rejected — a caller shouldn't have to
    /// know how long the set is.
    func play(queue tracks: [NowPlayingTrack], startIndex: Int = 0) async {
        guard !tracks.isEmpty else {
            errorMessage = "Nothing to play."
            return
        }
        await stop()
        queue = tracks
        queueIndex = min(max(0, startIndex), tracks.count - 1)
        await playCurrent()
    }

    var hasNext: Bool { queueIndex + 1 < queue.count }
    var hasPrevious: Bool { queueIndex > 0 }

    func next() async {
        guard hasNext else { return }
        queueIndex += 1
        await playCurrent()
    }

    func previous() async {
        guard hasPrevious else { return }
        queueIndex -= 1
        await playCurrent()
    }

    /// Plays whatever `queueIndex` points at, leaving the queue intact —
    /// unlike stop(), which clears it. Track changes go through here.
    private func playCurrent() async {
        guard queue.indices.contains(queueIndex) else { return }
        let track = queue[queueIndex]

        await teardownAudio()

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
        await teardownAudio()
        queue = []
        queueIndex = 0
        currentTrack = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Tears the audio graph down without touching the queue.
    private func teardownAudio() async {
        playbackGeneration += 1
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
        isPlaying = false
        fftBars = Array(repeating: 0, count: FFTAnalyzer.barCount)
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
        let generation = playbackGeneration
        playerNode.scheduleFile(file, at: nil) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handlePlaybackFinished(generation: generation)
            }
        }
        playerNode.play()
    }

    private func handlePlaybackFinished(generation: Int) async {
        // A reset fires this handler too, so a skip or a stop would look
        // exactly like a natural end and advance the queue again. Ignore
        // anything scheduled under a superseded generation.
        guard generation == playbackGeneration else { return }
        guard isPlaying else { return }

        if hasNext {
            await next()
        } else {
            await stop()
        }
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
        cc.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in await self?.next() }
            return .success
        }
        cc.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in await self?.previous() }
            return .success
        }
    }
}
