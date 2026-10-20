import Foundation
import UserNotifications

final class ExpirationNotificationService {
    static let shared = ExpirationNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let reminderDays = 3
    private let reminderHour = 9

    private init() {}

    func requestAuthorizationAndSchedule(items: [FoodItem]) async {
        let settings = await center.notificationSettings()
        let isAuthorized: Bool

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }

        guard isAuthorized else { return }

        let pendingIdentifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        let deliveredIdentifiers = Set(await center.deliveredNotifications().map { $0.request.identifier })

        for item in items {
            let identifier = notificationIdentifier(for: item)
            guard !pendingIdentifiers.contains(identifier),
                  !deliveredIdentifiers.contains(identifier) else { continue }
            await schedule(for: item)
        }
    }

    func schedule(for item: FoodItem) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional ||
                settings.authorizationStatus == .ephemeral else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let expirationDay = calendar.startOfDay(for: item.expirationDate)
        guard expirationDay >= today else { return }

        let reminderDay = calendar.date(
            byAdding: .day,
            value: -reminderDays,
            to: expirationDay
        ) ?? expirationDay
        let scheduledDate = calendar.date(
            bySettingHour: reminderHour,
            minute: 0,
            second: 0,
            of: reminderDay
        ) ?? reminderDay

        let content = UNMutableNotificationContent()
        content.title = "Use \(item.name) soon"
        content.body = reminderBody(for: item, expirationDay: expirationDay, today: today)
        content.sound = .default
        content.userInfo = ["foodItemID": item.id.uuidString]

        let trigger: UNNotificationTrigger
        if scheduledDate > Date() {
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: scheduledDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            // The item was added after the three-day reminder window began.
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: item),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancel(for item: FoodItem) {
        let identifier = notificationIdentifier(for: item)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private func notificationIdentifier(for item: FoodItem) -> String {
        "food-expiration-\(item.id.uuidString)"
    }

    private func reminderBody(for item: FoodItem, expirationDay: Date, today: Date) -> String {
        let daysLeft = Calendar.current.dateComponents(
            [.day],
            from: today,
            to: expirationDay
        ).day ?? 0

        let timing: String
        switch daysLeft {
        case ...0:
            timing = "today"
        case 1:
            timing = "tomorrow"
        default:
            timing = "in \(daysLeft) days"
        }

        return "\(item.name) expires \(timing). Use it before it goes to waste."
    }
}
