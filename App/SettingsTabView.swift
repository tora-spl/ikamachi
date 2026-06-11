import SwiftUI
import IkaMachiKit

struct SettingsTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Form {
                Section("通知") {
                    HStack {
                        Text("通知の許可")
                        Spacer()
                        if appState.notificationsAuthorized {
                            Label("許可済み", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("設定を開く") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }

                Section("データ") {
                    HStack {
                        Text("最終更新")
                        Spacer()
                        Text(lastFetchedText).foregroundStyle(.secondary)
                    }
                    Link("データ提供: splatoon3.ink",
                         destination: URL(string: "https://splatoon3.ink")!)
                    Link("ステージ画像: splatoon-commons",
                         destination: URL(string: "https://github.com/tora-spl/splatoon-commons")!)
                }

                Section("このアプリについて") {
                    Text("イカマチは非公式のファンアプリです。任天堂株式会社とは一切関係ありません。「スプラトゥーン」は任天堂株式会社の商標です。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("ソースコード (GitHub)",
                         destination: URL(string: "https://github.com/tora-spl/ikamachi")!)
                }
            }
            .navigationTitle("設定")
        }
    }

    private var lastFetchedText: String {
        guard let date = appState.lastFetched else { return "未取得" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
