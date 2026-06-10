import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// splatoon3.ink からスケジュールを取得し、ScheduleSlot に正規化するクライアント。
public struct ScheduleClient: Sendable {
    public static let endpoint = URL(string: "https://splatoon3.ink/data/schedules.json")!

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch() async throws -> [ScheduleSlot] {
        var request = URLRequest(url: Self.endpoint)
        // splatoon3.ink の利用ガイドラインに従いUser-Agentで連絡先を明示
        request.setValue("IkaMachi/1.0 (https://github.com/tora-spl/ikamachi)",
                         forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return Self.normalize(try Self.decode(data))
    }

    public static func decode(_ data: Data) throws -> InkSchedulesResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(InkSchedulesResponse.self, from: data)
    }

    /// APIレスポンスをモード横断の正規化スロット一覧に変換する。
    /// フェス中などでsettingがnullのノードはスキップする。
    public static func normalize(_ response: InkSchedulesResponse) -> [ScheduleSlot] {
        var slots: [ScheduleSlot] = []
        let d = response.data

        for node in d.regularSchedules.nodes {
            guard let setting = node.regularMatchSetting else { continue }
            slots.append(slot(mode: .regular, setting: setting,
                              start: node.startTime, end: node.endTime))
        }

        for node in d.bankaraSchedules.nodes {
            for setting in node.bankaraMatchSettings ?? [] {
                let mode: GameMode = setting.bankaraMode == "OPEN" ? .bankaraOpen : .bankaraChallenge
                slots.append(slot(mode: mode, setting: setting,
                                  start: node.startTime, end: node.endTime))
            }
        }

        for node in d.xSchedules.nodes {
            guard let setting = node.xMatchSetting else { continue }
            slots.append(slot(mode: .x, setting: setting,
                              start: node.startTime, end: node.endTime))
        }

        for node in d.eventSchedules.nodes {
            guard let setting = node.leagueMatchSetting else { continue }
            let stages = setting.vsStages.map { Stage(id: $0.vsStageId, name: $0.name) }
            let rule = GameRule(inkRule: setting.vsRule.rule) ?? .turfWar
            for period in node.timePeriods {
                slots.append(ScheduleSlot(mode: .event, rule: rule, stages: stages,
                                          startTime: period.startTime, endTime: period.endTime,
                                          eventName: setting.leagueMatchEvent?.name))
            }
        }

        let coopNodes = d.coopGroupingSchedule.regularSchedules.nodes
            + (d.coopGroupingSchedule.bigRunSchedules?.nodes ?? [])
        for node in coopNodes {
            guard let setting = node.setting else { continue }
            let stage = Stage(id: Stage.coopID(name: setting.coopStage.name),
                              name: setting.coopStage.name)
            slots.append(ScheduleSlot(mode: .salmonRun, rule: .salmonRun, stages: [stage],
                                      startTime: node.startTime, endTime: node.endTime))
        }

        return slots.sorted { $0.startTime < $1.startTime }
    }

    private static func slot(mode: GameMode, setting: InkMatchSetting,
                             start: Date, end: Date) -> ScheduleSlot {
        ScheduleSlot(
            mode: mode,
            rule: GameRule(inkRule: setting.vsRule.rule) ?? .turfWar,
            stages: setting.vsStages.map { Stage(id: $0.vsStageId, name: $0.name) },
            startTime: start, endTime: end)
    }
}
