import Foundation

/// An Internet Archive bootleg concert.
///
/// These are the only audio a brand-new user can reach without buying
/// anything: the Library needs a purchase and album previews need audio
/// uploaded to Cloudinary, but recordings are free Archive.org streams and
/// roughly 200 catalog artists already have them.
struct LiveRecording: Identifiable, Codable, Sendable, Hashable {
    let recordingId: Int
    let artistName: String
    let title: String
    let venue: String?
    let city: String?
    let recordedDate: String?

    var id: Int { recordingId }

    enum CodingKeys: String, CodingKey {
        case recordingId = "recording_id"
        case artistName = "artist_name"
        case title
        case venue
        case city
        case recordedDate = "recorded_date"
    }

    /// "Aug 1991 · The Palace, Los Angeles" — whatever of that we actually
    /// have. Archive metadata is patchy, so every part is optional.
    var subtitle: String {
        var parts: [String] = []
        if let date = formattedDate { parts.append(date) }
        let place = [venue, city].compactMap { $0 }.filter { !$0.isEmpty }
        if !place.isEmpty { parts.append(place.joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }

    private var formattedDate: String? {
        guard let recordedDate, !recordedDate.isEmpty else { return nil }
        // Backend sends a DATE, which serialises as either "1991-08-17" or a
        // full ISO timestamp depending on the driver — take the day part.
        let day = String(recordedDate.prefix(10))
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.timeZone = TimeZone(identifier: "UTC")
        guard let date = parser.date(from: day) else { return day }
        let out = DateFormatter()
        out.dateFormat = "MMM yyyy"
        return out.string(from: date)
    }
}

/// One track within a recording. Lives only in Archive.org metadata — there
/// is no row for it in our database, which is why comments on these anchor
/// on (recording, index) rather than a track id.
struct LiveRecordingTrack: Identifiable, Codable, Sendable, Hashable {
    let trackIndex: Int
    let title: String
    let streamUrl: String
    let length: String?

    var id: Int { trackIndex }

    enum CodingKeys: String, CodingKey {
        case trackIndex = "track_index"
        case title
        case streamUrl = "stream_url"
        case length
    }
}

struct LiveRecordingTracksResponse: Codable, Sendable {
    let artistName: String?
    let title: String?
    let tracks: [LiveRecordingTrack]

    enum CodingKeys: String, CodingKey {
        case artistName = "artist_name"
        case title
        case tracks
    }
}

extension LiveRecordingTrack {
    /// Bridges an Archive track into the shared player. The id convention
    /// matches the existing `feed-post-<id>` / `album-<id>` scheme so views
    /// can ask "is the player playing me?" without knowing the source type.
    func nowPlayingTrack(recording: LiveRecording) -> NowPlayingTrack? {
        guard let url = URL(string: streamUrl) else { return nil }
        return NowPlayingTrack(
            id: "live-\(recording.recordingId)-\(trackIndex)",
            title: title,
            subtitle: recording.artistName,
            artworkUrl: nil,
            audioUrl: url
        )
    }
}
