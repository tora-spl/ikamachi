import Foundation
import Testing
@testable import IkaMachiKit

@Suite struct StageCatalogTests {
    @Test func knownStageHasJapaneseNameAndCommonsID() {
        #expect(StageCatalog.shared.name(forVsStageId: 1) == "ユノハナ大渓谷")
        #expect(StageCatalog.shared.commonsID(forVsStageId: 1) == "yunohana")
    }

    @Test func unknownStageReturnsNil() {
        #expect(StageCatalog.shared.name(forVsStageId: 9999) == nil)
        #expect(StageCatalog.shared.commonsID(forVsStageId: 9999) == nil)
    }

    @Test func allEntriesLoaded() {
        #expect(StageCatalog.shared.all.count >= 25)
    }

    @Test func localizeReplacesKnownStageNames() {
        let slot = ScheduleSlot(
            mode: .x, rule: .area,
            stages: [Stage(id: 1, name: "Scorch Gorge"), Stage(id: 9999, name: "New Stage")],
            startTime: Date(), endTime: Date().addingTimeInterval(7200))
        let localized = StageCatalog.shared.localize(slot)
        #expect(localized.stages[0].name == "ユノハナ大渓谷")
        #expect(localized.stages[1].name == "New Stage")   // 未知IDは英語名フォールバック
    }
}
