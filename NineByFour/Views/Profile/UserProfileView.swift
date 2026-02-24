import SwiftUI

struct UserProfileView: View {
    let userId: Int
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var user: User?
    @State private var profileList: [Artist] = []
    @State private var followers: [FollowUser] = []
    @State private var following: [FollowUser] = []
    @State private var isFollowing = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if isLoading {
                    LoadingStateView()
                } else if let error = errorMessage {
                    ErrorStateView(message: error) {
                        Task { await loadProfile() }
                    }
                } else if let user {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile header
                            VStack(spacing: 12) {
                                if let imageUrl = user.profileImage, !imageUrl.isEmpty {
                                    CachedAsyncImage(url: imageUrl.fullImageURL, cornerRadius: 45)
                                        .frame(width: 90, height: 90)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundStyle(Color.Theme.textSecondary)
                                }

                                Text(user.username)
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.Theme.textBright)

                                if userId != authManager.currentUser?.id {
                                    FollowButton(userId: userId, isFollowing: $isFollowing)
                                }
                            }
                            .padding(.top, 8)

                            // Stats row
                            HStack(spacing: 32) {
                                VStack(spacing: 4) {
                                    Text("\(followers.count)")
                                        .font(.headline)
                                        .foregroundStyle(Color.Theme.textBright)
                                    Text("Followers")
                                        .font(.caption)
                                        .foregroundStyle(Color.Theme.textSecondary)
                                }

                                VStack(spacing: 4) {
                                    Text("\(following.count)")
                                        .font(.headline)
                                        .foregroundStyle(Color.Theme.textBright)
                                    Text("Following")
                                        .font(.caption)
                                        .foregroundStyle(Color.Theme.textSecondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.Theme.bgCard)
                            .cornerRadius(12)

                            // Artist list
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Their List")
                                    .font(.headline)
                                    .foregroundStyle(Color.Theme.textPrimary)

                                if profileList.isEmpty {
                                    Text("No artists in their list yet")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.Theme.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 20)
                                } else {
                                    LazyVStack(spacing: 8) {
                                        ForEach(profileList) { artist in
                                            HStack(spacing: 12) {
                                                CachedAsyncImage(url: artist.imageUrl?.fullImageURL, cornerRadius: 6)
                                                    .frame(width: 44, height: 44)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(artist.artistName)
                                                        .font(.subheadline)
                                                        .foregroundStyle(Color.Theme.textPrimary)
                                                        .lineLimit(1)

                                                    if let genre = artist.genre, !genre.isEmpty {
                                                        Text(genre)
                                                            .font(.caption)
                                                            .foregroundStyle(Color.Theme.textSecondary)
                                                    }
                                                }

                                                Spacer()
                                            }
                                            .padding(10)
                                            .background(Color.Theme.bgCard)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                }
            }
        }
        .task {
            await loadProfile()
        }
    }

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedUser: User = try await APIClient.shared.request(
                endpoint: .userProfile(userId: userId)
            )
            user = fetchedUser
        } catch {
            errorMessage = "Failed to load profile."
            isLoading = false
            return
        }

        // Load list, followers, following in parallel
        async let listTask: ProfileListResponse? = {
            try? await APIClient.shared.request(endpoint: .userProfileList(userId: userId))
        }()
        async let followersTask: [FollowUser]? = {
            try? await APIClient.shared.request(endpoint: .followers(userId: userId))
        }()
        async let followingTask: [FollowUser]? = {
            try? await APIClient.shared.request(endpoint: .following(userId: userId))
        }()

        profileList = (await listTask)?.list ?? []
        followers = await followersTask ?? []
        following = await followingTask ?? []

        // Check if current user follows this user
        if let currentUserId = authManager.currentUser?.id {
            isFollowing = followers.contains { $0.userId == currentUserId }
        }

        isLoading = false
    }
}

private struct ProfileListResponse: Codable {
    let list: [Artist]
}
