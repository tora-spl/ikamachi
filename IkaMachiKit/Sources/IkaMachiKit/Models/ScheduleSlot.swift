import Foundation

/// 全モードを正規化したスケジュールスロット。
public struct ScheduleSlot: Codable, Hashable, Sendable, Identifiable {
    public let mode: GameMode
    public let rule: GameRule
    public let stages: [Stage]
    public let startTime: Date
    public let endTime: Date
    /// イベントマッチのイベント名（その他のモードはnil）。
    public let eventName: String?

    public init(mode: GameMode, rule: GameRule, stages: [Stage],
                startTime: Date, endTime: Date, eventName: String? = nil) {
        self.mode = mode
        self.rule = rule
        self.stages = stages
        self.startTime = startTime
        self.endTime = endTime
        self.eventName = eventName
    }

    public var id: String {
        "\(mode.rawValue)-\(Int(startTime.timeIntervalSince1970))"
    }
}
