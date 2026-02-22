import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploading = false
    @State private var errorMessage: String?
    var onImageUploaded: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                VStack(spacing: 20) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.Theme.accent)

                            Text("Select Photo")
                                .font(.headline)
                                .foregroundStyle(Color.Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.Theme.bgCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.Theme.borderDefault, lineWidth: 1)
                        )
                    }

                    if isUploading {
                        ProgressView("Uploading...")
                            .tint(Color.Theme.accent)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.Theme.error)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
            .onChange(of: selectedItem) {
                guard let item = selectedItem else { return }
                Task { await uploadImage(item: item) }
            }
        }
    }

    @MainActor
    private func uploadImage(item: PhotosPickerItem) async {
        isUploading = true
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load image."
                isUploading = false
                return
            }

            var formData = MultipartFormData()
            formData.addFile(named: "image", fileName: "profile.jpg", mimeType: "image/jpeg", data: data)

            struct UploadResponse: Codable {
                let profileImage: String
                enum CodingKeys: String, CodingKey {
                    case profileImage = "profile_image"
                }
            }

            let response: UploadResponse = try await APIClient.shared.upload(
                endpoint: .uploadProfileImage,
                formData: formData
            )
            onImageUploaded(response.profileImage)
            dismiss()
        } catch {
            errorMessage = "Upload failed. Please try again."
        }

        isUploading = false
    }
}
