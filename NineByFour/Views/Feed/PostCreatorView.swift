import SwiftUI

struct PostCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                VStack(spacing: 16) {
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
}
