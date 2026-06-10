# イカマチ (IkaMachi) 設計ドキュメント

日付: 2026-06-11
ステータス: 承認済み

## 概要

スプラトゥーン3のスケジュールを監視し、ユーザーが設定した条件（モード×ルール×ステージ×時間帯）にマッチするスロットの開始前に通知するiOSアプリ。ホーム画面・ロック画面ウィジェット対応。

- ターゲット: iPhone (iOS 17+)
- 配布: App Store公開前提（まずローカル通知、将来APNs拡張可能な設計）
- データソース: splatoon3.ink API（約2日先までのスケジュール）
- 共有素材: `tora-spl/splatoon-commons` のステージマスタデータ・画像を活用
- リポジトリ: `tora-spl/ikamachi`（public、topic: `splatoon3`）

## 決定事項

| 論点 | 決定 |
|------|------|
| 出発点 | ゼロから新規設計（既存Splanotifyは参考のみ） |
| 対象マッチ | 全モード（レギュラー/バンカラ チャレンジ・オープン/X/イベント/サーモンラン） |
| 条件モデル | 条件セット複数（セット内AND、セット間OR） |
| 通知方式 | ローカル通知。Schedulerをプロトコル抽象化し将来APNs差し替え可能に |
| ウィジェット | 条件マッチ型＋スケジュール一覧型の2種類 |
| プロジェクト構成 | XcodeGen + ローカルSPMパッケージ(IkaMachiKit)にコアロジック分離 |
| アプリ名 | イカマチ (IkaMachi)。商標回避のため「Splatoon」を名前に含めない |

## アーキテクチャ

```
ikamachi/
├── project.yml                  # XcodeGen定義（.xcodeprojはコミットしない）
├── IkaMachiKit/                 # SPMパッケージ（コアロジック・テスト対象）
│   ├── Sources/IkaMachiKit/
│   │   ├── Models/              # GameMode, GameRule, Stage, ScheduleSlot, ConditionSet
│   │   ├── Engine/              # ConditionEngine, NotificationPlanner
│   │   └── Client/              # ScheduleClient(splatoon3.ink), キャッシュストア
│   └── Tests/IkaMachiKitTests/  # + APIレスポンスfixture JSON
├── App/                         # SwiftUIアプリ Target
├── Widget/                      # WidgetKit Extension Target
├── Resources/Commons/           # sync-commons.shが配置するステージ画像・データ
├── scripts/sync-commons.sh
└── docs/superpowers/specs/
```

App / Widget 間は App Groups (`group.com.tora.ikamachi`) で (1) スケジュールキャッシュ (2) 条件セット (3) 最終更新時刻 を共有する。

## データモデル

### 正規化スケジュール

splatoon3.inkのモードごとに異なるレスポンス形を、共通型に正規化する：

```swift
struct ScheduleSlot {
    let mode: GameMode        // regular / bankaraChallenge / bankaraOpen / x / event / salmonRun
    let rule: GameRule        // turfWar / area / tower / rainmaker / clam / salmonRun
    let stages: [Stage]       // 2ステージ（サーモンランは1）
    let startTime: Date
    let endTime: Date
}
```

サーモンランも同じ型に乗せ、条件エンジンが全モードを同一ロジックで扱う。

### 条件セット

```swift
struct ConditionSet: Identifiable, Codable {
    var id: UUID
    var name: String              // 省略時は自動生成
    var isEnabled: Bool
    var modes: Set<GameMode>      // 空 = すべて
    var rules: Set<GameRule>      // 空 = すべて
    var stages: Set<Stage.ID>     // 空 = すべて。2ステージのどちらかが含まれればマッチ
    var timeWindows: [TimeWindow] // 空 = 終日
    var leadTimeMinutes: Int      // 通知の先行時間 0〜60分
}

struct TimeWindow: Codable {
    var start: HourMinute         // 例 20:00
    var end: HourMinute           // 例 24:00。日跨ぎ(22:00-02:00)許容
    var weekdays: Set<Weekday>    // 空 = 毎日
}
```

- セット内はAND、セット間はOR
- 「空集合 = 制限なし」規約
- 時間帯判定は「スロット開催時間と窓が重なるか」（端末ローカルタイムゾーン基準）

### ConditionEngine

```swift
func match(slots: [ScheduleSlot], conditions: [ConditionSet]) -> [Match]
// Match = (slot, マッチした条件セット一覧)
```

状態を持たない純粋関数。同一スロットに複数セットがマッチしても通知は1本に統合。

## 通知計画

```swift
func plan(matches: [Match], now: Date) -> [PlannedNotification]

struct PlannedNotification {
    let id: String       // slot+条件から決定論的に生成（重複防止キー）
    let fireDate: Date   // slot開始 − leadTimeMinutes（複数セットマッチ時は最大lead）
    let title: String    // 例「まもなくガチエリア × マサバ海峡大橋」
    let body: String
}

protocol NotificationScheduler {
    func sync(_ planned: [PlannedNotification]) async
}
```

- v1実装は `LocalNotificationScheduler` (UNUserNotificationCenter)。将来APNs移行時は実装差し替えのみ
- `sync` は宣言的: 予約済みと突き合わせて追加・削除し、条件編集後に通知全体が正しい状態へ収束
- ローカル通知64件上限のため fireDate 近い順に最大50件予約。残りはバックグラウンド更新で補充

## 更新サイクル

1. アプリ起動/フォアグラウンド復帰時: 取得 → マッチ → 通知sync → WidgetCenter.reloadAllTimelines
2. BGAppRefreshTask（6時間間隔目安）: 同一パイプライン。2日分予約済みなので1日以上スキップされても通知は途切れない
3. キャッシュ: App Groups共有コンテナにJSON保存。ウィジェットはキャッシュのみ読む（ネットワーク不使用）

### エラー処理

- API失敗時はキャッシュで継続、UIに「最終更新: ◯時間前」表示
- キャッシュ切れ（2日以上更新なし）時のみウィジェットに「アプリを開いて更新」表示

## アプリUI（SwiftUI・3タブ）

- **スケジュール**: 現在〜2日先の一覧（モード切替セグメント）。条件マッチをハイライト＋バッジ。「自分の条件で絞る」トグル
- **条件**: 条件セット一覧（有効/無効トグル）＋編集フォーム（モード→ルール→ステージ→時間帯→通知タイミング）。ステージ選択はcommons画像のグリッド。保存時に「次にマッチするスロット」をプレビュー
- **設定**: 通知許可状態、最終更新時刻、データ出典（splatoon3.ink）、免責事項

## ウィジェット（2種類）

1. **条件マッチウィジェット**: Small/Medium（次のマッチを ルールアイコン×ステージ画像×残り時間 で表示、Mediumは2件）、ロック画面 accessoryRectangular/accessoryInline（テキスト主体）
2. **スケジュール一覧ウィジェット**: Medium/Large。AppIntentConfigurationで表示モード選択可能

タイムラインはキャッシュ＋保存済み条件から計算し、スロット境界ごとにエントリを刻む。

## commons連携

- 使用: `data/stages.json`（ID＋日本語名）、`assets/img/stages/*.png`
- 取り込み: `scripts/sync-commons.sh` が jsDelivr `@v1` から取得し `Resources/Commons/` にコピーしてコミット（ビルド時同梱）
- ID対応: splatoon3.ink の `vsStageId`（数値）と commons の内部コードネーム（`twist`等）の対応表が必要。commons の `stages.json` に `vsStageId` フィールドを追加するPRを実装フェーズで行う。未対応ステージ（新ステージ追加時）は英語名フォールバック表示

## テスト方針

- IkaMachiKit を `swift test` で検証（シミュレータ不要）:
  - ConditionEngine: 空集合規約、日跨ぎ時間帯、曜日、複数セット重複、タイムゾーン
  - NotificationPlanner: 決定論的ID、件数上限打ち切り、lead time計算
  - ScheduleClient: 全モードの実APIレスポンスfixtureデコード
- UI層は薄く保ちロジックはKitへ
- CI: GitHub Actions (macOS) で `swift test`

## 法務・表記

- splatoon3.ink クレジットをアプリ内・READMEに明記
- 任天堂非公式の免責を設定画面に表示（commonsのDISCLAIMER方針準拠）
- アプリ名・ストア掲載文に「Splatoon/スプラトゥーン」商標を使わない
