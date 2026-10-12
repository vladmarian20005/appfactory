import Foundation
import UserNotifications

/// One local notification a day, at the hour she lays, carrying one line. Asked for when the
/// toggle is turned on and only then.
enum Reminder {
    static let id = "baize.today"

    static func lay(hour: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.body = "Today's deal is laid."
        content.sound = .default
        var when = DateComponents()
        when.hour = hour
        when.minute = 0
        let request = UNNotificationRequest(identifier: id, content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true))
        try? await center.add(request)
        return true
    }

    static func lift() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
