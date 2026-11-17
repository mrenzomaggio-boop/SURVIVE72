import Foundation
import UserNotifications

/// A notification shown when an alert or a private message reaches this phone.
struct MeshNotice: Equatable {
    let id: UUID
    let title: String
    let body: String
    let isSOS: Bool
}

/// Shows mesh notifications. A protocol so tests never touch the system.
protocol MeshNotifier: AnyObject {
    func requestPermission()
    func post(_ notice: MeshNotice)
}

/// Local notifications from iOS. They need no internet and no server: they
/// are created on this phone when a packet arrives. iOS keeps the phone-to-phone
/// link only while the app is open, so they mostly show as banners in the app
/// or right after leaving it.
final class LocalMeshNotifier: NSObject, MeshNotifier, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() {
        // No permission prompt over the store screenshots.
        guard !ScreenshotMode.isOn else { return }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func post(_ notice: MeshNotice) {
        let content = UNMutableNotificationContent()
        content.title = notice.title
        content.body = notice.body
        content.sound = .default
        content.threadIdentifier = notice.isSOS ? "mesh.sos" : "mesh"
        if notice.isSOS { content.interruptionLevel = .timeSensitive }
        center.add(UNNotificationRequest(identifier: notice.id.uuidString, content: content, trigger: nil))
    }

    /// Banners also while the app is open: that is when messages arrive.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

/// Keeps notices in memory (tests and previews).
final class RecordingMeshNotifier: MeshNotifier {
    private(set) var permissionRequests = 0
    private(set) var notices: [MeshNotice] = []

    func requestPermission() { permissionRequests += 1 }
    func post(_ notice: MeshNotice) { notices.append(notice) }
}
