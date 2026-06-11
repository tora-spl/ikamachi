import SwiftUI
import IkaMachiKit

/// 条件セットの編集フォーム。保存時の状態は親バインディングへ即時反映される。
struct ConditionEditView: View {
    @Environment(AppState.self) private var appState
    @Binding var condition: ConditionSet

    var body: some View {
        Form {
            Section("名前") {
                TextField(ConditionSummary.autoName(condition), text: $condition.name)
            }

            Section("モード（未選択 = すべて）") {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    toggleRow(mode.displayName,
                              isOn: binding(for: mode, in: $condition.modes))
                }
            }

            Section("ルール（未選択 = すべて）") {
                ForEach(GameRule.allCases.filter { $0 != .salmonRun }, id: \.self) { rule in
                    toggleRow(rule.displayName,
                              isOn: binding(for: rule, in: $condition.rules))
                }
            }

            Section("ステージ（未選択 = すべて）") {
                StageGridPicker(selection: $condition.stageIDs)
            }

            Section("時間帯（未設定 = 終日）") {
                ForEach(condition.timeWindows.indices, id: \.self) { i in
                    TimeWindowEditor(window: $condition.timeWindows[i])
                }
                .onDelete { condition.timeWindows.remove(atOffsets: $0) }
                Button("時間帯を追加") {
                    condition.timeWindows.append(
                        TimeWindow(start: HourMinute(hour: 20, minute: 0),
                                   end: HourMinute(hour: 24, minute: 0)))
                }
            }

            Section("通知タイミング") {
                Stepper("\(condition.leadTimeMinutes)分前に通知",
                        value: $condition.leadTimeMinutes, in: 0...60, step: 5)
            }

            Section("プレビュー") {
                if let next = nextMatch {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("次のマッチ").font(.caption).foregroundStyle(.secondary)
                        Text("\(Self.formatter.string(from: next.startTime)) \(next.eventName ?? next.rule.displayName)")
                            .font(.subheadline.bold())
                        Text(next.stages.map(\.name).joined(separator: " / "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("取得済みスケジュール内にマッチはありません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("条件を編集")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nextMatch: ScheduleSlot? {
        var enabled = condition
        enabled.isEnabled = true
        return ConditionEngine.match(slots: appState.futureSlots,
                                     conditions: [enabled], calendar: .current)
            .map(\.slot)
            .min { $0.startTime < $1.startTime }
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d(E) H:mm"
        return f
    }()

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
    }

    private func binding<T: Hashable>(for value: T, in set: Binding<Set<T>>) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(value) },
            set: { included in
                if included { set.wrappedValue.insert(value) }
                else { set.wrappedValue.remove(value) }
            })
    }
}

/// commons画像を使ったステージ複数選択グリッド。
struct StageGridPicker: View {
    @Binding var selection: Set<Int>

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(StageCatalog.shared.all, id: \.vsStageId) { entry in
                let isSelected = selection.contains(entry.vsStageId)
                Button {
                    if isSelected { selection.remove(entry.vsStageId) }
                    else { selection.insert(entry.vsStageId) }
                } label: {
                    VStack(spacing: 2) {
                        StageImage(stageID: entry.vsStageId)
                            .frame(height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.orange, lineWidth: 3)
                                }
                            }
                        Text(entry.name)
                            .font(.system(size: 9))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .opacity(isSelected || selection.isEmpty ? 1 : 0.5)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 1つの時間帯（開始・終了・曜日）のエディタ。
struct TimeWindowEditor: View {
    @Binding var window: TimeWindow

    private static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                hourMinutePicker("開始", $window.start)
                Text("〜")
                hourMinutePicker("終了", $window.end)
                if window.crossesMidnight {
                    Text("翌日").font(.caption2).foregroundStyle(.orange)
                }
            }
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { weekday in
                    let isOn = window.weekdays.contains(weekday)
                    Button(Self.weekdaySymbols[weekday - 1]) {
                        if isOn { window.weekdays.remove(weekday) }
                        else { window.weekdays.insert(weekday) }
                    }
                    .font(.caption)
                    .frame(width: 28, height: 28)
                    .background(isOn ? Color.orange : Color(.systemGray5), in: Circle())
                    .foregroundStyle(isOn ? .white : .primary)
                    .buttonStyle(.plain)
                }
                if window.weekdays.isEmpty {
                    Text("毎日").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func hourMinutePicker(_ label: String, _ value: Binding<HourMinute>) -> some View {
        Picker(label, selection: Binding(
            get: { value.wrappedValue.hour * 60 + value.wrappedValue.minute },
            set: { value.wrappedValue = HourMinute(hour: $0 / 60, minute: $0 % 60) })) {
            ForEach(Array(stride(from: 0, through: 24 * 60, by: 30)), id: \.self) { minutes in
                Text(String(format: "%d:%02d", minutes / 60, minutes % 60)).tag(minutes)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }
}
