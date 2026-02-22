import SwiftUI

struct FeedTab: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = FeedViewModel()
    @State private var showPostCreator = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if !authManager.isAuthenticated {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text("Login to view your feed")
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                } else if viewModel.isLoading && viewModel.posts.isEmpty {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage, viewModel.posts.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.loadFeed() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.posts) { post in
                                FeedPostCard(
                                    post: post,
                                    currentUserId: authManager.currentUser?.id
                                ) {
                                    Task {
                                        await viewModel.deletePost(
                                            type: post.postType.rawValue,
                                            id: post.id
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
            }
            .navigationTitle("Feed")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if authManager.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showPostCreator = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.Theme.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showPostCreator) {
                PostCreatorView(viewModel: viewModel)
            }
        }
        .task {
            if authManager.isAuthenticated && viewModel.posts.isEmpty {
                await viewModel.loadFeed()
            }
        }
    }
}
