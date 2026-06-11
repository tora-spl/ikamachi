import SwiftUI
import BackgroundTasks
import IkaMachiKit

@main
struct IkaMachiApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Self.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .task {
                    await appState.requestNotificationPermission()
                    await appState.refresh()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await appState.refresh() }
                    } else if phase == .background {
                        Self.scheduleBackgroundRefresh()
                    }
                }
        }
    }

    static let refreshTaskID = "com.tora.ikamachi.refresh"

    private static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            scheduleBackgroundRefresh()
            let work = Task {
                let state = await AppState()
                await state.refresh()
                refreshTask.setTaskCompleted(success: true)
            }
            refreshTask.expirationHandler = { work.cancel() }
        }
    }

    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ScheduleTabView()
                .tabItem { Label("スケジュール", systemImage: "calendar") }
            ConditionsTabView()
                .tabItem { Label("条件", systemImage: "bell.badge") }
            SettingsTabView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
    }
}
