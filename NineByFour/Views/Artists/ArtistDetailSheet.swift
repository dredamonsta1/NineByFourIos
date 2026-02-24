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

                                // Clout button
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

                                    Spacer()
                                }

                                // Albums section
                                if let albums = artist.albums, !albums.isEmpty {
                                    Divider()
                                        .background(Color.Theme.borderDefault)

                                    Text("Discography")
                                        .font(.headline)
                                        .foregroundStyle(Color.Theme.textPrimary)

                                    LazyVStack(spacing: 10) {
                                        ForEach(albums) { album in
                                            AlbumRow(album: album)
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
            await viewModel.loadArtist(id: artistId)
            if authManager.isAuthenticated {
                await viewModel.checkProfileList()
            }
        }
    }
}

// MARK: - Supporting Views

private struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(Color.Theme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.Theme.bgCardElevated)
        .cornerRadius(16)
    }
}

private struct AlbumRow: View {
    let album: Album

    var body: some View {
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
        .padding(10)
        .background(Color.Theme.bgCard)
        .cornerRadius(8)
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
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
