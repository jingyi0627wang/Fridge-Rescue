import Foundation

/// Every fridge food, including previously saved food, can shake once per app session.
/// Only animation state lives here; food and account data are unchanged.
struct FridgeArrivalTracker {
    private var played: Set<UUID> = []

    mutating func markAdded(_ id: UUID) { played.remove(id) }

    /// First visible appearance returns true; later scrolling/tab visits return false.
    mutating func consume(_ id: UUID) -> Bool { played.insert(id).inserted }

    mutating func remove(_ id: UUID) { played.remove(id) }
}
