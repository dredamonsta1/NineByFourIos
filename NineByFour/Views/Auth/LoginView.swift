import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case email, code }

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    Image("StanBoxLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 220)
                        .accessibilityLabel("StanBox")

                    Spacer().frame(height: 4)

                    Text(viewModel.otpStep == .email ? "Welcome back" : "Confirm your email")
                        .font(.title2.bold())
                        .foregroundStyle(Color.Theme.textPrimary)

                    Text(viewModel.otpStep == .email
                         ? "Enter your email — we'll send you a sign-in code."
                         : "We sent a 6-digit code to \(viewModel.email). Enter it below.")
                        .font(.subheadline)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.Theme.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let info = viewModel.infoMessage {
                        Text(info)
                            .font(.caption)
                            .foregroundStyle(Color.Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if viewModel.otpStep == .email {
                        emailForm
                    } else {
                        codeForm
                    }

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
        .onAppear {
            if viewModel.otpStep == .email { focusedField = .email }
        }
    }

    private var emailForm: some View {
        VStack(spacing: 16) {
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
                .textContentType(.emailAddress)
                .focused($focusedField, equals: .email)
                .submitLabel(.send)
                .onSubmit { Task { await viewModel.sendOTPCode(authManager: authManager) } }

            Button {
                Task { await viewModel.sendOTPCode(authManager: authManager) }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Sending…" : "Send code")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.Theme.accent)
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
            .disabled(viewModel.isLoading || viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var codeForm: some View {
        VStack(spacing: 16) {
            TextField("123456", text: $viewModel.code)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )
                .foregroundStyle(Color.Theme.textPrimary)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focusedField, equals: .code)
                .onChange(of: viewModel.code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(6))
                    if digits != newValue { viewModel.code = digits }
                }
                .onAppear { focusedField = .code }

            Button {
                Task { await viewModel.verifyOTPCode(authManager: authManager) }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text(viewModel.isLoading ? "Verifying…" : "Sign in")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.Theme.accent)
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
            .disabled(viewModel.isLoading || viewModel.code.count != 6)

            VStack(spacing: 6) {
                Button {
                    Task { await viewModel.sendOTPCode(authManager: authManager, silent: true) }
                } label: {
                    Text(viewModel.resendCooldown > 0
                         ? "Resend in \(viewModel.resendCooldown)s"
                         : "Resend code")
                        .font(.footnote)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
                .disabled(viewModel.resendCooldown > 0 || viewModel.isLoading)

                Button {
                    viewModel.backToEmailStep()
                    focusedField = .email
                } label: {
                    Text("Use a different email")
                        .font(.footnote)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.top, 4)
        }
    }
}
