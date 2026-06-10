import Foundation

/// 時:分（端末ローカルタイムゾーンで解釈する壁時計時刻）。
public struct HourMinute: Codable, Hashable, Sendable, Comparable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public var minutesFromMidnight: Int { hour * 60 + minute }

    public static func < (lhs: HourMinute, rhs: HourMinute) -> Bool {
        lhs.minutesFromMidnight < rhs.minutesFromMidnight
    }
}

/// 通知対象の時間帯。start > end の場合は日跨ぎ（例 22:00-02:00）。
public struct TimeWindow: Codable, Hashable, Sendable {
    public var start: HourMinute
    public var end: HourMinute
    /// Calendar.weekday 準拠（1=日曜…7=土曜）。空 = 毎日。
    public var weekdays: Set<Int>

    public init(start: HourMinute, end: HourMinute, weekdays: Set<Int> = []) {
        self.start = start
        self.end = end
        self.weekdays = weekdays
    }

    public var crossesMidnight: Bool { end < start }
}
