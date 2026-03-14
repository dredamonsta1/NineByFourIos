import Foundation
import Observation

@Observable
final class EventsViewModel {
    var events: [Event] = []
    var isLoading = false
    var errorMessage: String?

    // Create event state
    var newTitle = ""
    var newDate = Date()
    var newTime = ""
    var newVenue = ""
    var newCity = ""
    var isCreating = false

    @MainActor
    func loadEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            events = try await APIClient.shared.request(endpoint: .events)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load events."
        }

        isLoading = false
    }

    @MainActor
    func createEvent() async -> Bool {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        isCreating = true
        defer { isCreating = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        do {
            let body = CreateEventBody(
                title: newTitle,
                eventDate: formatter.string(from: newDate),
                eventTime: newTime.isEmpty ? nil : newTime,
                venue: newVenue.isEmpty ? nil : newVenue,
                city: newCity.isEmpty ? nil : newCity
            )
            let _: Event = try await APIClient.shared.request(endpoint: .createEvent, body: body)
            newTitle = ""
            newDate = Date()
            newTime = ""
            newVenue = ""
            newCity = ""
            await loadEvents()
            return true
        } catch {
            errorMessage = "Failed to create event."
            return false
        }
    }

    @MainActor
    func deleteEvent(id: Int) async {
        do {
            try await APIClient.shared.requestVoid(endpoint: .deleteEvent(id: id))
            events.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete event."
        }
    }
}

private struct CreateEventBody: Encodable {
    let title: String
    let eventDate: String
    let eventTime: String?
    let venue: String?
    let city: String?

    enum CodingKeys: String, CodingKey {
        case title
        case eventDate = "event_date"
        case eventTime = "event_time"
        case venue
        case city
    }
}
