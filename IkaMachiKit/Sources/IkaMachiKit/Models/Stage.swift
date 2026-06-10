import Foundation

/// ステージ。idは対戦ステージなら splatoon3.ink の vsStageId。
/// サーモンランのステージはvsStageIdを持たないため、名前から導出した負のIDを使う。
public struct Stage: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    /// サーモンランステージ用の安定した負ID。
    public static func coopID(name: String) -> Int {
        var hash = 0
        for byte in name.utf8 {
            hash = (hash &* 31 &+ Int(byte)) & 0x7FFF_FFFF
        }
        return -hash - 1
    }
}
