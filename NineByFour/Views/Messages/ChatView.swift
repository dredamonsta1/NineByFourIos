import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ChatViewModel()

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    LoadingStateView()
                } else {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                if viewModel.hasMore {
                                    Button("Load earlier messages") {
                                        Task { await viewModel.loadMore(conversationId: conversation.conversationId) }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(Color.Theme.accent)
                                    .padding(.top, 8)
                                }

                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        isSent: message.senderId == authManager.currentUser?.id
                                    )
                                    .id(message.messageId)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let lastId = viewModel.messages.last?.messageId {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.Theme.borderDefault)

                    // Input bar
                    HStack(spacing: 10) {
                        TextField("Message...", text: $viewModel.newMessageText)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color.Theme.bgInput)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
                            )
                            .foregroundStyle(Color.Theme.textPrimary)

                        Button {
                            Task {
                                await viewModel.sendMessage(conversationId: conversation.conversationId)
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color.Theme.textSecondary
                                    : Color.Theme.accent
                                )
                        }
                        .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.Theme.bgSurface)
                }
            }
        }
        .navigationTitle(conversation.otherUsername ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadMessages(conversationId: conversation.conversationId)
            await viewModel.markAsRead(conversationId: conversation.conversationId)
            viewModel.startPolling(conversationId: conversation.conversationId)
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
}
