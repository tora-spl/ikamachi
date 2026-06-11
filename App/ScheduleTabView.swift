import SwiftUI
import IkaMachiKit

/// 現在〜2日先のスケジュール一覧。条件マッチはハイライト表示。
struct ScheduleTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedMode: GameMode = .bankaraChallenge
    @State private var matchesOnly = false

    private var matchedSlotIDs: Set<String> {
        Set(appState.matches.map(\.slot.id))
    }

    private var visibleSlots: [ScheduleSlot] {
        appState.futureSlots.filter { slot in
            if matchesOnly { return matchedSlotIDs.contains(slot.id) }
            return slot.mode == selectedMode
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let error = appState.lastError {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                }
                ForEach(visibleSlots) { slot in
                    SlotRow(slot: slot, isMatched: matchedSlotIDs.contains(slot.id))
                }
                if visibleSlots.isEmpty {
                    Text(matchesOnly ? "条件にマッチする予定はありません" : "スケジュールがありません。引っ張って更新してください")
                        .foregroundStyle(.secondary)
                }
            }
            .refreshable { await appState.refresh() }
            .navigationTitle("スケジュール")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $matchesOnly) {
                        Image(systemName: matchesOnly ? "bell.badge.fill" : "bell.badge")
                    }
                    .toggleStyle(.button)
                }
            }
            .safeAreaInset(edge: .top) {
                if !matchesOnly {
                    Picker("モード", selection: $selectedMode) {
                        ForEach(GameMode.allCases, id: \.self) { mode in
                            Text(shortName(mode)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .background(.bar)
                }
            }
        }
    }

    private func shortName(_ mode: GameMode) -> String {
        switch mode {
        case .regular: "レギュラー"
        case .bankaraChallenge: "チャレンジ"
        case .bankaraOpen: "オープン"
        case .x: "X"
        case .event: "イベント"
        case .salmonRun: "サーモン"
        }
    }
}

struct SlotRow: View {
    let slot: ScheduleSlot
    let isMatched: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M/d(E) H:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(slot.stages) { stage in
                    StageImage(stageID: stage.id)
                        .frame(width: 56, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(slot.eventName ?? slot.rule.displayName)
                        .font(.subheadline.bold())
                    if isMatched {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Text(slot.stages.map(\.name).joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(Self.timeFormatter.string(from: slot.startTime)) 〜")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .listRowBackground(isMatched ? Color.orange.opacity(0.12) : nil)
    }
}
