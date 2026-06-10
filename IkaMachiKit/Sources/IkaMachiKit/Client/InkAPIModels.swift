import Foundation

// splatoon3.ink /data/schedules.json のデコード用モデル。
// フェス開催中は各settingがnullになるため、設定類はすべてOptional。

public struct InkSchedulesResponse: Decodable, Sendable {
    public let data: InkData
}

public struct InkData: Decodable, Sendable {
    public let regularSchedules: InkNodes<InkRegularNode>
    public let bankaraSchedules: InkNodes<InkBankaraNode>
    public let xSchedules: InkNodes<InkXNode>
    public let eventSchedules: InkNodes<InkEventNode>
    public let coopGroupingSchedule: InkCoopGrouping
}

public struct InkNodes<T: Decodable & Sendable>: Decodable, Sendable {
    public let nodes: [T]
}

public struct InkVsStage: Decodable, Sendable {
    public let vsStageId: Int
    public let name: String
}

public struct InkVsRule: Decodable, Sendable {
    public let rule: String
    public let name: String
}

public struct InkMatchSetting: Decodable, Sendable {
    public let vsStages: [InkVsStage]
    public let vsRule: InkVsRule
    public let bankaraMode: String?   // CHALLENGE | OPEN（バンカラのみ）
}

public struct InkRegularNode: Decodable, Sendable {
    public let startTime: Date
    public let endTime: Date
    public let regularMatchSetting: InkMatchSetting?
}

public struct InkBankaraNode: Decodable, Sendable {
    public let startTime: Date
    public let endTime: Date
    public let bankaraMatchSettings: [InkMatchSetting]?
}

public struct InkXNode: Decodable, Sendable {
    public let startTime: Date
    public let endTime: Date
    public let xMatchSetting: InkMatchSetting?
}

public struct InkEventNode: Decodable, Sendable {
    public let leagueMatchSetting: InkLeagueMatchSetting?
    public let timePeriods: [InkTimePeriod]
}

public struct InkLeagueMatchSetting: Decodable, Sendable {
    public let vsStages: [InkVsStage]
    public let vsRule: InkVsRule
    public let leagueMatchEvent: InkLeagueMatchEvent?
}

public struct InkLeagueMatchEvent: Decodable, Sendable {
    public let name: String
}

public struct InkTimePeriod: Decodable, Sendable {
    public let startTime: Date
    public let endTime: Date
}

public struct InkCoopGrouping: Decodable, Sendable {
    public let regularSchedules: InkNodes<InkCoopNode>
    public let bigRunSchedules: InkNodes<InkCoopNode>?
}

public struct InkCoopNode: Decodable, Sendable {
    public let startTime: Date
    public let endTime: Date
    public let setting: InkCoopSetting?
}

public struct InkCoopSetting: Decodable, Sendable {
    public let coopStage: InkCoopStage
}

public struct InkCoopStage: Decodable, Sendable {
    public let name: String
}
