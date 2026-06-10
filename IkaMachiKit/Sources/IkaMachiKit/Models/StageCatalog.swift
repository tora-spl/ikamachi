import Foundation

/// vsStageId → 日本語名・commons画像ID の対応カタログ。
/// 元データは Resources/stage-map.json（splatoon3.ink ja-JPロケール × splatoon-commonsから生成）。
public struct StageCatalog: Sendable {
    public struct Entry: Codable, Hashable, Sendable {
        public let vsStageId: Int
        public let name: String
        public let commonsId: String?
    }

    public static let shared = StageCatalog()

    public let all: [Entry]
    private let byID: [Int: Entry]

    init() {
        let url = Bundle.module.url(forResource: "Resources/stage-map", withExtension: "json")
        let entries = url.flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode([Entry].self, from: $0) } ?? []
        self.all = entries
        self.byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.vsStageId, $0) })
    }

    public func name(forVsStageId id: Int) -> String? {
        byID[id]?.name
    }

    public func commonsID(forVsStageId id: Int) -> String? {
        byID[id]?.commonsId
    }

    /// スロットのステージ名を日本語化する。未知IDはAPIの英語名のまま。
    public func localize(_ slot: ScheduleSlot) -> ScheduleSlot {
        ScheduleSlot(
            mode: slot.mode, rule: slot.rule,
            stages: slot.stages.map { Stage(id: $0.id, name: name(forVsStageId: $0.id) ?? $0.name) },
            startTime: slot.startTime, endTime: slot.endTime, eventName: slot.eventName)
    }
}
