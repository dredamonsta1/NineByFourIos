import SwiftUI

struct ArtistDetailSheet: View {
    let artistId: Int
    @State private var viewModel = ArtistDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager

    // Album manager state
    @State private var albumRows: [NewAlbumRow] = [NewAlbumRow()]
    @State private var albumMessage: String?
    @State private var isSavingAlbums = false

    private var isAdmin: Bool { authManager.currentUser?.role == "admin" }

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

                                // Discography
                                if let albums = artist.albums, !albums.isEmpty {
                                    Divider().background(Color.Theme.borderDefault)

                                    Text("Discography")
                                        .font(.headline)
                                        .foregroundStyle(Color.Theme.textPrimary)

                                    LazyVStack(spacing: 10) {
                                        ForEach(albums) { album in
                                            AlbumRow(album: album, onDelete: isAdmin ? {
                                                Task { await viewModel.deleteAlbum(artistId: artistId, albumId: album.albumId) }
                                            } : nil)
                                        }
                                    }
                                }

                                // Album manager (authenticated users)
                                if authManager.isAuthenticated {
                                    Divider().background(Color.Theme.borderDefault)
                                    albumManagerSection(artistId: artist.artistId)
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

    // MARK: - Album Manager

    @ViewBuilder
    private func albumManagerSection(artistId: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Albums")
                .font(.headline)
                .foregroundStyle(Color.Theme.textPrimary)

            Text("Album name is required. Year and certifications are optional.")
                .font(.caption)
                .foregroundStyle(Color.Theme.textSecondary)

            ForEach($albumRows) { $row in
                AlbumInputRow(row: $row, canRemove: albumRows.count > 1) {
                    albumRows.removeAll { $0.id == row.id }
                }
            }

            Button {
                albumRows.append(NewAlbumRow())
            } label: {
                Label("Add Another Album", systemImage: "plus")
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.Theme.borderDefault, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
            }

            if let msg = albumMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(msg.contains("saved") ? Color.Theme.success : Color.Theme.error)
            }

            Button {
                Task {
                    isSavingAlbums = true
                    albumMessage = nil
                    let success = await viewModel.addAlbums(artistId: artistId, rows: albumRows)
                    if success {
                        albumRows = [NewAlbumRow()]
                        albumMessage = "Albums saved!"
                    } else {
                        albumMessage = viewModel.errorMessage ?? "Failed to save albums."
                    }
                    isSavingAlbums = false
                }
            } label: {
                Text(isSavingAlbums ? "Saving..." : "Save Albums")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.Theme.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .disabled(isSavingAlbums || albumRows.allSatisfy { $0.albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        }
    }
}

// MARK: - Album Input Row

private struct AlbumInputRow: View {
    @Binding var row: NewAlbumRow
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField("Album name *", text: $row.albumName)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.Theme.bgInput)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.Theme.borderDefault, lineWidth: 1))
                    .foregroundStyle(Color.Theme.textPrimary)

                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.Theme.error)
                            .font(.title3)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Year", text: $row.year)
                    .font(.subheadline)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Color.Theme.bgInput)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.Theme.borderDefault, lineWidth: 1))
                    .foregroundStyle(Color.Theme.textPrimary)

                TextField("Certifications", text: $row.certifications)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.Theme.bgInput)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.Theme.borderDefault, lineWidth: 1))
                    .foregroundStyle(Color.Theme.textPrimary)
            }
        }
    }
}

// MARK: - Album Row (existing albums)

private struct AlbumRow: View {
    let album: Album
    var onDelete: (() -> Void)?

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

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.error)
                }
            }
        }
        .padding(10)
        .background(Color.Theme.bgCard)
        .cornerRadius(8)
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
