import SwiftUI

struct EventCard: View {
    let event: Event
    let currentUserId: Int?
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Flyer image
            if let flyerUrl = event.flyerUrl {
                CachedAsyncImage(url: flyerUrl.fullImageURL, cornerRadius: 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .padding(.bottom, -12)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(Color.Theme.textBright)

                    Spacer()

                    if event.userId == currentUserId {
                        Button {
                            onDelete?()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(Color.Theme.error)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.accent)
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(Color.Theme.textPrimary)

                    if let time = event.eventTime, !time.isEmpty {
                        Text("·")
                            .foregroundStyle(Color.Theme.textSecondary)
                        Text(time)
                            .font(.subheadline)
                            .foregroundStyle(Color.Theme.textPrimary)
                    }
                }

                if let venue = event.venue, !venue.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                            .foregroundStyle(Color.Theme.accent)
                        Text([venue, event.city].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                } else if let city = event.city, !city.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                            .foregroundStyle(Color.Theme.accent)
                        Text(city)
                            .font(.subheadline)
                            .foregroundStyle(Color.Theme.textSecondary)
                    }
                }

                if let username = event.username {
                    Text("by \(username)")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.textSecondary)
                }
            }
            .padding(14)
        }
        .background(Color.Theme.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.Theme.borderDefault, lineWidth: 1)
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: event.eventDate) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .none
            return display.string(from: date)
        }
        return event.eventDate
    }
}
