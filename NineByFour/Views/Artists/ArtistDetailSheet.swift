import SwiftUI

struct ArtistDetailSheet: View {
    let artistId: Int
    @State private var viewModel = ArtistDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.loadArtist(id: artistId) }
                    }
                } else if let artist = viewModel.artist {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Hero image
                            CachedAsyncImage(url: artist.imageUrl?.fullImageURL, cornerRadius: 0)
                                .frame(height: 280)
                                .frame(maxWidth: .infinity)
                                .clipped()

                            VStack(alignment: .leading, spacing: 12) {
                                // Name + AKA
                                Text(artist.artistName)
                                    .font(.title.bold())
                                    .foregroundStyle(Color.Theme.textBright)

                                if let aka = artist.aka, !aka.isEmpty {
                                    Text("AKA: \(aka)")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.Theme.textSecondary)
                                }

                                // Info chips
                                FlowLayout(spacing: 8) {
                                    if let genre = artist.genre, !genre.isEmpty {
                                        InfoChip(icon: "music.note", text: genre)
                                    }
                                    if let state = artist.state, !state.isEmpty {
                                        InfoChip(icon: "mappin", text: state)
                                    }
                                    if let region = artist.region, !region.isEmpty {
                                        InfoChip(icon: "globe", text: region)
                                    }
                                    if let label = artist.label, !label.isEmpty {
                                        InfoChip(icon: "building.2", text: label)
                                    }
                                }

                                // Artist "world" link-outs
                                if hasWorldLinks(artist) {
                                    FlowLayout(spacing: 8) {
                                        if let url = nonEmptyURL(artist.websiteUrl) {
                                            WorldLink(label: "Website", systemImage: "link", url: url)
                                        }
                                        if let url = nonEmptyURL(artist.merchUrl) {
                                            WorldLink(label: "Shop", systemImage: "bag", url: url)
                                        }
                                        if let url = nonEmptyURL(artist.newsletterUrl) {
                                            WorldLink(label: "Newsletter", systemImage: "envelope", url: url)
                                        }
                                        if let url = nonEmptyURL(artist.spotifyUrl) {
                                            WorldLink(label: "Spotify", systemImage: "play.circle.fill", url: url, tint: Color.Theme.spotify)
                                        }
                                        if let url = nonEmptyURL(artist.appleMusicUrl) {
                                            WorldLink(label: "Apple Music", systemImage: "applelogo", url: url, tint: Color.Theme.appleMusic)
                                        }
                                    }
                                }

                                // Clout + Top 20 buttons
                                HStack(spacing: 8) {
                                    Button {
                                        Task { await viewModel.toggleClout(isAuthenticated: authManager.isAuthenticated) }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: viewModel.hasClout ? "flame.fill" : "flame")
                                            Text("\(artist.count ?? 0)")
                                        }
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(viewModel.hasClout ? Color.Theme.hot : Color.clear)
                                        .foregroundStyle(viewModel.hasClout ? .white : Color.Theme.hot)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.Theme.hot, lineWidth: viewModel.hasClout ? 0 : 1)
                                        )
                                    }

                                    if authManager.isAuthenticated {
                                        TopTwentyButton(viewModel: viewModel, isAuthenticated: authManager.isAuthenticated)
                                    }

                                    Spacer()
                                }

                                // Discography
                                if let albums = artist.albums, !albums.isEmpty {
                                    Divider().background(Color.Theme.borderDefault)

                                    Text("Discography")
                                        .font(.headline)
                                        .foregroundStyle(Color.Theme.textPrimary)

                                    LazyVStack(spacing: 10) {
                                        ForEach(albums) { album in
                                            AlbumRow(
                                                album: album,
                                                viewModel: viewModel,
                                                authManager: authManager
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadArtist(id: artistId)
            if authManager.isAuthenticated {
                await viewModel.checkProfileList()
            }
        }
    }

    private func hasWorldLinks(_ artist: Artist) -> Bool {
        nonEmptyURL(artist.websiteUrl) != nil
            || nonEmptyURL(artist.merchUrl) != nil
            || nonEmptyURL(artist.newsletterUrl) != nil
            || nonEmptyURL(artist.spotifyUrl) != nil
            || nonEmptyURL(artist.appleMusicUrl) != nil
    }

    private func nonEmptyURL(_ raw: String?) -> URL? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return URL(string: raw)
    }
}

// MARK: - Top 20 pill button

private struct TopTwentyButton: View {
    @Bindable var viewModel: ArtistDetailViewModel
    let isAuthenticated: Bool

    private enum State { case add, added, full }

    private var state: State {
        if viewModel.isInProfileList { return .added }
        if viewModel.isProfileListFull { return .full }
        return .add
    }

    var body: some View {
        Button {
            guard state == .add else { return }
            Task { await viewModel.addToProfileList(isAuthenticated: isAuthenticated) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                Text(label)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(background)
            .foregroundStyle(foreground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(strokeColor, lineWidth: state == .add ? 1 : 0)
            )
        }
        .disabled(state != .add || viewModel.isAddingToProfileList)
    }

    private var iconName: String {
        switch state {
        case .add: return "plus"
        case .added: return "checkmark"
        case .full: return "circle.slash"
        }
    }

    private var label: String {
        switch state {
        case .add: return "Top 20"
        case .added: return "In Top 20"
        case .full: return "Top 20 Full"
        }
    }

    private var background: Color {
        switch state {
        case .add: return .clear
        case .added: return Color.Theme.accent
        case .full: return Color.Theme.bgCardElevated
        }
    }

    private var foreground: Color {
        switch state {
        case .add: return Color.Theme.accent
        case .added: return .white
        case .full: return Color.Theme.textSecondary
        }
    }

    private var strokeColor: Color { Color.Theme.accent }
}

// MARK: - World link-out pill

private struct WorldLink: View {
    let label: String
    let systemImage: String
    let url: URL
    var tint: Color = Color.Theme.accent

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.caption)
                Text(label).font(.caption.weight(.semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.Theme.bgCardElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - Album Row (existing albums)

private struct AlbumRow: View {
    let album: Album
    @Bindable var viewModel: ArtistDetailViewModel
    let authManager: AuthManager

    private var spotifyURL: URL? {
        guard let raw = album.spotifyUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    private var appleMusicURL: URL? {
        guard let raw = album.appleMusicUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: album.albumImageUrl?.fullImageURL, cornerRadius: 6)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text(album.albumName)
                        .font(.subheadline)
                        .foregroundStyle(Color.Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let year = album.year, !year.isEmpty {
                            Text(year)
                                .font(.caption)
                                .foregroundStyle(Color.Theme.textSecondary)
                        }
                        if let certs = album.certifications, !certs.isEmpty {
                            Text(certs)
                                .font(.caption)
                                .foregroundStyle(Color.Theme.accent)
                        }
                    }
                }

                Spacer()
            }

            if spotifyURL != nil || appleMusicURL != nil {
                HStack(spacing: 8) {
                    if let url = spotifyURL {
                        AlbumLinkButton(label: "Spotify", systemImage: "play.circle.fill", url: url, tint: Color.Theme.spotify)
                    }
                    if let url = appleMusicURL {
                        AlbumLinkButton(label: "Apple Music", systemImage: "applelogo", url: url, tint: Color.Theme.appleMusic)
                    }
                }
                .padding(.leading, 62)
            }

            if album.isOnSale {
                AlbumBuyButton(album: album, viewModel: viewModel, authManager: authManager)
                    .padding(.leading, 62)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .background(Color.Theme.bgCard)
        .cornerRadius(8)
    }
}

// MARK: - Album Buy Button (Pillar B commerce)
//
// UI-only slice: "Add to Top 20 to unlock" wires up via the existing
// add-to-profile-list action. "Buy $X.XX" shows a placeholder alert
// until the webview Stripe Checkout lands in iOS v1 Phase 5 slice 3.

private struct AlbumBuyButton: View {
    let album: Album
    @Bindable var viewModel: ArtistDetailViewModel
    let authManager: AuthManager

    @State private var isAddingToList = false
    @State private var showBuyStubAlert = false

    private var priceLabel: String {
        guard let cents = album.priceCents else { return "" }
        return String(format: "$%.2f", Double(cents) / 100.0)
    }

    private enum ButtonState {
        case signIn
        case owned
        case addToTop20
        case top20Full
        case buy
    }

    private var state: ButtonState {
        if !authManager.isAuthenticated { return .signIn }
        if authManager.hasPurchased(albumId: album.albumId) { return .owned }
        if viewModel.isInProfileList { return .buy }
        if viewModel.isProfileListFull { return .top20Full }
        return .addToTop20
    }

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                Text(labelText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .font(.caption.bold())
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, lineWidth: showsBorder ? 1 : 0)
            )
            .cornerRadius(10)
        }
        .disabled(state == .top20Full || isAddingToList)
        .alert("Web checkout coming soon", isPresented: $showBuyStubAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Stripe Checkout in-app opens in the next update. Meanwhile you can buy this album on stanbox.com.")
        }
    }

    private var iconName: String {
        switch state {
        case .signIn: return "person.crop.circle"
        case .owned: return "arrow.down.circle.fill"
        case .addToTop20: return "star.circle"
        case .top20Full: return "circle.slash"
        case .buy: return "cart.fill"
        }
    }

    private var labelText: String {
        switch state {
        case .signIn: return "Sign in to buy \(priceLabel)"
        case .owned: return "Owned — open in Library"
        case .addToTop20: return "Add to your Top 20 to unlock \(priceLabel)"
        case .top20Full: return "Top 20 full — manage in profile"
        case .buy: return isAddingToList ? "Adding…" : "Buy \(priceLabel)"
        }
    }

    private var foreground: Color {
        switch state {
        case .signIn: return Color.Theme.accent
        case .owned: return .white
        case .addToTop20: return Color.Theme.accent
        case .top20Full: return Color.Theme.textSecondary
        case .buy: return .white
        }
    }

    private var background: Color {
        switch state {
        case .signIn, .addToTop20: return .clear
        case .owned: return Color.Theme.accent
        case .top20Full: return Color.Theme.bgCardElevated
        case .buy: return Color.Theme.accent
        }
    }

    private var showsBorder: Bool {
        state == .signIn || state == .addToTop20
    }

    private var strokeColor: Color { Color.Theme.accent }

    private func handleTap() {
        switch state {
        case .signIn, .top20Full:
            break
        case .owned:
            // TODO(iOS v1 Phase 5 slice 5): route to LibraryTab and scroll to album.
            break
        case .addToTop20:
            Task {
                isAddingToList = true
                await viewModel.addToProfileList(isAuthenticated: authManager.isAuthenticated)
                isAddingToList = false
            }
        case .buy:
            // TODO(iOS v1 Phase 5 slice 3): open webview to
            // POST /albums/:id/checkout → Stripe Checkout URL, return to app.
            showBuyStubAlert = true
        }
    }
}

private struct AlbumLinkButton: View {
    let label: String
    let systemImage: String
    let url: URL
    let tint: Color

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 4) {
                Image(systemName: systemImage).font(.caption2)
                Text(label).font(.caption2.weight(.semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .cornerRadius(10)
        }
    }
}

// MARK: - Info Chip

private struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption)
        }
        .foregroundStyle(Color.Theme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.Theme.bgCardElevated)
        .cornerRadius(16)
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangeSubviews(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
