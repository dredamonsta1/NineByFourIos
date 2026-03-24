import SwiftUI

struct ProfileTab: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ProfileViewModel()
    @State private var showImagePicker = false
    @State private var showFollowers = false
    @State private var showFollowing = false
    @State private var searchDebounce: Task<Void, Never>?
    @State private var creatorTier: String? = nil // nil = loading

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if !authManager.isAuthenticated {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text("Login to view your profile")
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile header
                            VStack(spacing: 12) {
                                Button {
                                    showImagePicker = true
                                } label: {
                                    if let imageUrl = authManager.currentUser?.profileImage, !imageUrl.isEmpty {
                                        CachedAsyncImage(url: imageUrl.fullImageURL, cornerRadius: 45)
                                            .frame(width: 90, height: 90)
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundStyle(Color.Theme.textSecondary)
                                    }
                                }

                                Text(authManager.currentUser?.username ?? "")
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.Theme.textBright)

                                if let email = authManager.currentUser?.email, !email.isEmpty {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundStyle(Color.Theme.textSecondary)
                                }
                            }
                            .padding(.top, 8)

                            // Stats row
                            HStack(spacing: 32) {
                                Button {
                                    showFollowers = true
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(viewModel.followers.count)")
                                            .font(.headline)
                                            .foregroundStyle(Color.Theme.textBright)
                                        Text("Followers")
                                            .font(.caption)
                                            .foregroundStyle(Color.Theme.textSecondary)
                                    }
                                }

                                Button {
                                    showFollowing = true
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(viewModel.following.count)")
                                            .font(.headline)
                                            .foregroundStyle(Color.Theme.textBright)
                                        Text("Following")
                                            .font(.caption)
                                            .foregroundStyle(Color.Theme.textSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.Theme.bgCard)
                            .cornerRadius(12)

                            // Creator tier card
                            creatorTierCard

                            // My List section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("My List")
                                    .font(.headline)
                                    .foregroundStyle(Color.Theme.textPrimary)

                                // Artist search
                                VStack(spacing: 6) {
                                    SearchBar(text: $viewModel.searchText, placeholder: "Search for an artist...")
                                        .onChange(of: viewModel.searchText) { _, _ in
                                            searchDebounce?.cancel()
                                            searchDebounce = Task {
                                                try? await Task.sleep(for: .milliseconds(400))
                                                guard !Task.isCancelled else { return }
                                                await viewModel.searchArtists()
                                            }
                                        }

                                    Text("\(viewModel.profileList.count)/20 artists in your list")
                                        .font(.caption)
                                        .foregroundStyle(Color.Theme.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                // Show search results when searching, otherwise show saved list
                                if viewModel.searchLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                } else if !viewModel.searchText.isEmpty {
                                    if viewModel.searchResults.isEmpty {
                                        Text("No artists found")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.Theme.textSecondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.vertical, 8)
                                    } else {
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
                                    }
                                } else if viewModel.profileList.isEmpty {
                                    Text("No artists in your list yet")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.Theme.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 20)
                                } else {
                                    LazyVStack(spacing: 8) {
                                        ForEach(viewModel.profileList) { artist in
                                            FavoriteArtistRow(artist: artist) {
                                                Task {
                                                    await viewModel.removeFromProfileList(artistId: artist.artistId)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Similar taste suggestions
                            if !viewModel.tasteSuggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("People with similar taste")
                                        .font(.headline)
                                        .foregroundStyle(Color.Theme.textPrimary)

                                    LazyVStack(spacing: 8) {
                                        ForEach(viewModel.tasteSuggestions) { suggestion in
                                            SuggestionRow(suggestion: suggestion)
                                        }
                                    }
                                }
                            }

                            // Logout button
                            Button {
                                authManager.logout()
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.Theme.error.opacity(0.15))
                                .foregroundStyle(Color.Theme.error)
                                .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        await loadProfileData()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView { newImageUrl in
                    authManager.currentUser?.profileImage = newImageUrl
                }
            }
            .sheet(isPresented: $showFollowers) {
                followListSheet(title: "Followers", users: viewModel.followers)
            }
            .sheet(isPresented: $showFollowing) {
                followListSheet(title: "Following", users: viewModel.following)
            }
        }
        .task {
            if authManager.isAuthenticated {
                await loadProfileData()
                await loadCreatorTier()
            }
        }
    }

    // MARK: - Creator Tier Card

    @ViewBuilder
    private var creatorTierCard: some View {
        if authManager.currentUser?.role == "admin" {
            // Admins always have creator access — no card needed
            EmptyView()
        } else if let tier = creatorTier {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: tier == "creator" ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundStyle(tier == "creator" ? Color.Theme.success : Color.Theme.textSecondary)
                    Text(tier == "creator" ? "Creator Account" : "Free Account")
                        .font(.subheadline.bold())
                        .foregroundStyle(tier == "creator" ? Color.Theme.success : Color.Theme.textPrimary)
                    Spacer()
                }

                if tier != "creator" {
                    Text("Upgrade to a Creator account to add and manage artists on the platform.")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)

                    if let url = URL(string: "https://vedioz.netlify.app/pricing") {
                        Link(destination: url) {
                            Text("View Creator Plans →")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.Theme.accent)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.Theme.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tier == "creator" ? Color.Theme.success.opacity(0.4) : Color.Theme.borderDefault, lineWidth: 1)
            )
        }
    }

    private func loadCreatorTier() async {
        guard authManager.currentUser?.role != "admin" else { return }
        do {
            let status: PaymentStatusResponse = try await APIClient.shared.request(endpoint: .paymentStatus)
            creatorTier = status.creatorTier
        } catch {
            creatorTier = "free"
        }
    }

    private func loadProfileData() async {
        await viewModel.loadProfileList()
        if let userId = authManager.currentUser?.id {
            async let f: () = viewModel.loadFollowers(userId: userId)
            async let g: () = viewModel.loadFollowing(userId: userId)
            async let s: () = viewModel.loadTasteSuggestions()
            _ = await (f, g, s)
        }
    }

    private func followListSheet(title: String, users: [FollowUser]) -> some View {
        FollowListSheet(title: title, users: users, currentUserId: authManager.currentUser?.id)
    }
}

private struct FollowListSheet: View {
    let title: String
    let users: [FollowUser]
    let currentUserId: Int?
    @State private var activeConversation: Conversation?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if users.isEmpty {
                    Text("No \(title.lowercased()) yet")
                        .foregroundStyle(Color.Theme.textSecondary)
                } else {
                    List(users) { user in
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.Theme.textSecondary)

                            Text(user.username)
                                .foregroundStyle(Color.Theme.textPrimary)

                            Spacer()

                            DMButton(targetUserId: user.userId, targetUsername: user.username) { conversation in
                                activeConversation = conversation
                            }
                        }
                        .listRowBackground(Color.Theme.bgCard)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $activeConversation) { conversation in
                ChatView(conversation: conversation)
            }
        }
    }
}

private struct DMButton: View {
    let targetUserId: Int
    let targetUsername: String
    let onOpenChat: (Conversation) -> Void

    @State private var canDM = false
    @State private var existingConvId: Int?
    @State private var isLoading = true

    var body: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.7)
                .task { await checkDM() }
        } else if canDM {
            Button {
                Task { await openConversation() }
            } label: {
                Image(systemName: "envelope.fill")
                    .font(.caption)
                    .foregroundStyle(Color.Theme.accent)
                    .padding(8)
                    .background(Color.Theme.accent.opacity(0.15))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    private func checkDM() async {
        do {
            let response: CheckDMResponse = try await APIClient.shared.request(
                endpoint: .checkDM(userId: targetUserId)
            )
            canDM = response.canDM
            existingConvId = response.conversationId
        } catch {
            canDM = false
        }
        isLoading = false
    }

    private func openConversation() async {
        var convId = existingConvId

        if convId == nil {
            do {
                let response: CreateConversationResponse = try await APIClient.shared.request(
                    endpoint: .createConversation,
                    body: CreateConversationBody(recipientId: targetUserId)
                )
                convId = response.conversationId
            } catch {
                return
            }
        }

        guard let convId else { return }

        let conversation = Conversation(
            conversationId: convId,
            userOne: 0,
            userTwo: 0,
            otherUsername: targetUsername,
            otherUserId: targetUserId
        )
        onOpenChat(conversation)
    }
}

private struct SuggestionRow: View {
    let suggestion: TasteSuggestion
    @State private var isFollowing = false
    @State private var activeConversation: Conversation?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.username)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.Theme.textPrimary)
                Text("\(suggestion.overlapCount) shared \(suggestion.overlapCount == 1 ? "artist" : "artists")")
                    .font(.caption)
                    .foregroundStyle(Color.Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.Theme.accent.opacity(0.15))
                    .cornerRadius(20)
            }

            Spacer()

            FollowButton(userId: suggestion.userId, isFollowing: $isFollowing)

            DMButton(targetUserId: suggestion.userId, targetUsername: suggestion.username) { conversation in
                activeConversation = conversation
            }
        }
        .padding(12)
        .background(Color.Theme.bgCard)
        .cornerRadius(10)
        .navigationDestination(item: $activeConversation) { conversation in
            ChatView(conversation: conversation)
        }
    }
}

private struct PaymentStatusResponse: Decodable {
    let creatorTier: String
    let tierType: String?

    enum CodingKeys: String, CodingKey {
        case creatorTier = "creator_tier"
        case tierType = "tier_type"
    }
}

private struct CreateConversationBody: Encodable {
    let recipientId: Int

    enum CodingKeys: String, CodingKey {
        case recipientId = "recipient_id"
    }
}

private struct CreateConversationResponse: Codable {
    let conversationId: Int

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
    }
}
