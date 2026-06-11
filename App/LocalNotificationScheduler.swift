import Foundation
import UserNotifications
import IkaMachiKit

/// UNUserNotificationCenter への宣言的sync実装。
/// 計画にないID（条件変更で外れたスロット等）の予約は削除し、
/// 新規・変更分だけを登録し直す。
struct LocalNotificationScheduler: NotificationScheduler {
    func sync(_ planned: [PlannedNotification]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let plannedByID = Dictionary(uniqueKeysWithValues: planned.map { ($0.id, $0) })

        // 計画から消えたもの、fireDateが変わったものを削除
        var toRemove: [String] = []
        var unchanged: Set<String> = []
        for request in pending {
            guard let plan = plannedByID[request.identifier] else {
                toRemove.append(request.identifier)
                continue
            }
            let trigger = request.trigger as? UNCalendarNotificationTrigger
            if let fireDate = trigger?.nextTriggerDate(),
               abs(fireDate.timeIntervalSince(plan.fireDate)) < 60 {
                unchanged.insert(request.identifier)
            } else {
                toRemove.append(request.identifier)
            }
        }
        if !toRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }

        for plan in planned where !unchanged.contains(plan.id) {
            let content = UNMutableNotificationContent()
            content.title = plan.title
            content.body = plan.body
            content.sound = .default
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second], from: plan.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: plan.id,
                                                        content: content, trigger: trigger))
        }
    }
}
