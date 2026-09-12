import Foundation
import UserNotifications

/// The daily reminder: off by default, set in Settings, and it names work rather than guilt.
///
/// There is no streak in this app, so there is nothing to break and nothing to be warned
/// about. The notification says what is waiting at the bench and stops there.
enum Reminder {
    static let enabledKey = "thousand.reminder.on"
    static let hourKey = "thousand.reminder.hour"
    private static let identifier = "thousand.bench"

    static func label(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    static func set(on: Bool, hour: Int, ready: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard on else { return }

        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Thousand"
            content.body = Voice.reminder(ready: max(ready, 1))
            content.sound = .default

            var when = DateComponents()
            when.hour = hour
            when.minute = 0
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true))
            center.add(request)
        }
    }
}
