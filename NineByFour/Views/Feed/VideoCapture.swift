import AVFoundation
import CoreTransferable
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Same ceiling as the web upload modal. The backend accepts 100 MB, but a
/// phone upload that size on cellular mostly ends in a timeout.
nonisolated let maxVideoUploadBytes = 50 * 1024 * 1024

/// Recording limits, matching the web recorder: a music video gets longer.
nonisolated enum VideoRecordLimit {
    static let regular: TimeInterval = 60
    static let musicVideo: TimeInterval = 100
}

/// A movie from the photo library, copied somewhere we own. The picker's
/// file is deleted as soon as the import closure returns.
nonisolated struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return PickedMovie(url: copy)
        }
    }
}

nonisolated enum VideoExportError: LocalizedError {
    case failed
    case tooLarge

    var errorDescription: String? {
        switch self {
        case .failed: return "Couldn't prepare that video. Try another one."
        case .tooLarge: return "That video is over 50 MB, even compressed. Try a shorter clip."
        }
    }
}

/// Re-encodes a video to H.264 MP4 so every browser can play it and the
/// upload stays small. iPhones record HEVC .mov by default, which Chrome
/// and Firefox can't decode. Tries 720p first, then 540p if 720p is still
/// over the limit.
nonisolated enum VideoExport {
    static func mp4(from source: URL) async throws -> URL {
        for preset in [AVAssetExportPreset1280x720, AVAssetExportPreset960x540] {
            let output = try await export(source, preset: preset)
            let size = (try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? .max
            if size <= maxVideoUploadBytes { return output }
            try? FileManager.default.removeItem(at: output)
        }
        throw VideoExportError.tooLarge
    }

    private static func export(_ source: URL, preset: String) async throws -> URL {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw VideoExportError.failed
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        session.shouldOptimizeForNetworkUse = true

        if #available(iOS 18, *) {
            do {
                try await session.export(to: output, as: .mp4)
            } catch {
                throw VideoExportError.failed
            }
        } else {
            session.outputURL = output
            session.outputFileType = .mp4
            nonisolated(unsafe) let legacy = session
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                legacy.exportAsynchronously { done.resume() }
            }
            guard legacy.status == .completed else { throw VideoExportError.failed }
        }
        return output
    }
}

/// The system camera, in video mode. Reports the recorded file, or nil on cancel.
struct CameraRecorder: UIViewControllerRepresentable {
    let maxDuration: TimeInterval
    let onFinish: (URL?) -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.cameraCaptureMode = .video
        picker.videoMaximumDuration = maxDuration
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (URL?) -> Void

        init(onFinish: @escaping (URL?) -> Void) { self.onFinish = onFinish }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onFinish(info[.mediaURL] as? URL)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}
