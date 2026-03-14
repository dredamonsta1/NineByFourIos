import SwiftUI

struct EventCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: EventsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Theme.bgBase.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        field(label: "Title *", text: $viewModel.newTitle, placeholder: "Event name")

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date *")
                                .font(.caption)
                                .foregroundStyle(Color.Theme.textSecondary)
                            DatePicker("", selection: $viewModel.newDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        field(label: "Time (e.g. 9:00 PM)", text: $viewModel.newTime, placeholder: "Optional")
                        field(label: "Venue", text: $viewModel.newVenue, placeholder: "Optional")
                        field(label: "City", text: $viewModel.newCity, placeholder: "Optional")

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.Theme.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task {
                                let success = await viewModel.createEvent()
                                if success { dismiss() }
                            }
                        } label: {
                            Text(viewModel.isCreating ? "Creating..." : "Create Event")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.Theme.accent)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isCreating)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Event")
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

    private func field(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.Theme.textSecondary)
            TextField(placeholder, text: text)
                .foregroundStyle(Color.Theme.textPrimary)
                .padding(12)
                .background(Color.Theme.bgInput)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.Theme.borderDefault, lineWidth: 1)
                )
        }
    }
}
