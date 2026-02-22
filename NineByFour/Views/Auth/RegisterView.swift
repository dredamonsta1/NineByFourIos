import SwiftUI

struct RegisterView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    Text("Create Account")
                        .font(.title.bold())
                        .foregroundStyle(Color.Theme.textPrimary)

                    VStack(spacing: 16) {
                        TextField("Username", text: $viewModel.username)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.Theme.bgInput)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
                            )
                            .foregroundStyle(Color.Theme.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.Theme.bgInput)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
                            )
                            .foregroundStyle(Color.Theme.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.Theme.bgInput)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
                            )
                            .foregroundStyle(Color.Theme.textPrimary)

                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.Theme.bgInput)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.Theme.borderDefault, lineWidth: 1)
                            )
                            .foregroundStyle(Color.Theme.textPrimary)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.Theme.error)
                    }

                    Button {
                        Task {
                            await viewModel.register(authManager: authManager)
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.Theme.accent)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)

                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? ")
                            .foregroundStyle(Color.Theme.textSecondary)
                        + Text("Login")
                            .foregroundStyle(Color.Theme.accent)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.Theme.textPrimary)
                }
            }
        }
    }
}
