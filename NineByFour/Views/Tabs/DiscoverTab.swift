import SwiftUI

struct DiscoverTab: View {
    @State private var viewModel = DiscoverViewModel()
    @State private var selectedVideoId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Section", selection: $viewModel.selectedSection) {
                        ForEach(DiscoverSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    switch viewModel.selectedSection {
                    case .videos:
                        if viewModel.isLoading {
                            LoadingStateView()
                        } else if let error = viewModel.errorMessage {
                            ErrorStateView(message: error) {
                                Task { await viewModel.loadVideos() }
                            }
                        } else {
                            videosSection
                        }
                    case .releases:
                        if viewModel.isLoading {
                            LoadingStateView()
                        } else if let error = viewModel.errorMessage {
                            ErrorStateView(message: error) {
                                Task { await viewModel.loadUpcomingReleases() }
                            }
                        } else {
                            releasesSection
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: Binding(
                get: { selectedVideoId.map { VideoSheetItem(videoId: $0) } },
                set: { selectedVideoId = $0?.videoId }
            )) { item in
                NavigationStack {
                    YouTubePlayerView(videoId: item.videoId)
                        .ignoresSafeArea()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    selectedVideoId = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.Theme.textSecondary)
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .task {
            await viewModel.loadAll()
        }
    }

    // MARK: - Videos Section

    private var videosSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.videos) { video in
                    VideoCard(video: video) {
                        selectedVideoId = video.youtubeId
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .refreshable {
            await viewModel.loadVideos()
        }
    }

    // MARK: - Releases Section

    private var releasesSection: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.upcomingReleases) { release in
                    UpcomingReleaseCard(release: release)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .refreshable {
            await viewModel.loadUpcomingReleases()
        }
    }
}

private struct VideoSheetItem: Identifiable {
    let videoId: String
    var id: String { videoId }
}
