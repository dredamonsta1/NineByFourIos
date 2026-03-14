import SwiftUI

private enum CreatorTab: String, CaseIterable {
    case text = "Text"
    case music = "Music"
}

struct PostCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: FeedViewModel
    @State private var selectedTab: CreatorTab = .text

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                VStack(spacing: 16) {
                    Picker("Post type", selection: $selectedTab) {
                        ForEach(CreatorTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedTab {
                    case .text:
                        textPostForm
                    case .music:
                        musicPostForm
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Text Post Form

    private var textPostForm: some View {
        VStack(spacing: 12) {
            TextEditor(text: $viewModel.newPostContent)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color.Theme.textPrimary)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )
                .frame(minHeight: 120)

            Button {
                Task {
                    let success = await viewModel.createTextPost()
                    if success { dismiss() }
                }
            } label: {
                Text("Post")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.Theme.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Music Post Form

    private var musicPostForm: some View {
        VStack(spacing: 12) {
            TextField("Title (optional)", text: $viewModel.musicTitle)
                .foregroundStyle(Color.Theme.textPrimary)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )

            TextField("Spotify / SoundCloud / Apple Music link", text: $viewModel.musicStreamUrl)
                .foregroundStyle(Color.Theme.textPrimary)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )

            TextField("Caption (optional)", text: $viewModel.musicCaption)
                .foregroundStyle(Color.Theme.textPrimary)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )

            Button {
                Task {
                    let success = await viewModel.createMusicPost()
                    if success { dismiss() }
                }
            } label: {
                Text("Share Music")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.Theme.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.musicStreamUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
