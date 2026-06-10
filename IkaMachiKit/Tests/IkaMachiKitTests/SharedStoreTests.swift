import Foundation
import Testing
@testable import IkaMachiKit

@Suite struct SharedStoreTests {
    private func makeStore() -> SharedStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ikamachi-test-\(UUID().uuidString)")
        return SharedStore(directory: dir)
    }

    @Test func scheduleRoundTrip() throws {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        let slots = [ScheduleSlot(mode: .x, rule: .area,
                                  stages: [Stage(id: 1, name: "ユノハナ大渓谷")],
                                  startTime: now, endTime: now.addingTimeInterval(7200))]
        try store.saveSchedule(slots, fetchedAt: now)
        let loaded = store.loadSchedule()
        #expect(loaded?.slots == slots)
        #expect(loaded?.fetchedAt == now)
    }

    @Test func conditionsRoundTrip() throws {
        let store = makeStore()
        let sets = [ConditionSet(name: "テスト", rules: [.clam], leadTimeMinutes: 20)]
        try store.saveConditions(sets)
        #expect(store.loadConditions() == sets)
    }

    @Test func emptyStoreReturnsDefaults() {
        let store = makeStore()
        #expect(store.loadSchedule() == nil)
        #expect(store.loadConditions() == [])
    }

    @Test func corruptedFileReturnsNilNotCrash() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ikamachi-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: dir.appendingPathComponent("schedule.json"))
        try Data("not json".utf8).write(to: dir.appendingPathComponent("conditions.json"))
        let store = SharedStore(directory: dir)
        #expect(store.loadSchedule() == nil)
        #expect(store.loadConditions() == [])
    }
}
