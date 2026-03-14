import SwiftUI

struct DiscoverTab: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = DiscoverViewModel()
    @State private var eventsViewModel = EventsViewModel()
    @State private var selectedVideoId: String?
    @State private var showEventCreator = false

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
                    case .events:
                        if eventsViewModel.isLoading && eventsViewModel.events.isEmpty {
                            LoadingStateView()
                        } else if let error = eventsViewModel.errorMessage, eventsViewModel.events.isEmpty {
                            ErrorStateView(message: error) {
                                Task { await eventsViewModel.loadEvents() }
                            }
                        } else {
                            eventsSection
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if viewModel.selectedSection == .events && authManager.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showEventCreator = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.Theme.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEventCreator) {
                EventCreatorView(viewModel: eventsViewModel)
            }
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
        .onChange(of: viewModel.selectedSection) { _, newSection in
            if newSection == .events && eventsViewModel.events.isEmpty {
                Task { await eventsViewModel.loadEvents() }
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

    // MARK: - Events Section

    private var eventsSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if eventsViewModel.events.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text("No upcoming events")
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(eventsViewModel.events) { event in
                        EventCard(
                            event: event,
                            currentUserId: authManager.currentUser?.id
                        ) {
                            Task { await eventsViewModel.deleteEvent(id: event.id) }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .refreshable {
            await eventsViewModel.loadEvents()
        }
    }
}

private struct VideoSheetItem: Identifiable {
    let videoId: String
    var id: String { videoId }
}
