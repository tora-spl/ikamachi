import WidgetKit
import SwiftUI
import AppIntents
import IkaMachiKit

/// 表示モードを選べるスケジュール一覧ウィジェット。
struct ScheduleListWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ScheduleListWidget",
                               intent: ScheduleListConfigIntent.self,
                               provider: ScheduleListProvider()) { entry in
            ScheduleListView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("スケジュール一覧")
        .description("選んだモードのいま・次のスケジュールを表示します")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

enum WidgetGameMode: String, AppEnum {
    case regular, bankaraChallenge, bankaraOpen, x, event, salmonRun

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "モード")
    static let caseDisplayRepresentations: [WidgetGameMode: DisplayRepresentation] = [
        .regular: "レギュラーマッチ",
        .bankaraChallenge: "バンカラ(チャレンジ)",
        .bankaraOpen: "バンカラ(オープン)",
        .x: "Xマッチ",
        .event: "イベントマッチ",
        .salmonRun: "サーモンラン",
    ]

    var gameMode: GameMode { GameMode(rawValue: rawValue)! }
}

struct ScheduleListConfigIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "スケジュール一覧の設定"

    @Parameter(title: "モード", default: .bankaraChallenge)
    var mode: WidgetGameMode
}

struct ScheduleListEntry: TimelineEntry {
    let date: Date
    let mode: GameMode
    let slots: [ScheduleSlot]
    let isStale: Bool
}

struct ScheduleListProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ScheduleListEntry {
        ScheduleListEntry(date: Date(), mode: .bankaraChallenge, slots: [], isStale: false)
    }

    func snapshot(for configuration: ScheduleListConfigIntent,
                  in context: Context) async -> ScheduleListEntry {
        makeEntry(at: Date(), mode: configuration.mode.gameMode)
    }

    func timeline(for configuration: ScheduleListConfigIntent,
                  in context: Context) async -> Timeline<ScheduleListEntry> {
        let now = Date()
        let mode = configuration.mode.gameMode
        let data = WidgetData.load()
        let modeSlots = data.slots.filter { $0.mode == mode }
        let entries = WidgetData.timelineDates(slots: modeSlots, now: now)
            .map { makeEntry(at: $0, mode: mode) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func makeEntry(at date: Date, mode: GameMode) -> ScheduleListEntry {
        let data = WidgetData.load()
        let slots = data.slots
            .filter { $0.mode == mode && $0.endTime > date }
            .sorted { $0.startTime < $1.startTime }
        return ScheduleListEntry(date: date, mode: mode,
                                 slots: Array(slots.prefix(4)), isStale: data.isStale)
    }
}

struct ScheduleListView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ScheduleListEntry

    private var visibleSlots: [ScheduleSlot] {
        Array(entry.slots.prefix(family == .systemLarge ? 4 : 2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.mode.displayName)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if visibleSlots.isEmpty {
                Text(entry.isStale ? "アプリを開いて更新" : "スケジュールがありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(visibleSlots) { slot in
                    HStack(spacing: 8) {
                        if let stage = slot.stages.first,
                           let image = WidgetData.stageImage(forVsStageId: stage.id) {
                            image.resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 52, height: 30)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(slot.eventName ?? slot.rule.displayName)
                                .font(.caption.bold()).lineLimit(1)
                            Text(slot.stages.map(\.name).joined(separator: "/"))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Text(timeLabel(slot))
                            .font(.caption2)
                            .foregroundStyle(slot.startTime <= entry.date ? .orange : .secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func timeLabel(_ slot: ScheduleSlot) -> String {
        if slot.startTime <= entry.date { return "開催中" }
        return Self.time.string(from: slot.startTime)
    }

    private static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "H:mm"
        return f
    }()
}
