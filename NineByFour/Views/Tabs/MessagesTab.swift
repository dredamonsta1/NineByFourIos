import SwiftUI

struct MessagesTab: View {
    @Environment(AuthManager.self) private var authManager
    @Bindable var viewModel: MessagesViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if !authManager.isAuthenticated {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text("Login to view messages")
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                } else if viewModel.isLoading && viewModel.conversations.isEmpty {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage, viewModel.conversations.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.loadConversations() }
                    }
                } else if viewModel.conversations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text("No conversations yet")
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.conversations) { conversation in
                                NavigationLink {
                                    ChatView(conversation: conversation)
                                } label: {
                                    ConversationRow(conversation: conversation)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .refreshable {
                        await viewModel.loadConversations()
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            if authManager.isAuthenticated {
                await viewModel.loadConversations()
                await viewModel.loadUnreadCount()
                viewModel.startPolling()
            }
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
}
