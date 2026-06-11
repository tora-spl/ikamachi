import SwiftUI
import IkaMachiKit

/// 条件セットの一覧。有効/無効トグルと編集・追加。
struct ConditionsTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            List {
                ForEach($appState.conditions) { $condition in
                    NavigationLink {
                        ConditionEditView(condition: $condition)
                    } label: {
                        ConditionRow(condition: $condition)
                    }
                }
                .onDelete { appState.conditions.remove(atOffsets: $0) }

                if appState.conditions.isEmpty {
                    ContentUnavailableView(
                        "条件がありません",
                        systemImage: "bell.slash",
                        description: Text("右上の＋から「ガチエリアのとき」「マサバで夜だけ」のような通知条件を作れます"))
                }
            }
            .navigationTitle("通知条件")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.conditions.append(ConditionSet())
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct ConditionRow: View {
    @Binding var condition: ConditionSet

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(condition.name.isEmpty ? ConditionSummary.autoName(condition) : condition.name)
                    .font(.body)
                Text(ConditionSummary.describe(condition))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Toggle("", isOn: $condition.isEnabled)
                .labelsHidden()
        }
    }
}

/// 条件セットの自動命名と説明文。
enum ConditionSummary {
    static func autoName(_ c: ConditionSet) -> String {
        var parts: [String] = []
        if !c.rules.isEmpty {
            parts.append(c.rules.map(\.displayName).sorted().joined(separator: "・"))
        }
        if !c.stageIDs.isEmpty {
            let names = c.stageIDs.compactMap { StageCatalog.shared.name(forVsStageId: $0) }.sorted()
            if names.count <= 2 { parts.append(names.joined(separator: "・")) }
            else { parts.append("\(names.first!)他\(names.count - 1)") }
        }
        if !c.timeWindows.isEmpty { parts.append("時間帯指定") }
        return parts.isEmpty ? "すべての試合" : parts.joined(separator: " × ")
    }

    static func describe(_ c: ConditionSet) -> String {
        var parts: [String] = []
        parts.append(c.modes.isEmpty ? "全モード" : c.modes.map(\.displayName).sorted().joined(separator: "・"))
        parts.append(c.rules.isEmpty ? "全ルール" : c.rules.map(\.displayName).sorted().joined(separator: "・"))
        parts.append(c.stageIDs.isEmpty ? "全ステージ" : "ステージ\(c.stageIDs.count)件")
        if let w = c.timeWindows.first {
            let head = String(format: "%d:%02d-%d:%02d", w.start.hour, w.start.minute, w.end.hour, w.end.minute)
            parts.append(c.timeWindows.count > 1 ? "\(head)他" : head)
        } else {
            parts.append("終日")
        }
        parts.append("\(c.leadTimeMinutes)分前通知")
        return parts.joined(separator: " / ")
    }
}
