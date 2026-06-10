import Foundation
import Testing
@testable import IkaMachiKit

private func loadFixture() throws -> InkSchedulesResponse {
    let url = Bundle.module.url(forResource: "Fixtures/schedules", withExtension: "json")!
    let data = try Data(contentsOf: url)
    return try ScheduleClient.decode(data)
}

@Suite struct ScheduleClientTests {
    @Test func fixtureDecodes() throws {
        _ = try loadFixture()
    }

    @Test func normalizeProducesAllModes() throws {
        let slots = ScheduleClient.normalize(try loadFixture())
        let byMode = Dictionary(grouping: slots, by: \.mode)
        #expect(byMode[.regular]?.count == 12)
        #expect(byMode[.bankaraChallenge]?.count == 12)
        #expect(byMode[.bankaraOpen]?.count == 12)
        #expect(byMode[.x]?.count == 12)
        #expect(byMode[.event]?.count == 7)   // 2イベント × timePeriods(6+1)
        #expect(byMode[.salmonRun]?.count == 5)
    }

    @Test func regularIsTurfWar() throws {
        let slots = ScheduleClient.normalize(try loadFixture())
        #expect(slots.filter { $0.mode == .regular }.allSatisfy { $0.rule == .turfWar })
    }

    @Test func bankaraSplitsIntoChallengeAndOpen() throws {
        let slots = ScheduleClient.normalize(try loadFixture())
        let challenge = slots.filter { $0.mode == .bankaraChallenge }.sorted { $0.startTime < $1.startTime }
        let open = slots.filter { $0.mode == .bankaraOpen }.sorted { $0.startTime < $1.startTime }
        // fixture先頭: CHALLENGE=ガチホコ(GOAL), OPEN=ガチエリア(AREA)
        #expect(challenge[0].rule == .rainmaker)
        #expect(open[0].rule == .area)
        #expect(challenge[0].startTime == open[0].startTime)
    }

    @Test func eventSlotsExpandTimePeriodsAndCarryEventName() throws {
        let slots = ScheduleClient.normalize(try loadFixture())
        let events = slots.filter { $0.mode == .event }
        #expect(events.allSatisfy { $0.eventName != nil && !$0.eventName!.isEmpty })
        // timePeriodsごとに開始時刻が異なる
        #expect(Set(events.map(\.startTime)).count == events.count)
    }

    @Test func salmonRunHasCoopStage() throws {
        let slots = ScheduleClient.normalize(try loadFixture())
        let coop = slots.filter { $0.mode == .salmonRun }
        #expect(coop.allSatisfy { $0.rule == .salmonRun && $0.stages.count == 1 })
        #expect(coop.allSatisfy { $0.stages[0].id < 0 })   // coopは負ID
    }

    @Test func timesAreParsedAsUTC() throws {
        let slots = ScheduleClient.normalize(try loadFixture())
        let first = slots.filter { $0.mode == .regular }.min { $0.startTime < $1.startTime }!
        // fixture先頭: 2026-06-10T18:00:00Z
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: first.startTime)
        #expect(comps.year == 2026 && comps.month == 6 && comps.day == 10 && comps.hour == 18)
    }

    @Test func vsStagesUseVsStageId() throws {
        let slots = ScheduleClient.normalize(try loadFixture())
        let vs = slots.filter { $0.mode != .salmonRun }
        #expect(vs.allSatisfy { $0.stages.allSatisfy { $0.id > 0 } })
        #expect(vs.allSatisfy { $0.stages.count == 2 })
    }
}
