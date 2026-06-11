import Foundation
import Observation
import UserNotifications
import WidgetKit
import IkaMachiKit

/// 取得→マッチ→通知sync→ウィジェット更新 のパイプラインを束ねるアプリ状態。
@Observable @MainActor
final class AppState {
    private(set) var slots: [ScheduleSlot] = []
    var conditions: [ConditionSet] = [] {
        didSet { persistConditions() }
    }
    private(set) var lastFetched: Date?
    private(set) var isRefreshing = false
    private(set) var lastError: String?
    private(set) var notificationsAuthorized = false

    private let store: SharedStore
    private let client = ScheduleClient()
    private let scheduler: any NotificationScheduler

    init(scheduler: any NotificationScheduler = LocalNotificationScheduler()) {
        self.store = SharedStore.appGroup()
            ?? SharedStore(directory: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0])
        self.scheduler = scheduler
        if let cached = store.loadSchedule() {
            slots = cached.slots
            lastFetched = cached.fetchedAt
        }
        conditions = store.loadConditions()
    }

    /// 現在の条件にマッチするスロット一覧。
    var matches: [Match] {
        ConditionEngine.match(slots: futureSlots, conditions: conditions, calendar: .current)
    }

    var futureSlots: [ScheduleSlot] {
        let now = Date()
        return slots.filter { $0.endTime > now }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let fetched = try await client.fetch().map { StageCatalog.shared.localize($0) }
            slots = fetched
            lastFetched = Date()
            lastError = nil
            try store.saveSchedule(fetched, fetchedAt: lastFetched!)
        } catch {
            lastError = "スケジュール取得に失敗しました"
        }
        await syncNotifications()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 条件変更時にも呼ばれ、通知予約を現在の状態に収束させる。
    func syncNotifications() async {
        let planned = NotificationPlanner.plan(matches: matches, now: Date())
        await scheduler.sync(planned)
    }

    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        notificationsAuthorized = granted
    }

    private func persistConditions() {
        try? store.saveConditions(conditions)
        Task {
            await syncNotifications()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
