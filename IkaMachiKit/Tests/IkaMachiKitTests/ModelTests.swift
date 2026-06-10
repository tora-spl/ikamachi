import Foundation
import Testing
@testable import IkaMachiKit

@Suite struct ModelTests {
    @Test func gameRuleFromInkRule() {
        #expect(GameRule(inkRule: "TURF_WAR") == .turfWar)
        #expect(GameRule(inkRule: "AREA") == .area)
        #expect(GameRule(inkRule: "LOFT") == .tower)
        #expect(GameRule(inkRule: "GOAL") == .rainmaker)
        #expect(GameRule(inkRule: "CLAM") == .clam)
        #expect(GameRule(inkRule: "UNKNOWN") == nil)
    }

    @Test func conditionSetJSONRoundTrip() throws {
        let set = ConditionSet(
            id: UUID(),
            name: "夜のマサバエリア",
            isEnabled: true,
            modes: [.bankaraChallenge],
            rules: [.area],
            stageIDs: [11],
            timeWindows: [TimeWindow(start: HourMinute(hour: 20, minute: 0),
                                     end: HourMinute(hour: 24, minute: 0))],
            leadTimeMinutes: 10
        )
        let data = try JSONEncoder().encode(set)
        let decoded = try JSONDecoder().decode(ConditionSet.self, from: data)
        #expect(set == decoded)
    }

    @Test func hourMinuteComparable() {
        #expect(HourMinute(hour: 9, minute: 30) < HourMinute(hour: 10, minute: 0))
        #expect(HourMinute(hour: 9, minute: 30) < HourMinute(hour: 9, minute: 45))
        #expect(!(HourMinute(hour: 10, minute: 0) < HourMinute(hour: 10, minute: 0)))
    }

    @Test func scheduleSlotIDIsDeterministic() {
        let start = Date(timeIntervalSince1970: 1_770_000_000)
        let a = ScheduleSlot(mode: .x, rule: .clam, stages: [], startTime: start,
                             endTime: start.addingTimeInterval(7200))
        let b = ScheduleSlot(mode: .x, rule: .clam, stages: [], startTime: start,
                             endTime: start.addingTimeInterval(7200))
        #expect(a.id == b.id)
    }
}
