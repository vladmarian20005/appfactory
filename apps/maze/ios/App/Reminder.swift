import Foundation
import UserNotifications

/// One local notification a day, off unless he pins it. It carries one line and only that
/// line: no count of days missed, no question, no request.
enum Reminder {
    static let id = "lacework.reminder"

    /// Asks for permission then and only then, and schedules the reminder at `hour`.
    static func pin(hour: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.body = Voice.reminder
        var when = DateComponents()
        when.hour = hour
        when.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        return true
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
