import SwiftUI

struct ErrorStateView: View {
    var message: String
    var onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.Theme.error)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Retry", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.Theme.accent)
            }
        }
    }
}
