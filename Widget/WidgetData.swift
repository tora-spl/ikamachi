import Foundation
import WidgetKit
import SwiftUI
import IkaMachiKit

/// ウィジェット共通のデータ読み込み。ネットワークには行かず共有キャッシュのみ参照する。
enum WidgetData {
    static func load() -> (slots: [ScheduleSlot], matches: [Match], isStale: Bool) {
        guard let store = SharedStore.appGroup(),
              let cached = store.loadSchedule() else {
            return ([], [], true)
        }
        let now = Date()
        let slots = cached.slots.filter { $0.endTime > now }
        let conditions = store.loadConditions()
        let matches = ConditionEngine.match(slots: slots, conditions: conditions, calendar: .current)
        // 2日以上更新が無ければ古い扱い
        let isStale = now.timeIntervalSince(cached.fetchedAt) > 2 * 86400
        return (slots, matches, isStale)
    }

    /// スロット境界ごとにタイムラインを刻むための日付列。
    static func timelineDates(slots: [ScheduleSlot], now: Date, limit: Int = 12) -> [Date] {
        var dates: Set<Date> = [now]
        for slot in slots {
            if slot.startTime > now { dates.insert(slot.startTime) }
            if slot.endTime > now { dates.insert(slot.endTime) }
        }
        return dates.sorted().prefix(limit).map { $0 }
    }

    static func stageImage(forVsStageId id: Int) -> Image? {
        guard let commonsID = StageCatalog.shared.commonsID(forVsStageId: id),
              let url = Bundle.main.url(forResource: commonsID, withExtension: "png",
                                        subdirectory: "Commons/stages"),
              let uiImage = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: uiImage)
    }
}
