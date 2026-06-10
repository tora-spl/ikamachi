import Foundation
import Testing
@testable import IkaMachiKit

/// JST固定のカレンダー。テストの決定論性のためタイムゾーンを固定する。
private let jst: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return cal
}()

/// JSTの日時からDateを作る。
private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> Date {
    jst.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
}

private let masaba = Stage(id: 11, name: "マサバ海峡大橋")
private let yunohana = Stage(id: 2, name: "ユノハナ大渓谷")
private let gonzui = Stage(id: 5, name: "ゴンズイ地区")

/// 2026-06-12(金) 20:00-22:00 JST バンカラチャレンジ・エリア・マサバ/ユノハナ
private let fridayNightSlot = ScheduleSlot(
    mode: .bankaraChallenge, rule: .area, stages: [masaba, yunohana],
    startTime: date(2026, 6, 12, 20), endTime: date(2026, 6, 12, 22))

@Suite struct ConditionEngineTests {
    @Test func emptyConditionMatchesEverything() {
        let cond = ConditionSet()
        #expect(ConditionEngine.matches(slot: fridayNightSlot, condition: cond, calendar: jst))
    }

    @Test func modeFilter() {
        #expect(ConditionEngine.matches(
            slot: fridayNightSlot,
            condition: ConditionSet(modes: [.bankaraChallenge]), calendar: jst))
        #expect(!ConditionEngine.matches(
            slot: fridayNightSlot,
            condition: ConditionSet(modes: [.x]), calendar: jst))
    }

    @Test func ruleFilter() {
        #expect(ConditionEngine.matches(
            slot: fridayNightSlot, condition: ConditionSet(rules: [.area]), calendar: jst))
        #expect(!ConditionEngine.matches(
            slot: fridayNightSlot, condition: ConditionSet(rules: [.tower]), calendar: jst))
    }

    @Test func stageMatchesIfEitherStageIncluded() {
        #expect(ConditionEngine.matches(
            slot: fridayNightSlot, condition: ConditionSet(stageIDs: [masaba.id]), calendar: jst))
        #expect(ConditionEngine.matches(
            slot: fridayNightSlot, condition: ConditionSet(stageIDs: [yunohana.id, 99]), calendar: jst))
        #expect(!ConditionEngine.matches(
            slot: fridayNightSlot, condition: ConditionSet(stageIDs: [gonzui.id]), calendar: jst))
    }

    @Test func timeWindowOverlap() {
        // スロット 20:00-22:00
        let inside = TimeWindow(start: HourMinute(hour: 20, minute: 0), end: HourMinute(hour: 24, minute: 0))
        let partial = TimeWindow(start: HourMinute(hour: 21, minute: 0), end: HourMinute(hour: 23, minute: 0))
        let outside = TimeWindow(start: HourMinute(hour: 8, minute: 0), end: HourMinute(hour: 12, minute: 0))
        // 端点一致（22:00開始の窓）は重なりとみなさない
        let edge = TimeWindow(start: HourMinute(hour: 22, minute: 0), end: HourMinute(hour: 23, minute: 0))
        #expect(ConditionEngine.matches(slot: fridayNightSlot, condition: ConditionSet(timeWindows: [inside]), calendar: jst))
        #expect(ConditionEngine.matches(slot: fridayNightSlot, condition: ConditionSet(timeWindows: [partial]), calendar: jst))
        #expect(!ConditionEngine.matches(slot: fridayNightSlot, condition: ConditionSet(timeWindows: [outside]), calendar: jst))
        #expect(!ConditionEngine.matches(slot: fridayNightSlot, condition: ConditionSet(timeWindows: [edge]), calendar: jst))
    }

    @Test func midnightCrossingWindow() {
        let lateNight = TimeWindow(start: HourMinute(hour: 22, minute: 0), end: HourMinute(hour: 2, minute: 0))
        // 23:00-01:00 のスロット → マッチ
        let slot2330 = ScheduleSlot(mode: .x, rule: .tower, stages: [masaba],
                                    startTime: date(2026, 6, 12, 23), endTime: date(2026, 6, 13, 1))
        // 01:00-03:00 のスロット → 前日窓の延長部分(〜02:00)に重なる
        let slot0100 = ScheduleSlot(mode: .x, rule: .tower, stages: [masaba],
                                    startTime: date(2026, 6, 13, 1), endTime: date(2026, 6, 13, 3))
        // 10:00-12:00 → 不一致
        let slot1000 = ScheduleSlot(mode: .x, rule: .tower, stages: [masaba],
                                    startTime: date(2026, 6, 13, 10), endTime: date(2026, 6, 13, 12))
        let cond = ConditionSet(timeWindows: [lateNight])
        #expect(ConditionEngine.matches(slot: slot2330, condition: cond, calendar: jst))
        #expect(ConditionEngine.matches(slot: slot0100, condition: cond, calendar: jst))
        #expect(!ConditionEngine.matches(slot: slot1000, condition: cond, calendar: jst))
    }

    @Test func weekdayFilter() {
        // fridayNightSlot は金曜(weekday=6)
        let fridayOnly = TimeWindow(start: HourMinute(hour: 0, minute: 0),
                                    end: HourMinute(hour: 24, minute: 0), weekdays: [6])
        let mondayOnly = TimeWindow(start: HourMinute(hour: 0, minute: 0),
                                    end: HourMinute(hour: 24, minute: 0), weekdays: [2])
        #expect(ConditionEngine.matches(slot: fridayNightSlot, condition: ConditionSet(timeWindows: [fridayOnly]), calendar: jst))
        #expect(!ConditionEngine.matches(slot: fridayNightSlot, condition: ConditionSet(timeWindows: [mondayOnly]), calendar: jst))
    }

    @Test func midnightCrossingWeekdayIsBasedOnWindowStartDay() {
        // 金曜22:00開始の日跨ぎ窓。土曜01:00のスロットも「金曜の窓」としてマッチする
        let fridayLate = TimeWindow(start: HourMinute(hour: 22, minute: 0),
                                    end: HourMinute(hour: 2, minute: 0), weekdays: [6])
        let saturdayEarly = ScheduleSlot(mode: .x, rule: .tower, stages: [masaba],
                                         startTime: date(2026, 6, 13, 1), endTime: date(2026, 6, 13, 3))
        #expect(ConditionEngine.matches(slot: saturdayEarly, condition: ConditionSet(timeWindows: [fridayLate]), calendar: jst))
    }

    @Test func disabledConditionNeverMatches() {
        let cond = ConditionSet(isEnabled: false)
        #expect(!ConditionEngine.matches(slot: fridayNightSlot, condition: cond, calendar: jst))
    }

    @Test func multipleWindowsAreOR() {
        let morning = TimeWindow(start: HourMinute(hour: 8, minute: 0), end: HourMinute(hour: 10, minute: 0))
        let night = TimeWindow(start: HourMinute(hour: 20, minute: 0), end: HourMinute(hour: 22, minute: 0))
        #expect(ConditionEngine.matches(
            slot: fridayNightSlot, condition: ConditionSet(timeWindows: [morning, night]), calendar: jst))
    }

    @Test func matchCollectsAllMatchingSets() {
        let setA = ConditionSet(name: "A", rules: [.area])
        let setB = ConditionSet(name: "B", stageIDs: [masaba.id])
        let setC = ConditionSet(name: "C", modes: [.salmonRun])
        let matches = ConditionEngine.match(slots: [fridayNightSlot],
                                            conditions: [setA, setB, setC], calendar: jst)
        #expect(matches.count == 1)
        #expect(matches[0].slot == fridayNightSlot)
        #expect(matches[0].conditionSets.map(\.name) == ["A", "B"])
    }

    @Test func noMatchProducesNoEntry() {
        let cond = ConditionSet(modes: [.salmonRun])
        let matches = ConditionEngine.match(slots: [fridayNightSlot], conditions: [cond], calendar: jst)
        #expect(matches.isEmpty)
    }
}
