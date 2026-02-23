import SwiftUI

struct DiscoverTab: View {
    @State private var viewModel = DiscoverViewModel()
    @State private var selectedVideoId: String?
    @State private var searchDebounce: Task<Void, Never>?

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
                    case .artists:
                        artistsSection
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

    // MARK: - Artists Section

    private var artistsSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                SearchBar(text: $viewModel.searchText, placeholder: "Search for an artist...")
                    .padding(.horizontal, 16)
                    .onChange(of: viewModel.searchText) { _, newValue in
                        searchDebounce?.cancel()
                        searchDebounce = Task {
                            try? await Task.sleep(for: .milliseconds(400))
                            guard !Task.isCancelled else { return }
                            await viewModel.searchArtists()
                        }
                    }

                Text("\(viewModel.profileListCount)/20 artists in your list")
                    .font(.caption)
                    .foregroundStyle(Color.Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)

            if viewModel.searchLoading {
                LoadingStateView()
            } else if viewModel.searchText.isEmpty {
                Spacer()
                Text("Search for artists to add to your list")
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.textSecondary)
                Spacer()
            } else if viewModel.searchResults.isEmpty {
                Spacer()
                Text("No artists found")
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.textSecondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.searchResults) { artist in
                            ArtistSearchRow(
                                artist: artist,
                                isAdded: viewModel.profileListIds.contains(artist.artistId),
                                isListFull: viewModel.isListFull
                            ) {
                                Task { await viewModel.addToProfileList(artist: artist) }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
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
