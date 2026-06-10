import Foundation
import Testing
@testable import IkaMachiKit

private let masaba = Stage(id: 11, name: "マサバ海峡大橋")

private func slot(startOffsetMinutes: Int, now: Date,
                  mode: GameMode = .bankaraChallenge, rule: GameRule = .area) -> ScheduleSlot {
    let start = now.addingTimeInterval(TimeInterval(startOffsetMinutes * 60))
    return ScheduleSlot(mode: mode, rule: rule, stages: [masaba],
                        startTime: start, endTime: start.addingTimeInterval(7200))
}

@Suite struct NotificationPlannerTests {
    let now = Date(timeIntervalSince1970: 1_780_000_000)

    @Test func fireDateUsesLeadTime() {
        let s = slot(startOffsetMinutes: 120, now: now)
        let cond = ConditionSet(name: "テスト", leadTimeMinutes: 15)
        let planned = NotificationPlanner.plan(
            matches: [Match(slot: s, conditionSets: [cond])], now: now)
        #expect(planned.count == 1)
        #expect(planned[0].fireDate == s.startTime.addingTimeInterval(-15 * 60))
    }

    @Test func multipleSetsUseMaxLead() {
        let s = slot(startOffsetMinutes: 120, now: now)
        let a = ConditionSet(name: "A", leadTimeMinutes: 5)
        let b = ConditionSet(name: "B", leadTimeMinutes: 30)
        let planned = NotificationPlanner.plan(
            matches: [Match(slot: s, conditionSets: [a, b])], now: now)
        #expect(planned[0].fireDate == s.startTime.addingTimeInterval(-30 * 60))
    }

    @Test func pastSlotsAreExcluded() {
        let past = slot(startOffsetMinutes: -30, now: now)
        let cond = ConditionSet(leadTimeMinutes: 10)
        let planned = NotificationPlanner.plan(
            matches: [Match(slot: past, conditionSets: [cond])], now: now)
        #expect(planned.isEmpty)
    }

    @Test func imminentSlotFiresImmediately() {
        // 開始5分前だがlead10分 → fireDateは過去になるので now+5秒 に繰り上げ
        let s = slot(startOffsetMinutes: 5, now: now)
        let cond = ConditionSet(leadTimeMinutes: 10)
        let planned = NotificationPlanner.plan(
            matches: [Match(slot: s, conditionSets: [cond])], now: now)
        #expect(planned.count == 1)
        #expect(planned[0].fireDate == now.addingTimeInterval(5))
    }

    @Test func limitTruncatesByFireDateAscending() {
        let matches = (1...10).map { i in
            Match(slot: slot(startOffsetMinutes: i * 60, now: now),
                  conditionSets: [ConditionSet(leadTimeMinutes: 10)])
        }
        let planned = NotificationPlanner.plan(matches: matches, now: now, limit: 3)
        #expect(planned.count == 3)
        #expect(planned == planned.sorted { $0.fireDate < $1.fireDate })
        #expect(planned[0].fireDate < planned[2].fireDate)
    }

    @Test func idIsDeterministicAndConditionIndependent() {
        let s = slot(startOffsetMinutes: 120, now: now)
        let a = NotificationPlanner.plan(
            matches: [Match(slot: s, conditionSets: [ConditionSet(name: "A")])], now: now)
        let b = NotificationPlanner.plan(
            matches: [Match(slot: s, conditionSets: [ConditionSet(name: "B", leadTimeMinutes: 30)])], now: now)
        #expect(a[0].id == b[0].id)
        #expect(a[0].id == s.id)
    }

    @Test func contentMentionsRuleStageAndConditionName() {
        let s = slot(startOffsetMinutes: 120, now: now)
        let cond = ConditionSet(name: "夜エリア")
        let planned = NotificationPlanner.plan(
            matches: [Match(slot: s, conditionSets: [cond])], now: now)
        #expect(planned[0].title.contains("ガチエリア"))
        #expect(planned[0].title.contains("マサバ海峡大橋"))
        #expect(planned[0].body.contains("夜エリア"))
    }
}
