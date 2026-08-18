import Foundation
import UserNotifications

/// Weekly nudges at the moment the problem actually happens.
///
/// The app is only useful at the point someone is deciding what to watch, and
/// that moment is a Friday or Saturday evening on the sofa — not whenever they
/// happen to remember the app exists. These reminders are the difference
/// between a tool people mean to use and one they actually open.
///
/// Nothing is scheduled until the user explicitly opts in. iOS only ever shows
/// the system permission dialog once, so it is never triggered on launch:
/// `NotificationPrimer` makes the case first, and the real dialog appears only
/// after someone has said yes to that.
@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    /// Where iOS currently stands. Drives the settings toggle.
    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined

    /// Set when a reminder is tapped, so Home can go straight to tonight's
    /// pick rather than dropping the user on a dashboard to find it.
    @Published var didOpenFromReminder = false

    /// Whether we've made our case yet. Asking twice is nagging, and the
    /// system dialog can't be re-shown anyway.
    private(set) var hasOffered: Bool {
        get { UserDefaults.standard.bool(forKey: offeredKey) }
        set { UserDefaults.standard.set(newValue, forKey: offeredKey) }
    }

    private let offeredKey = "notifications.hasOffered"
    private let center = UNUserNotificationCenter.current()

    /// Friday and Saturday evening — early enough to still act on it, late
    /// enough that the evening has actually started.
    private let schedule: [(id: String, weekday: Int, title: String, body: String)] = [
        (
            "weekly.friday", 6,
            "Friday night",
            "You've earned a good one. Bella's got a pick ready for you."
        ),
        (
            "weekly.saturday", 7,
            "Saturday in",
            "No plans? Perfect. Let's find you something."
        )
    ]

    private let hour = 18
    private let minute = 30

    // MARK: - Lifecycle

    /// Called once at launch so a reminder tapped from a cold start is caught.
    func start() {
        center.delegate = self
        Task { await refreshAuthorization() }
    }

    func refreshAuthorization() async {
        authorization = await center.notificationSettings().authorizationStatus
    }

    // MARK: - Opting in

    /// Shows the system dialog and, if allowed, schedules the reminders.
    /// Returns whether notifications are now on.
    @discardableResult
    func enable() async -> Bool {
        hasOffered = true

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        await refreshAuthorization()

        guard granted else { return false }
        await scheduleWeeklyReminders()
        return true
    }

    /// Records that the offer was declined, so it isn't made again.
    func declineOffer() {
        hasOffered = true
    }

    /// Whether to make the case now: only once, and only while iOS would still
    /// show the dialog.
    var shouldOfferReminders: Bool {
        !hasOffered && authorization == .notDetermined
    }

    var isEnabled: Bool {
        authorization == .authorized || authorization == .provisional
    }

    // MARK: - Scheduling

    func scheduleWeeklyReminders() async {
        cancelWeeklyReminders()

        for entry in schedule {
            var date = DateComponents()
            date.weekday = entry.weekday
            date.hour = hour
            date.minute = minute

            let content = UNMutableNotificationContent()
            content.title = entry.title
            content.body = entry.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: entry.id,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            )
            try? await center.add(request)
        }
    }

    func cancelWeeklyReminders() {
        center.removePendingNotificationRequests(withIdentifiers: schedule.map(\.id))
    }

    /// Turns reminders off without revoking permission, so they can be turned
    /// back on in the app rather than in iOS Settings.
    func disable() {
        cancelWeeklyReminders()
    }
}

// MARK: - Delegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Show the banner even with the app open — someone browsing at 6:30 on a
    /// Friday is exactly who the reminder is for.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        didOpenFromReminder = true
    }
}
