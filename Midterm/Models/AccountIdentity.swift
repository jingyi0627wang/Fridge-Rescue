import Foundation

/// Preserve the same Firebase login address on every device, including existing accounts.
enum AccountIdentity {
    static func normalizedUsername(_ username: String) -> String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func email(for username: String) -> String {
        normalizedUsername(username) + "@freshlings.com"
    }

    static func isValidUsername(_ username: String) -> Bool {
        let name = normalizedUsername(username)
        return !name.isEmpty && !name.contains("@") &&
            name.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
