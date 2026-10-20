import Foundation
import UserNotifications

final class ExpirationNotificationService {
    static let shared = ExpirationNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let reminderHour = 9

    // Settings (Settings → Reminder preferences). Same keys as SettingsView's @AppStorage.
    static let enabledKey = "expirationRemindersEnabled"
    static let daysBeforeKey = "reminderDaysBefore"

    /// On by default (matches the toggle's default).
    private var remindersEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// How many days before expiration to remind (default 3).
    private var reminderDays: Int {
        let days = UserDefaults.standard.integer(forKey: Self.daysBeforeKey)
        return days > 0 ? days : 3
    }

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

        guard isAuthorized, remindersEnabled else { return }

        let pendingIdentifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
        let deliveredIdentifiers = Set(await center.deliveredNotifications().map { $0.request.identifier })

        for item in items {
            let identifier = notificationIdentifier(for: item)
            guard !pendingIdentifiers.contains(identifier),
                  !deliveredIdentifiers.contains(identifier) else { continue }
            await schedule(for: item)
        }
    }

    /// Call after the reminder settings change: removes every waiting food
    /// reminder and schedules them again with the new settings.
    /// (Reminders whose new time has already passed are skipped, so changing
    /// the setting doesn't send a burst of notifications at once.)
    func rescheduleAll(items: [FoodItem]) async {
        let pending = await center.pendingNotificationRequests()
        let foodIDs = pending.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: foodIDs)

        guard remindersEnabled else { return }

        let delivered = Set(await center.deliveredNotifications().map { $0.request.identifier })
        for item in items where item.status == .active {
            guard !delivered.contains(notificationIdentifier(for: item)) else { continue }
            await schedule(for: item, sendNowIfLate: false)
        }
    }

    /// `sendNowIfLate`: if the reminder time has already passed (e.g. the food
    /// was added 1 day before it expires), send the reminder right away.
    func schedule(for item: FoodItem, sendNowIfLate: Bool = true) async {
        guard remindersEnabled else { return }
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

        let isLate = scheduledDate <= Date()
        if isLate && !sendNowIfLate { return }

        // The text is written now but shown later, so count the days from
        // the day the reminder will actually appear (not from today).
        let deliveryDay = isLate ? today : calendar.startOfDay(for: scheduledDate)

        let content = UNMutableNotificationContent()
        content.title = "Use \(item.name) soon"
        content.body = reminderBody(for: item, expirationDay: expirationDay, deliveryDay: deliveryDay)
        content.sound = .default
        content.userInfo = ["foodItemID": item.id.uuidString]

        let trigger: UNNotificationTrigger
        if !isLate {
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: scheduledDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            // The item was added after its reminder time had already passed.
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

    private static let identifierPrefix = "food-expiration-"

    private func notificationIdentifier(for item: FoodItem) -> String {
        Self.identifierPrefix + item.id.uuidString
    }

    private func reminderBody(for item: FoodItem, expirationDay: Date, deliveryDay: Date) -> String {
        let daysLeft = Calendar.current.dateComponents(
            [.day],
            from: deliveryDay,
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
