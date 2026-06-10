import Foundation

/// 通知条件セット。セット内の各要素はAND、セット同士はORで評価される。
/// 「空集合 = 制限なし」の規約。
public struct ConditionSet: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var isEnabled: Bool
    public var modes: Set<GameMode>
    public var rules: Set<GameRule>
    /// vsStageId の集合。スロットの2ステージのどちらかが含まれればマッチ。
    public var stageIDs: Set<Int>
    /// 空 = 終日。複数はOR。
    public var timeWindows: [TimeWindow]
    /// スロット開始の何分前に通知するか（0〜60）。
    public var leadTimeMinutes: Int

    public init(id: UUID = UUID(), name: String = "", isEnabled: Bool = true,
                modes: Set<GameMode> = [], rules: Set<GameRule> = [],
                stageIDs: Set<Int> = [], timeWindows: [TimeWindow] = [],
                leadTimeMinutes: Int = 10) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.modes = modes
        self.rules = rules
        self.stageIDs = stageIDs
        self.timeWindows = timeWindows
        self.leadTimeMinutes = leadTimeMinutes
    }
}
