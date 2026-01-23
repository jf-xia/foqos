import SwiftUI
import SwiftData

/// 场景4: 睡前数字戒断
/// 睡前自动屏蔽手机，帮助改善睡眠质量
struct BedtimeDigitalDetoxScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logMessages: [LogMessage] = []
    
    @State private var bedtimeHour = 22
    @State private var bedtimeMinute = 0
    @State private var wakeHour = 7
    @State private var wakeMinute = 0
    @State private var isScheduleActive = false
    @State private var enableReminder = true
    @State private var reminderMinutesBefore = 15
    @State private var allowBreak = true
    @State private var breakDuration = 5
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**睡前数字戒断**帮助你在睡前远离屏幕，改善睡眠质量。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "睡前减少蓝光暴露")
                        BulletPointView(text: "培养健康的就寝习惯")
                        BulletPointView(text: "避免睡前刷手机影响入睡")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "自定义就寝/起床时间")
                        BulletPointView(text: "就寝前提醒通知")
                        BulletPointView(text: "紧急情况短暂休息")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "BlockedProfileSchedule",
                            path: "ZenBound/Models/Schedule.swift",
                            description: "日程配置 - 每日睡眠时间段"
                        )
                        DependencyRowView(
                            name: "TimersUtil",
                            path: "ZenBound/Utils/TimersUtil.swift",
                            description: "通知调度 - 就寝提醒"
                        )
                        DependencyRowView(
                            name: "BreakTimerActivity",
                            path: "ZenBound/Models/Timers/BreakTimerActivity.swift",
                            description: "休息计时 - 紧急查看手机"
                        )
                        DependencyRowView(
                            name: "SharedData",
                            path: "ZenBound/Models/Shared.swift",
                            description: "数据同步 - 跨进程状态"
                        )
                        DependencyRowView(
                            name: "DeviceActivityMonitor",
                            path: "monitor/DeviceActivityMonitorExtension.swift",
                            description: "后台监控 - 自动触发屏蔽"
                        )
                    }
                }
                
                // MARK: - 时间配置
                DemoSectionView(title: "🌙 睡眠时间设置", icon: "moon.zzz") {
                    VStack(spacing: 20) {
                        // 就寝时间
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(.indigo)
                                    Text("就寝时间")
                                        .font(.subheadline.bold())
                                }
                                Text("开始屏蔽手机")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Picker("时", selection: $bedtimeHour) {
                                    ForEach(0..<24, id: \.self) { Text("\($0)时").tag($0) }
                                }
                                .pickerStyle(.menu)
                                
                                Picker("分", selection: $bedtimeMinute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { Text(String(format: "%02d分", $0)).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding()
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(12)
                        
                        // 起床时间
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.orange)
                                    Text("起床时间")
                                        .font(.subheadline.bold())
                                }
                                Text("解除屏蔽")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Picker("时", selection: $wakeHour) {
                                    ForEach(0..<24, id: \.self) { Text("\($0)时").tag($0) }
                                }
                                .pickerStyle(.menu)
                                
                                Picker("分", selection: $wakeMinute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { Text(String(format: "%02d分", $0)).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        
                        // 睡眠时长显示
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .foregroundColor(.purple)
                            Text("睡眠时长: \(sleepDuration)")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                // MARK: - 提醒设置
                DemoSectionView(title: "🔔 提醒设置", icon: "bell") {
                    VStack(spacing: 16) {
                        Toggle(isOn: $enableReminder) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("就寝提醒")
                                    .font(.subheadline.bold())
                                Text("在就寝前收到通知提醒")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if enableReminder {
                            HStack {
                                Text("提前提醒")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $reminderMinutesBefore) {
                                    Text("5分钟").tag(5)
                                    Text("10分钟").tag(10)
                                    Text("15分钟").tag(15)
                                    Text("30分钟").tag(30)
                                }
                                .pickerStyle(.menu)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        Divider()
                        
                        Toggle(isOn: $allowBreak) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("允许紧急休息")
                                    .font(.subheadline.bold())
                                Text("紧急情况可短暂使用手机")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if allowBreak {
                            HStack {
                                Text("休息时长")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $breakDuration) {
                                    Text("3分钟").tag(3)
                                    Text("5分钟").tag(5)
                                    Text("10分钟").tag(10)
                                }
                                .pickerStyle(.menu)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            toggleSchedule()
                        } label: {
                            Label(
                                isScheduleActive ? "停用睡眠日程" : "启用睡眠日程",
                                systemImage: isScheduleActive ? "moon.zzz.fill" : "moon.zzz"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isScheduleActive ? .red : .indigo)
                        
                        if isScheduleActive {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("睡眠日程已激活")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Button {
                            simulateBreak()
                        } label: {
                            Label("模拟紧急休息", systemImage: "cup.and.saucer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!isScheduleActive || !allowBreak)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 创建睡眠日程",
                            description: "每日重复的睡眠时间段",
                            code: """
// 创建睡眠日程 (每天 22:00 - 07:00)
let schedule = BlockedProfileSchedule(
    days: Weekday.allCases,  // 每天都启用
    startHour: 22, startMinute: 0,
    endHour: 7, endMinute: 0,
    updatedAt: Date()
)

// 注意：跨午夜日程系统会自动处理
// 22:00 触发 intervalDidStart
// 次日 07:00 触发 intervalDidEnd
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 设置就寝提醒",
                            description: "使用 TimersUtil 调度提醒通知",
                            code: """
let timersUtil = TimersUtil()

// 计算提醒时间 (就寝前15分钟)
let reminderSeconds = calculateSecondsUntilBedtime() - (15 * 60)

// 调度通知
let notificationId = timersUtil.scheduleNotification(
    title: "睡前准备",
    message: "15分钟后开始睡眠模式，请准备就寝",
    seconds: Double(reminderSeconds),
    identifier: "bedtime-reminder"
) { result in
    // 处理调度结果
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 紧急休息功能",
                            description: "使用 BreakTimerActivity 短暂暂停",
                            code: """
// 启动休息 (5分钟)
let breakTimer = BreakTimerActivity()

// 记录休息开始
SharedData.setBreakStartTime(date: Date())

// 临时解除屏蔽
appBlocker.deactivateRestrictions()

// 启动休息计时器
breakTimer.start(for: profile)

// 休息结束后自动恢复屏蔽
// (由 DeviceActivityMonitor 处理)
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 后台自动触发",
                            description: "DeviceActivityMonitor 处理日程事件",
                            code: """
// monitor/DeviceActivityMonitorExtension.swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        // 日程时间开始，激活屏蔽
        let store = ManagedSettingsStore()
        // 设置屏蔽...
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        // 日程时间结束，解除屏蔽
        let store = ManagedSettingsStore()
        store.shield.applications = nil
    }
}
"""
                        )
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 改进建议
                DemoSectionView(title: "💡 改进建议", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ImprovementCardView(
                            priority: .high,
                            title: "与系统睡眠模式集成",
                            description: "读取健康App的睡眠计划，自动同步时间",
                            relatedFiles: ["Schedule.swift", "HealthKit"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "添加渐进式屏蔽",
                            description: "就寝前30分钟逐步减少可用应用，而非一刀切",
                            relatedFiles: ["AppBlockerUtil.swift", "TimersUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "睡眠质量追踪",
                            description: "记录每晚就寝时间和手机使用情况，生成报告",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "放松内容白名单",
                            description: "允许冥想、白噪音等助眠应用",
                            relatedFiles: ["BlockedProfiles.swift", "enableAllowMode"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("睡前数字戒断")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Computed Properties
    
    private var sleepDuration: String {
        var hours = wakeHour - bedtimeHour
        var minutes = wakeMinute - bedtimeMinute
        
        if minutes < 0 {
            hours -= 1
            minutes += 60
        }
        if hours < 0 {
            hours += 24
        }
        
        return "\(hours)小时\(minutes > 0 ? "\(minutes)分钟" : "")"
    }
    
    // MARK: - Private Methods
    
    private func toggleSchedule() {
        isScheduleActive.toggle()
        
        if isScheduleActive {
            addLog("🌙 创建睡眠日程", type: .info)
            addLog("⏰ 就寝: \(bedtimeHour):\(String(format: "%02d", bedtimeMinute))", type: .info)
            addLog("☀️ 起床: \(wakeHour):\(String(format: "%02d", wakeMinute))", type: .info)
            
            if enableReminder {
                addLog("🔔 提前 \(reminderMinutesBefore) 分钟提醒", type: .info)
                addLog("📱 TimersUtil.scheduleNotification()", type: .success)
            }
            
            addLog("🔄 DeviceActivityCenterUtil.scheduleTimerActivity()", type: .success)
            addLog("✅ 睡眠日程已启用", type: .success)
        } else {
            addLog("🌙 停用睡眠日程", type: .info)
            addLog("🔔 TimersUtil.cancelNotification()", type: .success)
            addLog("🔄 DeviceActivityCenterUtil.removeScheduleTimerActivities()", type: .success)
            addLog("✅ 睡眠日程已停用", type: .warning)
        }
    }
    
    private func simulateBreak() {
        addLog("☕️ 启动紧急休息", type: .info)
        addLog("⏱️ 休息时长: \(breakDuration) 分钟", type: .info)
        addLog("📝 SharedData.setBreakStartTime()", type: .success)
        addLog("🔓 AppBlockerUtil.deactivateRestrictions()", type: .success)
        addLog("🔄 BreakTimerActivity.start()", type: .success)
        addLog("✅ 休息开始，\(breakDuration)分钟后自动恢复屏蔽", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

#Preview {
    NavigationStack {
        BedtimeDigitalDetoxScenarioView()
    }
}
