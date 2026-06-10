import Foundation

/// ゲームルール。サーモンランは専用値で表す。
public enum GameRule: String, Codable, CaseIterable, Hashable, Sendable {
    case turfWar
    case area
    case tower
    case rainmaker
    case clam
    case salmonRun

    /// splatoon3.ink APIの `vsRule.rule` 文字列から変換する。
    public init?(inkRule: String) {
        switch inkRule {
        case "TURF_WAR": self = .turfWar
        case "AREA": self = .area
        case "LOFT": self = .tower
        case "GOAL": self = .rainmaker
        case "CLAM": self = .clam
        default: return nil
        }
    }

    public var displayName: String {
        switch self {
        case .turfWar: "ナワバリバトル"
        case .area: "ガチエリア"
        case .tower: "ガチヤグラ"
        case .rainmaker: "ガチホコバトル"
        case .clam: "ガチアサリ"
        case .salmonRun: "サーモンラン"
        }
    }
}
