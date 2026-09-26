import SwiftUI

/// First-run artist picking.
///
/// Ported from the web flow shipped 2026-09-11, and mirrors its decisions
/// rather than reinventing them:
///
///  - **Genre grid before any artists.** The default artist sort is clout and
///    only ~57 of 112k artists have any, so an ungated grid opens on
///    ":wumpscut:" and "!!!". A poor first screen for a page whose whole job
///    is to prevent hesitation.
///  - **Three artists**, matching the server's own minimum for generating a
///    personality.
///  - **Ends on the personality reveal**, not by dropping into the app, so the
///    flow pays off with something the platform could not have said a minute
///    earlier.
///  - **Skip is "not now", not "stop asking".** It records that the user has
///    seen this screen so they are not bounced back into it, and nothing more.
///
/// The web's baseline was 13 of 24 registered users with zero artists — they
/// never started, rather than failing to finish. iOS had no equivalent at all
/// until now: a new user landed straight on the tab bar.
struct WelcomeView: View {
    /// Matches the web's genre pills exactly. StanBox is genre agnostic, so
    /// this is a broad spread rather than a house style.
    private static let genres = [
        "Hip Hop", "R&B", "Pop", "Rock", "Country",
        "Latin", "Drill", "Trap", "Reggae", "Dancehall",
    ]
    private static let gridSize = 24
    private static let target = 3

    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ProfileViewModel()

    @State private var selectedGenre: String?
    @State private var searchText = ""
    @State private var results: [Artist] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var personality: PersonalityResponse?
    @State private var isRevealing = false
    @State private var searchDebounce: Task<Void, Never>?

    let onFinish: () -> Void

    private var count: Int { viewModel.profileList.count }
    private var remaining: Int { max(Self.target - count, 0) }
    private var inList: Set<Int> { viewModel.profileListIds }

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()
            if let personality {
                reveal(personality)
            } else {
                picker
            }
        }
        .task {
            await viewModel.loadProfileList()
        }
    }

    // MARK: - Picking

    private var picker: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    genreRow

                    SearchBar(text: $searchText, placeholder: "Or search for anyone…")
                        .onChange(of: searchText) { _, value in
                            searchDebounce?.cancel()
                            searchDebounce = Task {
                                try? await Task.sleep(for: .milliseconds(400))
                                guard !Task.isCancelled else { return }
                                await search(value)
                            }
                        }

                    if isLoading {
                        ProgressView().tint(Color.Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 30)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.Theme.error)
                    } else if results.isEmpty {
                        Text("Pick a genre to see artists, or search for someone you already love.")
                            .font(.footnote)
                            .foregroundStyle(Color.Theme.textSecondary)
                            .padding(.top, 20)
                    } else {
                        grid
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Who do you stan?")
                .font(.title2.bold())
                .foregroundStyle(Color.Theme.textPrimary)
            Text(
                remaining > 0
                    ? "Pick \(remaining) more to unlock your music personality"
                    : "You're set — \(count) artists in your list"
            )
            .font(.footnote)
            .foregroundStyle(Color.Theme.textSecondary)

            ProgressView(value: Double(min(count, Self.target)), total: Double(Self.target))
                .tint(Color.Theme.accent)
                .padding(.horizontal, 40)
                .padding(.top, 2)
        }
        .padding(.top, 20)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
    }

    private var genreRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Self.genres, id: \.self) { genre in
                    Button {
                        selectedGenre = genre
                        searchText = ""
                        Task { await loadGenre(genre) }
                    } label: {
                        Text(genre)
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedGenre == genre ? Color.Theme.accent : Color.Theme.bgCard)
                            .foregroundStyle(selectedGenre == genre ? Color.Theme.bgBase : Color.Theme.textPrimary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(results) { artist in
                let added = inList.contains(artist.artistId)
                Button {
                    guard !added, !viewModel.isListFull else { return }
                    Task { await viewModel.addToProfileList(artist: artist) }
                } label: {
                    VStack(spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            ArtistThumb(url: artist.imageUrl)
                            if added {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.Theme.accent)
                                    .background(Circle().fill(Color.Theme.bgBase))
                                    .padding(4)
                            }
                        }
                        Text(artist.artistName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.Theme.textPrimary)
                            .lineLimit(1)
                    }
                }
                .opacity(added ? 0.55 : 1)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button {
                Task { await finish() }
            } label: {
                HStack(spacing: 6) {
                    if isRevealing { ProgressView().tint(Color.Theme.bgBase).scaleEffect(0.8) }
                    Text(isRevealing ? "Reading your taste…" : "Done")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(count >= Self.target ? Color.Theme.accent : Color.Theme.bgCardElevated)
                .foregroundStyle(count >= Self.target ? Color.Theme.bgBase : Color.Theme.textSecondary)
                .cornerRadius(10)
            }
            .disabled(count < Self.target || isRevealing)

            Button("I'll do this later") { skip() }
                .font(.footnote)
                .foregroundStyle(Color.Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Reveal

    private func reveal(_ p: PersonalityResponse) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text("You are")
                .font(.footnote)
                .foregroundStyle(Color.Theme.textSecondary)
            Text(p.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.accent)
                .padding(.horizontal, 24)
            Text(p.description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.textSecondary)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                onFinish()
            } label: {
                Text("Take me in")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.Theme.accent)
                    .foregroundStyle(Color.Theme.bgBase)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func loadGenre(_ genre: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let res: PaginatedArtistResponse = try await APIClient.shared.request(
                endpoint: .artists,
                queryItems: [
                    URLQueryItem(name: "genre", value: genre),
                    URLQueryItem(name: "limit", value: String(Self.gridSize)),
                ]
            )
            results = res.artists
        } catch {
            errorMessage = "Couldn't load artists. Try another genre."
            results = []
        }
        isLoading = false
    }

    private func search(_ term: String) async {
        let q = term.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        selectedGenre = nil
        isLoading = true
        errorMessage = nil
        do {
            let res: PaginatedArtistResponse = try await APIClient.shared.request(
                endpoint: .artists,
                queryItems: [
                    URLQueryItem(name: "search", value: q),
                    URLQueryItem(name: "limit", value: String(Self.gridSize)),
                ]
            )
            results = res.artists
        } catch {
            errorMessage = "Couldn't search right now."
            results = []
        }
        isLoading = false
    }

    /// Generates the personality, then hands off.
    ///
    /// Proceeds even when generation fails. The artists are already saved and
    /// the profile card generates one itself, so stranding someone on an error
    /// at the moment the product is trying to delight them is worse than
    /// skipping the flourish.
    private func finish() async {
        guard count >= Self.target, !isRevealing else { return }
        isRevealing = true
        OnboardingState.markSeen()
        do {
            let body = PersonalityRequest(
                artists: viewModel.profileList.map {
                    PersonalityRequest.ArtistRef(artist_name: $0.artistName, genre: $0.genre)
                }
            )
            let result: PersonalityResponse = try await APIClient.shared.request(
                endpoint: .musicPersonality,
                body: body
            )
            authManager.currentUser?.musicPersonalityTitle = result.title
            authManager.currentUser?.musicPersonalityDesc = result.description
            withAnimation { personality = result }
        } catch {
            onFinish()
        }
        isRevealing = false
    }

    /// "Not now", not "stop asking". Records only that this screen was seen,
    /// so the user is not bounced straight back into it.
    private func skip() {
        OnboardingState.markSeen()
        onFinish()
    }
}

/// Whether the first-run flow has been shown to this user on this device.
enum OnboardingState {
    private static let key = "stanbox_welcome_seen"

    static var hasSeen: Bool { UserDefaults.standard.bool(forKey: key) }
    static func markSeen() { UserDefaults.standard.set(true, forKey: key) }
    /// Used on sign-out so a different account on the same device still gets
    /// its own first run.
    static func reset() { UserDefaults.standard.removeObject(forKey: key) }
}

private struct ArtistThumb: View {
    let url: String?

    var body: some View {
        Group {
            if let url, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.Theme.bgCard
                }
            } else {
                Color.Theme.bgCard
                    .overlay(
                        Image(systemName: "music.mic")
                            .foregroundStyle(Color.Theme.textSecondary)
                    )
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(8)
    }
}
