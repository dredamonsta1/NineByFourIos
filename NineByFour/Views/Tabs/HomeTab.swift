import SwiftUI

struct HomeTab: View {
    @State private var viewModel = ArtistListViewModel()
    @State private var selectedArtistId: Int?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                if viewModel.isLoading && viewModel.artists.isEmpty {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage, viewModel.artists.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.loadArtists() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            SearchBar(text: $viewModel.searchText)
                                .padding(.horizontal, 16)
                                .onChange(of: viewModel.searchText) {
                                    Task { await viewModel.search() }
                                }

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(viewModel.artists) { artist in
                                    ArtistCard(artist: artist) {
                                        selectedArtistId = artist.artistId
                                    }
                                    .onAppear {
                                        if artist.id == viewModel.artists.last?.id {
                                            Task { await viewModel.loadMore() }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 16)
                    }
                    .refreshable {
                        await viewModel.loadArtists()
                    }
                }
            }
            .navigationTitle("Artists")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: Binding(
                get: { selectedArtistId.map { SheetItem(id: $0) } },
                set: { selectedArtistId = $0?.id }
            )) { item in
                ArtistDetailSheet(artistId: item.id)
            }
        }
        .task {
            if viewModel.artists.isEmpty {
                await viewModel.loadArtists()
            }
        }
    }
}

private struct SheetItem: Identifiable {
    let id: Int
}
