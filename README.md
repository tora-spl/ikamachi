# 🦑 イカマチ (IkaMachi)

スプラトゥーン3のスケジュールを「条件」で見張って、開始前に通知するiOSアプリ。

「ガチエリアのとき」「マサバ海峡大橋が来たら」「金曜の夜だけ」——モード・ルール・ステージ・時間帯を自由に組み合わせた条件セットを複数登録でき、どれかにマッチするスケジュールが始まる前にローカル通知が届きます。ホーム画面・ロック画面ウィジェット対応。

## 機能

- **条件セット**: モード × ルール × ステージ × 時間帯（曜日・日跨ぎ対応）のAND条件。セットは複数登録でき、セット間はOR
- **通知**: スロット開始の0〜60分前（セットごとに設定）。約2日先まで先読み予約するので、アプリを開いていなくても届く
- **ウィジェット**: 「次の条件マッチ」（Small/Medium/ロック画面）と「スケジュール一覧」（Medium/Large、モード選択可）
- **全モード対応**: レギュラー / バンカラ(チャレンジ・オープン) / Xマッチ / イベントマッチ / サーモンラン

## 構成

```
IkaMachiKit/   コアロジック（SPMパッケージ・swift testでテスト可能）
App/           SwiftUIアプリ
Widget/        WidgetKit拡張
Resources/     splatoon-commons由来のステージ画像・データ
```

- 条件マッチング・通知計画・API正規化はすべて `IkaMachiKit` に分離し、ユニットテストで検証
- 通知は `NotificationScheduler` プロトコルで抽象化（将来のAPNs移行に対応）
- App / Widget は App Groups (`group.com.tora.ikamachi`) でキャッシュ・条件を共有

## 開発

```bash
# コアロジックのテスト（Xcode不要）
swift test --package-path IkaMachiKit

# Xcodeプロジェクト生成
brew install xcodegen
xcodegen generate
open IkaMachi.xcodeproj

# commons素材の再同期
./scripts/sync-commons.sh
```

実機で動かすには Xcode で Signing Team を設定し、App Groups のIDを自分のものに変更してください。

## データ・クレジット

- スケジュールデータ: [splatoon3.ink](https://splatoon3.ink)
- ステージ画像・マスタデータ: [splatoon-commons](https://github.com/tora-spl/splatoon-commons)

## 免責

イカマチは非公式のファンアプリです。任天堂株式会社とは一切関係ありません。「スプラトゥーン」は任天堂株式会社の商標です。
