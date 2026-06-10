import Foundation

/// App / Widget 間で共有するファイルベースのストア。
/// 本番は App Groups コンテナ、テストは一時ディレクトリを渡す。
public struct SharedStore: Sendable {
    public static let appGroupID = "group.com.tora.ikamachi"

    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// App Groupsコンテナを使う本番用ストア。コンテナ取得失敗時はnil。
    public static func appGroup() -> SharedStore? {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else { return nil }
        return SharedStore(directory: url.appendingPathComponent("Store", isDirectory: true))
    }

    private var scheduleURL: URL { directory.appendingPathComponent("schedule.json") }
    private var conditionsURL: URL { directory.appendingPathComponent("conditions.json") }

    private struct ScheduleCache: Codable {
        let slots: [ScheduleSlot]
        let fetchedAt: Date
    }

    public func saveSchedule(_ slots: [ScheduleSlot], fetchedAt: Date) throws {
        try write(ScheduleCache(slots: slots, fetchedAt: fetchedAt), to: scheduleURL)
    }

    public func loadSchedule() -> (slots: [ScheduleSlot], fetchedAt: Date)? {
        guard let cache: ScheduleCache = read(scheduleURL) else { return nil }
        return (cache.slots, cache.fetchedAt)
    }

    public func saveConditions(_ sets: [ConditionSet]) throws {
        try write(sets, to: conditionsURL)
    }

    public func loadConditions() -> [ConditionSet] {
        read(conditionsURL) ?? []
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    private func read<T: Decodable>(_ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(T.self, from: data)
    }
}
