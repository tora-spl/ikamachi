import WidgetKit
import SwiftUI
import IkaMachiKit

/// 次に条件マッチするスロットを表示するウィジェット。
struct NextMatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextMatchWidget", provider: NextMatchProvider()) { entry in
            NextMatchView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("次の条件マッチ")
        .description("設定した条件に次にマッチするスケジュールを表示します")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryRectangular, .accessoryInline])
    }
}

struct NextMatchEntry: TimelineEntry {
    let date: Date
    let upcoming: [Match]   // 開始時刻順、先頭が次のマッチ
    let isStale: Bool
}

struct NextMatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextMatchEntry {
        NextMatchEntry(date: Date(), upcoming: [], isStale: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextMatchEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextMatchEntry>) -> Void) {
        let now = Date()
        let data = WidgetData.load()
        let matchSlots = data.matches.map(\.slot)
        let entries = WidgetData.timelineDates(slots: matchSlots, now: now)
            .map { makeEntry(at: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func makeEntry(at date: Date) -> NextMatchEntry {
        let data = WidgetData.load()
        let upcoming = data.matches
            .filter { $0.slot.endTime > date }
            .sorted { $0.slot.startTime < $1.slot.startTime }
        return NextMatchEntry(date: date, upcoming: Array(upcoming.prefix(3)),
                              isStale: data.isStale)
    }
}

struct NextMatchView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextMatchEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var next: Match? { entry.upcoming.first }

    @ViewBuilder private var inlineView: some View {
        if let match = next {
            Text("\(Self.time.string(from: match.slot.startTime)) \(label(match.slot))")
        } else {
            Text(entry.isStale ? "イカマチ: 要更新" : "マッチ予定なし")
        }
    }

    @ViewBuilder private var rectangularView: some View {
        if let match = next {
            VStack(alignment: .leading, spacing: 1) {
                Text(label(match.slot)).font(.headline)
                Text(match.slot.stages.map(\.name).joined(separator: "/"))
                    .font(.caption2).lineLimit(1)
                Text(timeline(match.slot)).font(.caption2)
            }
        } else {
            emptyText
        }
    }

    @ViewBuilder private var smallView: some View {
        if let match = next {
            VStack(alignment: .leading, spacing: 4) {
                header(match)
                Spacer()
                stageImages(match.slot, height: 30)
                Text(match.slot.stages.map(\.name).joined(separator: "/"))
                    .font(.system(size: 9)).lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        } else {
            emptyText
        }
    }

    @ViewBuilder private var mediumView: some View {
        if entry.upcoming.isEmpty {
            emptyText
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.upcoming.prefix(2), id: \.slot.id) { match in
                    HStack(spacing: 8) {
                        stageImages(match.slot, height: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            header(match)
                            Text(match.slot.stages.map(\.name).joined(separator: "/"))
                                .font(.caption2).lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func header(_ match: Match) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label(match.slot)).font(.subheadline.bold()).lineLimit(1)
            Text(timeline(match.slot)).font(.caption2).foregroundStyle(.orange)
        }
    }

    private func stageImages(_ slot: ScheduleSlot, height: CGFloat) -> some View {
        HStack(spacing: 3) {
            ForEach(slot.stages) { stage in
                if let image = WidgetData.stageImage(forVsStageId: stage.id) {
                    image.resizable().aspectRatio(contentMode: .fill)
                        .frame(width: height * 16 / 9, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    private var emptyText: some View {
        Text(entry.isStale ? "アプリを開いて更新" : "条件にマッチする\n予定はありません")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func label(_ slot: ScheduleSlot) -> String {
        slot.eventName ?? slot.rule.displayName
    }

    private func timeline(_ slot: ScheduleSlot) -> String {
        if slot.startTime <= entry.date {
            return "開催中 〜\(Self.time.string(from: slot.endTime))"
        }
        return "\(Self.time.string(from: slot.startTime))から"
    }

    private static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "H:mm"
        return f
    }()
}
