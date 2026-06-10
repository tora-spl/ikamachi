import Foundation

/// スロットとマッチした条件セットの組。
public struct Match: Hashable, Sendable {
    public let slot: ScheduleSlot
    public let conditionSets: [ConditionSet]

    public init(slot: ScheduleSlot, conditionSets: [ConditionSet]) {
        self.slot = slot
        self.conditionSets = conditionSets
    }
}

/// 条件セットとスケジュールのマッチングを行う純粋ロジック。
public enum ConditionEngine {
    /// セット内AND・空集合=制限なし の規約で1スロットを判定する。
    public static func matches(slot: ScheduleSlot, condition: ConditionSet,
                               calendar: Calendar) -> Bool {
        guard condition.isEnabled else { return false }
        if !condition.modes.isEmpty, !condition.modes.contains(slot.mode) { return false }
        if !condition.rules.isEmpty, !condition.rules.contains(slot.rule) { return false }
        if !condition.stageIDs.isEmpty,
           !slot.stages.contains(where: { condition.stageIDs.contains($0.id) }) { return false }
        if !condition.timeWindows.isEmpty,
           !condition.timeWindows.contains(where: { overlaps(slot: slot, window: $0, calendar: calendar) }) {
            return false
        }
        return true
    }

    /// 全スロット×全条件セットを評価し、1つ以上マッチしたスロットだけ返す。
    /// conditionSetsの順序は入力順を保つ。
    public static func match(slots: [ScheduleSlot], conditions: [ConditionSet],
                             calendar: Calendar) -> [Match] {
        slots.compactMap { slot in
            let hit = conditions.filter { matches(slot: slot, condition: $0, calendar: calendar) }
            return hit.isEmpty ? nil : Match(slot: slot, conditionSets: hit)
        }
    }

    /// スロットの開催時間と時間帯窓が重なるか（端点一致は重なりとみなさない）。
    /// 窓はスロット開始日の前日・当日それぞれを起点に実時刻へ展開して判定する。
    /// 日跨ぎ窓は終了側を翌日に延長する。weekday指定は窓の開始側の曜日基準。
    private static func overlaps(slot: ScheduleSlot, window: TimeWindow,
                                 calendar: Calendar) -> Bool {
        // 前日起点（日跨ぎ窓が当日早朝に食い込むケース）と当日起点を試す
        for dayOffset in [-1, 0] {
            guard let baseDay = calendar.date(byAdding: .day, value: dayOffset,
                                              to: calendar.startOfDay(for: slot.startTime)) else { continue }
            if !window.weekdays.isEmpty {
                let weekday = calendar.component(.weekday, from: baseDay)
                if !window.weekdays.contains(weekday) { continue }
            }
            let windowStart = baseDay.addingTimeInterval(TimeInterval(window.start.minutesFromMidnight * 60))
            var endMinutes = window.end.minutesFromMidnight
            if window.crossesMidnight { endMinutes += 24 * 60 }
            let windowEnd = baseDay.addingTimeInterval(TimeInterval(endMinutes * 60))
            if slot.startTime < windowEnd && windowStart < slot.endTime {
                return true
            }
        }
        return false
    }
}
