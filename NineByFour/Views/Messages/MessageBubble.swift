import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isSent: Bool

    var body: some View {
        HStack {
            if isSent { Spacer(minLength: 60) }

            VStack(alignment: isSent ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isSent ? .white : Color.Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isSent ? Color.Theme.accent : Color.Theme.bgCardElevated)
                    .cornerRadius(16)

                Text(message.createdAt.toDate()?.relativeString() ?? "")
                    .font(.caption2)
                    .foregroundStyle(Color.Theme.textSecondary)
            }

            if !isSent { Spacer(minLength: 60) }
        }
    }
}
