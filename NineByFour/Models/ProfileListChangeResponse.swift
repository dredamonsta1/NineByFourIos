import Foundation

/// Response to adding or removing a Top 20 artist.
///
/// Clout is the number of Top 20s an artist is in, counted on the server
/// whenever an entry is added or removed. `clout` is the new total. It's
/// optional so an older backend that doesn't send it can't fail the add.
struct ProfileListChangeResponse: Decodable, Sendable {
    let clout: Int?
}
