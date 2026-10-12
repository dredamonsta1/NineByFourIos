import PhotosUI
import SwiftUI

private enum CreatorTab: String, CaseIterable {
    case text = "Text"
    case video = "Video"
    case music = "Music"
}

struct PostCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: FeedViewModel
    @State private var selectedTab: CreatorTab = .text
    @State private var pickedVideo: PhotosPickerItem?
    @State private var videoURL: URL?
    @State private var isLoadingVideo = false
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                VStack(spacing: 16) {
                    Picker("Post type", selection: $selectedTab) {
                        ForEach(CreatorTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedTab {
                    case .text:
                        textPostForm
                    case .video:
                        videoPostForm
                    case .music:
                        musicPostForm
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onDisappear { discardVideo() }
            .fullScreenCover(isPresented: $showCamera) {
                CameraRecorder(
                    maxDuration: viewModel.isMusicVideo ? VideoRecordLimit.musicVideo : VideoRecordLimit.regular
                ) { url in
                    showCamera = false
                    if let url { replaceVideo(with: url) }
                }
                .ignoresSafeArea()
            }
            .onChange(of: pickedVideo) { _, item in
                guard let item else { return }
                Task { await loadPickedVideo(item) }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Text Post Form

    private var textPostForm: some View {
        VStack(spacing: 12) {
            TextEditor(text: $viewModel.newPostContent)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color.Theme.textPrimary)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )
                .frame(minHeight: 120)

            Button {
                Task {
                    let success = await viewModel.createTextPost()
                    if success { dismiss() }
                }
            } label: {
                Text("Post")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.Theme.contrast)
                    .foregroundStyle(Color.Theme.bgBase)
                    .cornerRadius(8)
            }
            .disabled(viewModel.newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Video Post Form

    private var videoPostForm: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let videoURL {
                    PlatformVideoPlayer(url: videoURL)
                        .id(videoURL)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .background(Color.black)
                        .cornerRadius(10)

                    Button("Remove video", role: .destructive) { discardVideo() }
                        .font(.subheadline)
                        .disabled(viewModel.isPostingVideo)
                } else if isLoadingVideo {
                    ProgressView("Loading video…")
                        .tint(Color.Theme.textSecondary)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    videoSourceButtons
                }

                Toggle("Music video", isOn: $viewModel.isMusicVideo)
                    .foregroundStyle(Color.Theme.textPrimary)
                    .tint(Color.Theme.contrast)
                    .padding(.horizontal, 4)

                TextField("Title (optional)", text: $viewModel.videoTitle)
                    .foregroundStyle(Color.Theme.textPrimary)
                    .padding(12)
                    .background(Color.Theme.bgInput)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.Theme.borderDefault, lineWidth: 1)
                    )

                TextField("Caption (optional)", text: $viewModel.videoCaption)
                    .foregroundStyle(Color.Theme.textPrimary)
                    .padding(12)
                    .background(Color.Theme.bgInput)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.Theme.borderDefault, lineWidth: 1)
                    )

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    guard let videoURL else { return }
                    Task {
                        let success = await viewModel.createVideoPost(fileURL: videoURL)
                        if success { dismiss() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isPostingVideo {
                            ProgressView().tint(Color.Theme.bgBase)
                        }
                        Text(viewModel.isPostingVideo ? "Uploading…" : "Post Video")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.Theme.contrast)
                    .foregroundStyle(Color.Theme.bgBase)
                    .cornerRadius(8)
                }
                .disabled(videoURL == nil || viewModel.isPostingVideo)
            }
        }
    }

    private var videoSourceButtons: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $pickedVideo, matching: .videos) {
                Label("Choose video", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
            .buttonStyle(VideoSourceButtonStyle())

            if CameraRecorder.isAvailable {
                Button {
                    viewModel.errorMessage = nil
                    showCamera = true
                } label: {
                    Label("Record", systemImage: "video")
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
                .buttonStyle(VideoSourceButtonStyle())
            }
        }
    }

    private func loadPickedVideo(_ item: PhotosPickerItem) async {
        isLoadingVideo = true
        viewModel.errorMessage = nil
        defer {
            isLoadingVideo = false
            pickedVideo = nil
        }
        do {
            guard let movie = try await item.loadTransferable(type: PickedMovie.self) else {
                viewModel.errorMessage = "Couldn't load that video."
                return
            }
            replaceVideo(with: movie.url)
        } catch {
            viewModel.errorMessage = "Couldn't load that video."
        }
    }

    private func replaceVideo(with url: URL) {
        discardVideo()
        viewModel.errorMessage = nil
        videoURL = url
    }

    /// Picked and recorded files are temp copies; delete them when done.
    private func discardVideo() {
        if let videoURL { try? FileManager.default.removeItem(at: videoURL) }
        videoURL = nil
    }

    // MARK: - Music Post Form

    private var musicPostForm: some View {
        VStack(spacing: 12) {
            TextField("Title (optional)", text: $viewModel.musicTitle)
                .foregroundStyle(Color.Theme.textPrimary)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )

            TextField("Spotify / SoundCloud / Apple Music link", text: $viewModel.musicStreamUrl)
                .foregroundStyle(Color.Theme.textPrimary)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )

            TextField("Caption (optional)", text: $viewModel.musicCaption)
                .foregroundStyle(Color.Theme.textPrimary)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )

            Button {
                Task {
                    let success = await viewModel.createMusicPost()
                    if success { dismiss() }
                }
            } label: {
                Text("Share Music")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.Theme.contrast)
                    .foregroundStyle(Color.Theme.bgBase)
                    .cornerRadius(8)
            }
            .disabled(viewModel.musicStreamUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

private struct VideoSourceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.Theme.textPrimary)
            .background(Color.Theme.bgInput)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
