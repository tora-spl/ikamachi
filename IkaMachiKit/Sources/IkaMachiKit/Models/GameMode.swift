import Foundation

/// 対象マッチの種類。
public enum GameMode: String, Codable, CaseIterable, Hashable, Sendable {
    case regular
    case bankaraChallenge
    case bankaraOpen
    case x
    case event
    case salmonRun

    public var displayName: String {
        switch self {
        case .regular: "レギュラーマッチ"
        case .bankaraChallenge: "バンカラ(チャレンジ)"
        case .bankaraOpen: "バンカラ(オープン)"
        case .x: "Xマッチ"
        case .event: "イベントマッチ"
        case .salmonRun: "サーモンラン"
        }
    }
}
