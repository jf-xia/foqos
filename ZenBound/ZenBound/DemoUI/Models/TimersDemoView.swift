import SwiftUI
import DeviceActivity

/// Timers Demo - 展示定时器活动
struct TimersDemoView: View {
    @State private var logMessages: [LogMessage] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timers 模块管理 DeviceActivity 定时器活动。")
                        
                        Text("**TimerActivity 协议：**")
                        BulletPointView(text: "getDeviceActivityName() - 获取活动名称")
                        BulletPointView(text: "start(for:) - 开始定时器")
                        BulletPointView(text: "stop(for:) - 停止定时器")
                        
                        Text("**三种定时器类型：**")
                        BulletPointView(text: "ScheduleTimerActivity - 每日重复的日程定时器")
                        BulletPointView(text: "BreakTimerActivity - 一次性休息定时器")
                        BulletPointView(text: "StrategyTimerActivity - 策略持续时间定时器")
                        
                        Text("**TimerActivityUtil：**")
                        BulletPointView(text: "统一的定时器启动/停止入口")
                        BulletPointView(text: "解析活动名称，路由到对应实现")
                    }
                }
                
                // MARK: - 定时器类型
                DemoSectionView(title: "⏱️ 定时器类型", icon: "timer") {
                    VStack(spacing: 12) {
                        TimerTypeCardView(
                            title: "ScheduleTimerActivity",
                            description: "每日重复的自动屏蔽日程",
                            icon: "calendar.badge.clock",
                            color: .blue,
                            example: "格式: {profileId}"
                        )
                        
                        TimerTypeCardView(
                            title: "BreakTimerActivity",
                            description: "专注期间的临时休息定时器",
                            icon: "cup.and.saucer",
                            color: .orange,
                            example: "格式: BreakScheduleActivity:{profileId}"
                        )
                        
                        TimerTypeCardView(
                            title: "StrategyTimerActivity",
                            description: "策略定义的专注持续时间",
                            icon: "hourglass",
                            color: .purple,
                            example: "格式: StrategyTimerActivity:{profileId}"
                        )
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            listDeviceActivities()
                        } label: {
                            Label("列出当前 DeviceActivities", systemImage: "list.bullet")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            simulateActivityParsing()
                        } label: {
                            Label("模拟活动名称解析", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            demonstrateTimerFlow()
                        } label: {
                            Label("演示定时器流程", systemImage: "arrow.triangle.2.circlepath")
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
                            title: "场景1: 日程定时器",
                            description: "用户设置每天 9:00-18:00 自动屏蔽",
                            code: """
// 保存配置时注册
DeviceActivityCenterUtil.scheduleTimerActivity(for: profile)

// 系统在 9:00 触发 intervalDidStart
// DeviceActivityMonitor Extension 收到回调
func intervalDidStart(for activity: DeviceActivityName) {
    TimerActivityUtil.startTimerActivity(for: activity)
    // → ScheduleTimerActivity.start()
    // → appBlocker.activateRestrictions()
}

// 系统在 18:00 触发 intervalDidEnd
func intervalDidEnd(for activity: DeviceActivityName) {
    TimerActivityUtil.stopTimerActivity(for: activity)
    // → ScheduleTimerActivity.stop()
    // → appBlocker.deactivateRestrictions()
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 休息定时器",
                            description: "用户在专注期间休息 15 分钟",
                            code: """
// 用户点击"开始休息"
DeviceActivityCenterUtil.startBreakTimerActivity(for: profile)
// → 注册 15 分钟后的 intervalDidEnd

// BreakTimerActivity.start()
// → appBlocker.deactivateRestrictions()  // 暂停屏蔽
// → SharedData.setBreakStartTime()

// 15 分钟后系统触发 intervalDidEnd
// BreakTimerActivity.stop()
// → appBlocker.activateRestrictions()  // 恢复屏蔽
// → SharedData.setBreakEndTime()
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 策略定时器",
                            description: "用 Shortcuts 启动 25 分钟专注",
                            code: """
// App Intent 设置持续时间
profile.strategyData = StrategyTimerData
    .toData(from: StrategyTimerData(durationInMinutes: 25))

// 启动策略定时器
DeviceActivityCenterUtil.startStrategyTimerActivity(for: profile)

// StrategyTimerActivity.start()
// → appBlocker.activateRestrictions()

// 25 分钟后自动触发 stop
// → appBlocker.deactivateRestrictions()
// → SharedData.endActiveSharedSession()
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Timers")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
        }
    }
    
    // MARK: - Actions
    private func listDeviceActivities() {
        let activities = DeviceActivityCenterUtil.getDeviceActivities()
        
        if activities.isEmpty {
            addLog("📋 当前无活动的 DeviceActivity", type: .info)
        } else {
            addLog("📋 当前 DeviceActivities (\(activities.count)):", type: .info)
            for activity in activities {
                addLog("   - \(activity.rawValue)", type: .info)
            }
        }
    }
    
    private func simulateActivityParsing() {
        let testCases = [
            "12345678-1234-1234-1234-123456789012",  // Schedule (legacy)
            "BreakScheduleActivity:12345678-1234-1234-1234-123456789012",
            "StrategyTimerActivity:12345678-1234-1234-1234-123456789012"
        ]
        
        addLog("🔍 活动名称解析测试:", type: .info)
        
        for rawValue in testCases {
            let parts = rawValue.split(separator: ":")
            if parts.count == 2 {
                addLog("   \(rawValue)", type: .info)
                addLog("      类型: \(parts[0])", type: .success)
                addLog("      ProfileID: \(parts[1].prefix(8))...", type: .success)
            } else {
                addLog("   \(rawValue)", type: .info)
                addLog("      类型: ScheduleTimerActivity (legacy)", type: .success)
                addLog("      ProfileID: \(rawValue.prefix(8))...", type: .success)
            }
        }
    }
    
    private func demonstrateTimerFlow() {
        addLog("🔄 定时器生命周期流程:", type: .info)
        addLog("", type: .info)
        addLog("1️⃣ 用户操作 → 调用 DeviceActivityCenterUtil", type: .info)
        addLog("   例: scheduleTimerActivity(for: profile)", type: .info)
        addLog("", type: .info)
        addLog("2️⃣ 创建 DeviceActivitySchedule", type: .info)
        addLog("   设置 intervalStart / intervalEnd / repeats", type: .info)
        addLog("", type: .info)
        addLog("3️⃣ DeviceActivityCenter.startMonitoring()", type: .info)
        addLog("   注册到系统调度器", type: .info)
        addLog("", type: .info)
        addLog("4️⃣ 系统在指定时间唤醒 Extension", type: .info)
        addLog("   调用 intervalDidStart / intervalDidEnd", type: .info)
        addLog("", type: .info)
        addLog("5️⃣ TimerActivityUtil 路由到具体实现", type: .success)
        addLog("   执行 start() / stop() 方法", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 30 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct TimerTypeCardView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let example: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(example)
                .font(.caption.monospaced())
                .padding(6)
                .background(Color(.systemGray6))
                .cornerRadius(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        TimersDemoView()
    }
}
