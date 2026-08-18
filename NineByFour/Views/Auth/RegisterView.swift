import SwiftUI

/// Passwordless sign-up.
///
/// Was a username/email/password/confirm form posting to `/users/register`
/// and then `/users/login`. The app no longer calls either route (deleting
/// them backend-side is the follow-up), and neither was reachable from the
/// UI anyway — nothing ever presented this view, which meant an
/// approved waitlist user with an invite code had **no way to create an
/// account in the app at all**. They had to sign up on the web first.
///
/// Same two-step shape as `LoginView`: collect details, get a code, verify.
/// The account is created by the verify call itself — the backend inserts
/// the user when a username and invite code arrive alongside the code, so
/// there's no separate register round trip.
struct RegisterView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case email, username, invite, code }

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    Text(viewModel.otpStep == .email ? "Create account" : "Confirm your email")
                        .font(.title.bold())
                        .foregroundStyle(Color.Theme.textPrimary)

                    Text(viewModel.otpStep == .email
                         ? "You'll need an invite code. We'll email you a 6-digit code to finish."
                         : "We sent a 6-digit code to \(viewModel.email).")
                        .font(.subheadline)
                        .foregroundStyle(Color.Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    if let info = viewModel.infoMessage {
                        Text(info)
                            .font(.footnote)
                            .foregroundStyle(Color.Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.otpStep == .email {
                        detailsForm
                    } else {
                        codeForm
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.mode = .signup
            if viewModel.otpStep == .email { focusedField = .email }
        }
    }

    private var detailsForm: some View {
        VStack(spacing: 16) {
            field("Email", text: $viewModel.email, focus: .email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)

            field("Username", text: $viewModel.username, focus: .username)
                .textContentType(.username)

            field("Invite code", text: $viewModel.inviteCode, focus: .invite)
                .textInputAutocapitalization(.characters)

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
            .disabled(viewModel.isLoading || !detailsComplete)
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
                    Text(viewModel.isLoading ? "Creating account…" : "Create account")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.Theme.accent)
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
            .disabled(viewModel.isLoading || viewModel.code.count != 6)

            Button {
                Task { await viewModel.sendOTPCode(authManager: authManager, silent: true) }
            } label: {
                Text(viewModel.resendCooldown > 0
                     ? "Resend in \(viewModel.resendCooldown)s"
                     : "Resend code")
                    .font(.subheadline)
                    .foregroundStyle(viewModel.resendCooldown > 0
                                     ? Color.Theme.textSecondary
                                     : Color.Theme.accent)
            }
            .disabled(viewModel.resendCooldown > 0 || viewModel.isLoading)

            Button("Use different details") { viewModel.backToEmailStep() }
                .font(.subheadline)
                .foregroundStyle(Color.Theme.textSecondary)
        }
    }

    private var detailsComplete: Bool {
        !viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func field(
        _ placeholder: String,
        text: Binding<String>,
        focus: Field
    ) -> some View {
        TextField(placeholder, text: text)
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
            .focused($focusedField, equals: focus)
    }
}
