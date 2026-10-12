import SwiftUI

struct DiscoverTab: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = DiscoverViewModel()
    @State private var eventsViewModel = EventsViewModel()
    @State private var selectedVideo: PlatformVideo?
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
                                Task { await viewModel.loadVideos(isAuthenticated: authManager.isAuthenticated) }
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
            .brandedNavBar()
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
            .sheet(item: $selectedVideo) { video in
                NavigationStack {
                    Group {
                        if let url = video.playURL {
                            // Opened by a tap, so playing straight away is expected.
                            PlatformVideoPlayer(url: url, autoplay: true)
                        } else {
                            ErrorStateView(message: "This video can't be played.") { selectedVideo = nil }
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle(video.displayTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                selectedVideo = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.Theme.textSecondary)
                            }
                            .accessibilityLabel("Close")
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .task {
            await viewModel.loadAll(isAuthenticated: authManager.isAuthenticated)
        }
        .onChange(of: viewModel.videoTab) { _, _ in
            Task { await viewModel.loadVideos(isAuthenticated: authManager.isAuthenticated) }
        }
        .onChange(of: viewModel.musicOnly) { _, _ in
            Task { await viewModel.loadVideos(isAuthenticated: authManager.isAuthenticated) }
        }
        .onChange(of: viewModel.selectedSection) { _, newSection in
            if newSection == .events && eventsViewModel.events.isEmpty {
                Task { await eventsViewModel.loadEvents() }
            }
        }
    }

    // MARK: - Videos Section

    private var videosSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Whose videos", selection: $viewModel.videoTab) {
                    ForEach(VideoTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    viewModel.musicOnly.toggle()
                } label: {
                    Text("Music videos")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(viewModel.musicOnly ? Color.Theme.textPrimary : Color.Theme.textSecondary)
                        .background(viewModel.musicOnly ? Color.Theme.accent.opacity(0.25) : Color.clear)
                        .overlay(Capsule().stroke(viewModel.musicOnly ? Color.Theme.accent : Color.Theme.borderDefault, lineWidth: 1))
                        .clipShape(Capsule())
                }
                .accessibilityAddTraits(viewModel.musicOnly ? .isSelected : [])
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if viewModel.videosNeedSignIn {
                emptyVideos("Log in to see videos from people you follow.")
            } else if viewModel.videos.isEmpty {
                emptyVideos(viewModel.videoTab == .following
                    ? "No videos from people you follow yet."
                    : viewModel.musicOnly ? "No music videos yet." : "No videos yet.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.videos) { video in
                            VideoCard(video: video) {
                                selectedVideo = video
                            }
                            .onAppear {
                                if video.id == viewModel.videos.last?.id {
                                    Task { await viewModel.loadMoreVideos() }
                                }
                            }
                        }
                        if viewModel.isLoadingMore {
                            ProgressView().padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .refreshable {
                    await viewModel.loadVideos(isAuthenticated: authManager.isAuthenticated)
                }
            }
        }
    }

    private func emptyVideos(_ message: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "play.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.Theme.textSecondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
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
