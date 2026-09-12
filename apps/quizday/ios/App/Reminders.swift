import Foundation
import UserNotifications

/// The one notification Quizday sends: a daily nudge at a time the player picks.
/// Nothing is scheduled unless the player turns it on.
enum Reminders {
    static let identifier = "quizday.daily"

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Replaces any existing reminder with a daily one at the given hour and minute.
    static func schedule(hour: Int, minute: Int) async {
        cancel()
        let content = UNMutableNotificationContent()
        content.title = "Today's edition is on the step."
        content.body = "Ten questions, two minutes. Round \(DailyPack.editionNumber(for: .now))."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
