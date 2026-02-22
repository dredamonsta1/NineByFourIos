import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.Theme.textSecondary)

            TextField(placeholder, text: $text)
                .foregroundStyle(Color.Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
        }
        .padding(10)
        .background(Color.Theme.bgInput)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.Theme.borderDefault, lineWidth: 1)
        )
    }
}
