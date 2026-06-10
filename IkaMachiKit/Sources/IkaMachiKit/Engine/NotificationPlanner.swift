import Foundation

/// 予約すべき通知1件。idはスロットIDと同一（条件編集後も同一スロットは同一通知に収束する）。
public struct PlannedNotification: Hashable, Sendable, Identifiable {
    public let id: String
    public let fireDate: Date
    public let title: String
    public let body: String

    public init(id: String, fireDate: Date, title: String, body: String) {
        self.id = id
        self.fireDate = fireDate
        self.title = title
        self.body = body
    }
}

/// 通知の予約を同期する抽象。v1はローカル通知実装、将来APNsに差し替え可能。
public protocol NotificationScheduler: Sendable {
    /// 計画一覧を渡すと予約済みと突き合わせて追加・削除し、計画どおりの状態へ収束させる。
    func sync(_ planned: [PlannedNotification]) async
}

/// マッチ結果から通知計画を算出する純粋ロジック。
public enum NotificationPlanner {
    /// - Parameters:
    ///   - limit: iOSのローカル通知64件上限に対する安全枠。fireDate昇順で打ち切る。
    public static func plan(matches: [Match], now: Date, limit: Int = 50) -> [PlannedNotification] {
        matches.compactMap { match -> PlannedNotification? in
            let slot = match.slot
            guard slot.startTime > now else { return nil }
            let maxLead = match.conditionSets.map(\.leadTimeMinutes).max() ?? 0
            var fireDate = slot.startTime.addingTimeInterval(TimeInterval(-maxLead * 60))
            if fireDate <= now {
                fireDate = now.addingTimeInterval(5)
            }
            return PlannedNotification(
                id: slot.id,
                fireDate: fireDate,
                title: title(for: slot),
                body: body(for: match, maxLead: maxLead)
            )
        }
        .sorted { $0.fireDate < $1.fireDate }
        .prefix(limit)
        .map { $0 }
    }

    private static func title(for slot: ScheduleSlot) -> String {
        let stageNames = slot.stages.map(\.name).joined(separator: "・")
        if let eventName = slot.eventName {
            return "まもなく\(eventName) × \(stageNames)"
        }
        return "まもなく\(slot.rule.displayName) × \(stageNames)"
    }

    private static func body(for match: Match, maxLead: Int) -> String {
        let slot = match.slot
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "H:mm"
        let names = match.conditionSets.map { "「\($0.name)」" }.joined(separator: " ")
        return "\(formatter.string(from: slot.startTime))から \(slot.mode.displayName)。条件 \(names) にマッチ"
    }
}
