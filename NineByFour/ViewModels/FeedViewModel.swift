import Foundation
import Observation

@Observable
final class FeedViewModel {
    var posts: [FeedPost] = []
    var isLoading = false
    var errorMessage: String?
    var newPostContent = ""

    // Music post creation state
    var musicTitle = ""
    var musicStreamUrl = ""
    var musicCaption = ""

    // Video post creation state
    var videoTitle = ""
    var videoCaption = ""
    var isMusicVideo = false
    var isPostingVideo = false

    @MainActor
    func loadFeed() async {
        isLoading = true
        errorMessage = nil

        do {
            posts = try await APIClient.shared.request(endpoint: .feed)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load feed."
        }

        isLoading = false
    }

    @MainActor
    func createTextPost() async -> Bool {
        guard !newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        do {
            let body = TextPostBody(content: newPostContent)
            let _: FeedPost = try await APIClient.shared.request(
                endpoint: .feedText,
                body: body
            )
            newPostContent = ""
            await loadFeed()
            return true
        } catch {
            errorMessage = "Failed to create post."
            return false
        }
    }

    @MainActor
    func createMusicPost() async -> Bool {
        let trimmedUrl = musicStreamUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty else { return false }

        do {
            let body = MusicPostBody(
                streamUrl: trimmedUrl,
                title: musicTitle.isEmpty ? nil : musicTitle,
                caption: musicCaption.isEmpty ? nil : musicCaption
            )
            let _: FeedPost = try await APIClient.shared.request(
                endpoint: .feedMusic,
                body: body
            )
            musicTitle = ""
            musicStreamUrl = ""
            musicCaption = ""
            await loadFeed()
            return true
        } catch {
            errorMessage = "Failed to share music."
            return false
        }
    }

    /// Uploads a video file. Re-encodes it to MP4 first (see VideoExport),
    /// so the file sent is always H.264 regardless of what the camera wrote.
    @MainActor
    func createVideoPost(fileURL: URL) async -> Bool {
        isPostingVideo = true
        errorMessage = nil
        defer { isPostingVideo = false }

        do {
            let mp4 = try await VideoExport.mp4(from: fileURL)
            defer { try? FileManager.default.removeItem(at: mp4) }
            let data = try Data(contentsOf: mp4)

            var formData = MultipartFormData()
            formData.addFile(named: "video", fileName: "video.mp4", mimeType: "video/mp4", data: data)
            let title = videoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { formData.addField(named: "title", value: String(title.prefix(120))) }
            let caption = videoCaption.trimmingCharacters(in: .whitespacesAndNewlines)
            if !caption.isEmpty { formData.addField(named: "caption", value: caption) }
            formData.addField(named: "content_type", value: isMusicVideo ? "Music Video" : "Video")

            let _: UploadedPost = try await APIClient.shared.upload(endpoint: .feedVideo, formData: formData)
            videoTitle = ""
            videoCaption = ""
            isMusicVideo = false
            await loadFeed()
            return true
        } catch let error as VideoExportError {
            errorMessage = error.errorDescription
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Failed to post video."
        } catch {
            errorMessage = "Failed to post video."
        }
        return false
    }

    @MainActor
    /// Drops every post by a blocked user from the in-memory feed.
    ///
    /// The server already filters them, but only on the next fetch. Leaving
    /// the posts on screen until a refresh reads as the block having failed,
    /// which is the worst possible impression for a control someone reaches
    /// for when they are upset.
    func removePosts(byUserId userId: Int) {
        posts.removeAll { $0.userId == userId }
    }

    func deletePost(type: String, id: Int) async {
        do {
            try await APIClient.shared.requestVoid(endpoint: .deleteFeedPost(type: type, id: id))
            posts.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete post."
        }
    }
}

/// The upload's response is only checked for success; the feed reloads after.
private struct UploadedPost: Decodable {}

private struct TextPostBody: Encodable {
    let content: String
}

private struct MusicPostBody: Encodable {
    let streamUrl: String
    let title: String?
    let caption: String?

    enum CodingKeys: String, CodingKey {
        case streamUrl = "streamUrl"
        case title
        case caption
    }
}
