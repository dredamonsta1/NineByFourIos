import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    // Logo / Title
                    VStack(spacing: 8) {
                        Text("9by4")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.Theme.accent)
                        Text("NineByFour")
                            .font(.title3)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }

                    Spacer().frame(height: 20)

                    // Form
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
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.Theme.error)
                    }

                    // Login button
                    Button {
                        Task {
                            await viewModel.login(authManager: authManager)
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.Theme.accent)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)

                    // Register link
                    NavigationLink {
                        RegisterView()
                    } label: {
                        Text("Don't have an account? ")
                            .foregroundStyle(Color.Theme.textSecondary)
                        + Text("Sign Up")
                            .foregroundStyle(Color.Theme.accent)
                    }
                    .font(.subheadline)

                    // Waitlist link
                    NavigationLink {
                        WaitlistView()
                    } label: {
                        Text("No invite code? ")
                            .foregroundStyle(Color.Theme.textSecondary)
                        + Text("Join the Waitlist")
                            .foregroundStyle(Color.Theme.accent)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }
}
