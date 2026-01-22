import SwiftUI
import DeviceActivity

/// DeviceActivityCenterUtil Demo - 展示设备活动监控调度
struct DeviceActivityCenterUtilDemoView: View {
    @State private var logMessages: [LogMessage] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DeviceActivityCenterUtil 封装了 DeviceActivityCenter，管理所有定时监控任务。")
                        
                        Text("**三种定时器：**")
                        BulletPointView(text: "Schedule Timer - 每日重复的日程屏蔽")
                        BulletPointView(text: "Break Timer - 一次性休息定时器")
                        BulletPointView(text: "Strategy Timer - 策略持续时间定时器")
                        
                        Text("**核心方法：**")
                        BulletPointView(text: "scheduleTimerActivity() - 注册日程定时器")
                        BulletPointView(text: "startBreakTimerActivity() - 启动休息定时器")
                        BulletPointView(text: "startStrategyTimerActivity() - 启动策略定时器")
                        BulletPointView(text: "removeXxxTimerActivities() - 移除定时器")
                        BulletPointView(text: "getDeviceActivities() - 获取所有活动")
                    }
                }
                
                // MARK: - 当前活动
                DemoSectionView(title: "📊 当前 DeviceActivities", icon: "list.bullet.rectangle") {
                    let activities = DeviceActivityCenterUtil.getDeviceActivities()
                    if activities.isEmpty {
                        Text("当前无活动的监控任务")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(activities, id: \.rawValue) { activity in
                            ActivityRowView(activity: activity)
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            refreshActivities()
                        } label: {
                            Label("刷新活动列表", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            explainScheduleFlow()
                        } label: {
                            Label("解释 Schedule 流程", systemImage: "calendar.badge.clock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            explainBreakFlow()
                        } label: {
                            Label("解释 Break 流程", systemImage: "cup.and.saucer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            explainStrategyFlow()
                        } label: {
                            Label("解释 Strategy 流程", systemImage: "hourglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 注册日程监控",
                            description: "用户保存 9:00-18:00 的日程设置",
                            code: """
// 在 ProfileEditView 保存时调用
if let schedule = profile.schedule, schedule.isActive {
    DeviceActivityCenterUtil.scheduleTimerActivity(for: profile)
}

// 内部实现:
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 9, minute: 0),
    intervalEnd: DateComponents(hour: 18, minute: 0),
    repeats: true  // 每日重复
)
center.startMonitoring(activityName, during: schedule)
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 启动休息定时器",
                            description: "用户点击休息 15 分钟",
                            code: """
// 用户点击休息按钮
DeviceActivityCenterUtil.startBreakTimerActivity(for: profile)

// 内部计算:
// intervalStart = 00:00 (今天开始)
// intervalEnd = 当前时间 + 15分钟

// 15分钟后系统触发 intervalDidEnd
// → BreakTimerActivity.stop()
// → 恢复屏蔽
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 策略定时器",
                            description: "从 Shortcuts 启动 25 分钟专注",
                            code: """
// Shortcuts App Intent
profile.strategyData = StrategyTimerData
    .toData(from: StrategyTimerData(durationInMinutes: 25))

DeviceActivityCenterUtil.startStrategyTimerActivity(for: profile)

// 25分钟后系统触发 intervalDidEnd
// → StrategyTimerActivity.stop()
// → 结束会话
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景4: 取消监控",
                            description: "用户删除配置或关闭日程",
                            code: """
// 删除配置时
DeviceActivityCenterUtil.removeScheduleTimerActivities(for: profile)

// 结束休息时
DeviceActivityCenterUtil.removeBreakTimerActivity(for: profile)

// 清理所有策略定时器
DeviceActivityCenterUtil.removeAllStrategyTimerActivities()
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("DeviceActivityCenterUtil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
            refreshActivities()
        }
    }
    
    // MARK: - Actions
    private func refreshActivities() {
        let activities = DeviceActivityCenterUtil.getDeviceActivities()
        addLog("📊 刷新活动列表: \(activities.count) 个", type: .info)
        for activity in activities {
            addLog("   - \(activity.rawValue)", type: .info)
        }
    }
    
    private func explainScheduleFlow() {
        addLog("📅 Schedule Timer 流程:", type: .info)
        addLog("", type: .info)
        addLog("1️⃣ 用户设置日程 (9:00 - 18:00)", type: .info)
        addLog("2️⃣ 调用 scheduleTimerActivity()", type: .info)
        addLog("3️⃣ 创建 DeviceActivitySchedule (repeats: true)", type: .info)
        addLog("4️⃣ center.startMonitoring()", type: .info)
        addLog("5️⃣ 每天 9:00 系统触发 intervalDidStart", type: .success)
        addLog("   → Extension 收到回调", type: .info)
        addLog("   → activateRestrictions()", type: .info)
        addLog("6️⃣ 每天 18:00 系统触发 intervalDidEnd", type: .warning)
        addLog("   → Extension 收到回调", type: .info)
        addLog("   → deactivateRestrictions()", type: .info)
    }
    
    private func explainBreakFlow() {
        addLog("☕ Break Timer 流程:", type: .info)
        addLog("", type: .info)
        addLog("1️⃣ 用户点击休息按钮", type: .info)
        addLog("2️⃣ 调用 startBreakTimerActivity()", type: .info)
        addLog("3️⃣ 计算结束时间 = now + 15分钟", type: .info)
        addLog("4️⃣ 创建 DeviceActivitySchedule (repeats: false)", type: .info)
        addLog("5️⃣ 立即暂停屏蔽", type: .success)
        addLog("6️⃣ 15分钟后触发 intervalDidEnd", type: .warning)
        addLog("   → 恢复屏蔽", type: .info)
    }
    
    private func explainStrategyFlow() {
        addLog("⏱️ Strategy Timer 流程:", type: .info)
        addLog("", type: .info)
        addLog("1️⃣ Shortcuts 启动 25分钟专注", type: .info)
        addLog("2️⃣ 解析 profile.strategyData", type: .info)
        addLog("   → StrategyTimerData(durationInMinutes: 25)", type: .info)
        addLog("3️⃣ 调用 startStrategyTimerActivity()", type: .info)
        addLog("4️⃣ 立即开始屏蔽", type: .success)
        addLog("5️⃣ 25分钟后触发 intervalDidEnd", type: .warning)
        addLog("   → 结束屏蔽", type: .info)
        addLog("   → 结束会话", type: .info)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 25 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct ActivityRowView: View {
    let activity: DeviceActivityName
    
    var activityType: String {
        let raw = activity.rawValue
        if raw.starts(with: "BreakScheduleActivity:") {
            return "Break"
        } else if raw.starts(with: "StrategyTimerActivity:") {
            return "Strategy"
        } else if UUID(uuidString: raw) != nil {
            return "Schedule"
        }
        return "Unknown"
    }
    
    var typeColor: Color {
        switch activityType {
        case "Break": return .orange
        case "Strategy": return .purple
        case "Schedule": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Label(activityType, systemImage: iconForType)
                .font(.caption)
                .foregroundColor(typeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(typeColor.opacity(0.1))
                .cornerRadius(4)
            
            Text(activity.rawValue)
                .font(.caption2.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
    
    var iconForType: String {
        switch activityType {
        case "Break": return "cup.and.saucer"
        case "Strategy": return "hourglass"
        case "Schedule": return "calendar"
        default: return "questionmark"
        }
    }
}

#Preview {
    NavigationStack {
        DeviceActivityCenterUtilDemoView()
    }
}
