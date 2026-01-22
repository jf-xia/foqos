import SwiftUI

/// TimersUtil Demo - 展示通知与后台任务管理
struct TimersUtilDemoView: View {
    @State private var logMessages: [LogMessage] = []
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TimersUtil 管理通知和后台任务调度。")
                        
                        Text("**通知功能：**")
                        BulletPointView(text: "requestNotificationPermission() - 请求权限")
                        BulletPointView(text: "scheduleNotification() - 安排本地通知")
                        BulletPointView(text: "cancelNotifications() - 取消通知")
                        
                        Text("**后台任务：**")
                        BulletPointView(text: "scheduleBackgroundRefresh() - 安排后台刷新")
                        BulletPointView(text: "使用 BGTaskScheduler")
                        
                        Text("**通知类型：**")
                        BulletPointView(text: "会话即将结束提醒")
                        BulletPointView(text: "休息结束提醒")
                        BulletPointView(text: "每日专注提醒")
                    }
                }
                
                // MARK: - 通知权限
                DemoSectionView(title: "🔔 通知权限", icon: "bell.badge") {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: permissionIcon)
                                .font(.title)
                                .foregroundColor(permissionColor)
                            VStack(alignment: .leading) {
                                Text(permissionText)
                                    .font(.headline)
                                Text(permissionDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(permissionColor.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack {
                            Button {
                                checkPermission()
                            } label: {
                                Label("检查权限", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                requestPermission()
                            } label: {
                                Label("请求权限", systemImage: "bell")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(notificationPermission == .authorized)
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            scheduleTestNotification()
                        } label: {
                            Label("安排测试通知 (5秒后)", systemImage: "bell.badge.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            scheduleSessionEndNotification()
                        } label: {
                            Label("模拟会话结束通知", systemImage: "timer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            scheduleBreakEndNotification()
                        } label: {
                            Label("模拟休息结束通知", systemImage: "cup.and.saucer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Divider()
                        
                        Button {
                            cancelAllNotifications()
                        } label: {
                            Label("取消所有通知", systemImage: "bell.slash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        
                        Button {
                            listPendingNotifications()
                        } label: {
                            Label("列出待发送通知", systemImage: "list.bullet")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 后台任务
                DemoSectionView(title: "⏰ 后台任务", icon: "clock.arrow.circlepath") {
                    VStack(spacing: 12) {
                        Text("后台任务用于在 App 不活跃时更新数据")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            simulateBackgroundRefresh()
                        } label: {
                            Label("模拟后台刷新", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Info.plist 配置要求:")
                                .font(.caption.bold())
                            Text("• BGTaskSchedulerPermittedIdentifiers")
                                .font(.caption2)
                            Text("• UIBackgroundModes: fetch, processing")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 会话结束提醒",
                            description: "专注会话即将结束时通知用户",
                            code: """
func scheduleSessionEndNotification(endsAt: Date, profileName: String) {
    let content = UNMutableNotificationContent()
    content.title = "专注即将结束"
    content.body = "\\(profileName) 还有5分钟结束"
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: endsAt.timeIntervalSinceNow - 300,
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: "session-ending-\\(profileName)",
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request)
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 休息结束提醒",
                            description: "休息时间结束时震动提醒",
                            code: """
func scheduleBreakEndNotification(duration: TimeInterval) {
    let content = UNMutableNotificationContent()
    content.title = "休息结束"
    content.body = "该继续专注了！" + FocusMessages.getRandomMessage()
    content.sound = .defaultCritical
    
    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: duration,
        repeats: false
    )
    
    let request = UNNotificationRequest(
        identifier: "break-end",
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request)
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 后台状态同步",
                            description: "后台定期同步 Widget 数据",
                            code: """
func scheduleBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(
        identifier: "com.zenbound.refresh"
    )
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("Failed to schedule: \\(error)")
    }
}

// AppDelegate 中处理
func handleAppRefresh(task: BGAppRefreshTask) {
    // 刷新 Widget 数据
    WidgetCenter.shared.reloadAllTimelines()
    task.setTaskCompleted(success: true)
    
    // 重新安排下次刷新
    scheduleBackgroundRefresh()
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("TimersUtil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
            checkPermission()
        }
    }
    
    // MARK: - Permission Properties
    private var permissionIcon: String {
        switch notificationPermission {
        case .authorized: return "bell.badge.fill"
        case .denied: return "bell.slash"
        case .notDetermined: return "bell.badge.circle"
        case .provisional: return "bell.badge"
        case .ephemeral: return "bell.badge"
        @unknown default: return "questionmark.circle"
        }
    }
    
    private var permissionColor: Color {
        switch notificationPermission {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .gray
        @unknown default: return .gray
        }
    }
    
    private var permissionText: String {
        switch notificationPermission {
        case .authorized: return "已授权"
        case .denied: return "已拒绝"
        case .notDetermined: return "未请求"
        case .provisional: return "临时授权"
        case .ephemeral: return "临时授权"
        @unknown default: return "未知"
        }
    }
    
    private var permissionDescription: String {
        switch notificationPermission {
        case .authorized: return "可以发送所有类型的通知"
        case .denied: return "请到设置中开启通知权限"
        case .notDetermined: return "点击下方按钮请求权限"
        case .provisional: return "静默通知已启用"
        case .ephemeral: return "临时通知权限"
        @unknown default: return ""
        }
    }
    
    // MARK: - Actions
    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermission = settings.authorizationStatus
                addLog("🔔 权限状态: \(permissionText)", type: .info)
            }
        }
    }
    
    private func requestPermission() {
        addLog("📤 请求通知权限...", type: .info)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    addLog("✅ 通知权限已授权", type: .success)
                } else if let error = error {
                    addLog("❌ 权限请求失败: \(error.localizedDescription)", type: .error)
                } else {
                    addLog("❌ 用户拒绝了通知权限", type: .error)
                }
                checkPermission()
            }
        }
    }
    
    private func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "测试通知"
        content.body = "这是一条来自 ZenBound Demo 的测试通知"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-\(Date())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    addLog("❌ 安排失败: \(error.localizedDescription)", type: .error)
                } else {
                    addLog("✅ 测试通知已安排 (5秒后)", type: .success)
                }
            }
        }
    }
    
    private func scheduleSessionEndNotification() {
        addLog("📋 模拟会话结束通知:", type: .info)
        addLog("   title: 专注即将结束", type: .info)
        addLog("   body: Work 还有5分钟结束", type: .info)
        addLog("   trigger: 5分钟前触发", type: .info)
    }
    
    private func scheduleBreakEndNotification() {
        addLog("📋 模拟休息结束通知:", type: .info)
        addLog("   title: 休息结束", type: .info)
        addLog("   body: 该继续专注了！", type: .info)
        addLog("   sound: defaultCritical", type: .info)
    }
    
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        addLog("🗑️ 已取消所有待发送通知", type: .warning)
    }
    
    private func listPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                addLog("📋 待发送通知 (\(requests.count)):", type: .info)
                if requests.isEmpty {
                    addLog("   (无)", type: .info)
                } else {
                    for request in requests.prefix(5) {
                        addLog("   • \(request.identifier)", type: .info)
                    }
                    if requests.count > 5 {
                        addLog("   ... 还有 \(requests.count - 5) 条", type: .info)
                    }
                }
            }
        }
    }
    
    private func simulateBackgroundRefresh() {
        addLog("⏰ 模拟后台刷新:", type: .info)
        addLog("   1. BGTaskScheduler.shared.submit(request)", type: .info)
        addLog("   2. earliestBeginDate: 15分钟后", type: .info)
        addLog("   3. 系统会在适当时机执行任务", type: .info)
        addLog("   4. 任务中刷新 Widget 数据", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }
}

#Preview {
    NavigationStack {
        TimersUtilDemoView()
    }
}
