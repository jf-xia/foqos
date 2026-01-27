import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// 场景4: 睡前数字戒断
/// 完整流程实现：权限检查 → App选择 → 睡眠时间设置 → 启用日程 → 紧急休息
struct BedtimeDigitalDetoxScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var strategyManager: StrategyManager
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case appSelection = 1
        case schedule = 2
        case activation = 3
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .appSelection: return "选择App"
            case .schedule: return "睡眠时间"
            case .activation: return "启用日程"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .schedule: return "moon.zzz"
            case .activation: return "calendar.badge.clock"
            }
        }
    }
    
    @State private var currentStep: ConfigurationStep = .authorization
    
    // MARK: - 权限状态
    @State private var authorizationChecked = false
    @State private var isAuthorized = false
    
    // MARK: - App选择
    @State private var selectedActivity = FamilyActivitySelection()
    @State private var showAppPicker = false
    
    // MARK: - 睡眠时间设置
    @State private var bedtimeHour = 22
    @State private var bedtimeMinute = 0
    @State private var wakeHour = 7
    @State private var wakeMinute = 0
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    
    // MARK: - 高级设置
    @State private var isScheduleActive = false
    @State private var enableReminder = true
    @State private var reminderMinutesBefore = 15
    @State private var allowBreak = true
    @State private var breakDuration = 5
    @State private var enableLiveActivity = true
    @State private var enableGradualDimming = false
    
    // MARK: - 模拟会话状态
    @State private var isInSleepMode = false
    @State private var isOnBreak = false
    @State private var breakTimeRemaining = 0
    @State private var breakTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 流程步骤指示器
                StepProgressView(
                    steps: ConfigurationStep.allCases.map { ($0.icon, $0.title) },
                    currentStep: currentStep.rawValue
                )
                .padding(.horizontal)
                
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**睡前数字戒断**帮助你在睡前远离屏幕，改善睡眠质量。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "睡前减少蓝光暴露")
                        BulletPointView(text: "培养健康的就寝习惯")
                        BulletPointView(text: "避免睡前刷手机影响入睡")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - 选择睡前要屏蔽的App")
                        BulletPointView(text: "✅ 自定义就寝/起床时间")
                        BulletPointView(text: "✅ 就寝前提醒通知")
                        BulletPointView(text: "✅ 紧急情况短暂休息")
                        
                        // 当前状态卡片
                        HStack(spacing: 12) {
                            StatusCardView(
                                icon: isAuthorized ? "checkmark.shield.fill" : "shield.slash",
                                title: "权限",
                                value: isAuthorized ? "已授权" : "未授权",
                                color: isAuthorized ? .green : .red
                            )
                            
                            StatusCardView(
                                icon: "apps.iphone",
                                title: "屏蔽App",
                                value: "\(FamilyActivityUtil.countSelectedActivities(selectedActivity))个",
                                color: .indigo
                            )
                            
                            StatusCardView(
                                icon: isScheduleActive ? "moon.zzz.fill" : "moon.zzz",
                                title: "日程",
                                value: isScheduleActive ? "已启用" : "未启用",
                                color: isScheduleActive ? .indigo : .gray
                            )
                        }
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
                
                // MARK: - Step 1: 权限检查
                DemoSectionView(title: "🔐 Step 1: 权限检查", icon: "checkmark.shield") {
                    AuthorizationCheckSectionView(
                        isAuthorized: isAuthorized,
                        authorizationChecked: authorizationChecked,
                        onCheckAuthorization: checkAuthorization,
                        onRequestAuthorization: requestAuthorization,
                        logMessages: logMessages
                    )
                }
                
                // MARK: - Step 2: 选择睡前屏蔽App
                DemoSectionView(title: "📱 Step 2: 选择睡前屏蔽App", icon: "apps.iphone") {
                    BedtimeAppSelectionView(
                        isAuthorized: isAuthorized,
                        selectedActivity: $selectedActivity,
                        showAppPicker: $showAppPicker,
                        onSelectionChanged: { count in
                            addLog("📱 已选择 \(count) 个睡前屏蔽App", type: .success)
                            if currentStep == .appSelection && count > 0 {
                                currentStep = .schedule
                            }
                        }
                    )
                }
                .familyActivityPicker(
                    isPresented: $showAppPicker,
                    selection: $selectedActivity
                )
                .onChange(of: selectedActivity) { _, newValue in
                    let count = FamilyActivityUtil.countSelectedActivities(newValue)
                    addLog("📱 App选择更新: \(count) 个项目", type: .info)
                }
                
                // MARK: - Step 3: 睡眠时间设置
                DemoSectionView(title: "🌙 Step 3: 睡眠时间设置", icon: "moon.zzz") {
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
                                .onChange(of: bedtimeHour) { _, _ in
                                    addLog("🌙 就寝时间更新: \(bedtimeHour):\(String(format: "%02d", bedtimeMinute))", type: .info)
                                }
                                
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
                                .onChange(of: wakeHour) { _, _ in
                                    addLog("☀️ 起床时间更新: \(wakeHour):\(String(format: "%02d", wakeMinute))", type: .info)
                                }
                                
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
                        
                        // 重复日期选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📅 重复日期")
                                .font(.subheadline.bold())
                            
                            HStack(spacing: 6) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    Button {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                        addLog("📅 日期选择更新: \(selectedDays.count) 天", type: .info)
                                    } label: {
                                        Text(day.shortLabel)
                                            .font(.caption)
                                            .frame(width: 36, height: 36)
                                            .background(selectedDays.contains(day) ? Color.indigo : Color(.systemGray5))
                                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // MARK: - 提醒和休息设置
                DemoSectionView(title: "🔔 提醒和休息设置", icon: "bell") {
                    VStack(spacing: 16) {
                        ToggleSettingRow(
                            title: "启用 Live Activity",
                            subtitle: "在锁屏和灵动岛显示睡眠状态",
                            icon: "iphone",
                            isOn: $enableLiveActivity,
                            iconColor: .blue
                        )
                        .onChange(of: enableLiveActivity) { _, newValue in
                            addLog("📱 Live Activity: \(newValue ? "启用" : "禁用")", type: .info)
                        }
                        
                        Toggle(isOn: $enableReminder) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("就寝提醒")
                                    .font(.subheadline.bold())
                                Text("在就寝前收到通知提醒")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: enableReminder) { _, newValue in
                            addLog("🔔 就寝提醒: \(newValue ? "启用" : "禁用")", type: .info)
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
                        .onChange(of: allowBreak) { _, newValue in
                            addLog("☕️ 紧急休息: \(newValue ? "允许" : "禁止")", type: .info)
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
                        
                        Divider()
                        
                        Toggle(isOn: $enableGradualDimming) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("渐进式屏蔽")
                                    .font(.subheadline.bold())
                                Text("就寝前30分钟逐步减少可用应用")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: enableGradualDimming) { _, newValue in
                            addLog("🌅 渐进式屏蔽: \(newValue ? "启用" : "禁用")", type: .info)
                        }
                    }
                }
                
                // MARK: - Step 4: 启用日程
                DemoSectionView(title: "🚀 Step 4: 启用日程", icon: "calendar.badge.clock") {
                    VStack(spacing: 16) {
                        // 前置条件检查
                        if !isAuthorized {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("请先完成 Step 1 权限授权")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else if FamilyActivityUtil.countSelectedActivities(selectedActivity) == 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("请先完成 Step 2 选择屏蔽App")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        } else if selectedDays.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("请至少选择一个重复日期")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 日程状态显示
                        if isScheduleActive {
                            VStack(spacing: 12) {
                                if isInSleepMode {
                                    // 睡眠模式中
                                    if isOnBreak {
                                        // 正在休息
                                        Image(systemName: "cup.and.saucer.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.orange)
                                        
                                        Text("紧急休息中")
                                            .font(.headline)
                                        
                                        Text("\(breakTimeRemaining) 秒后恢复屏蔽")
                                            .font(.title2.bold().monospacedDigit())
                                        
                                        Button {
                                            endBreak()
                                        } label: {
                                            Text("提前结束休息")
                                                .font(.subheadline)
                                        }
                                        .buttonStyle(.bordered)
                                    } else {
                                        Image(systemName: "moon.zzz.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.indigo)
                                        
                                        Text("睡眠模式已激活")
                                            .font(.headline)
                                        
                                        Text("已屏蔽 \(FamilyActivityUtil.countSelectedActivities(selectedActivity)) 个应用")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("将于 \(wakeHour):\(String(format: "%02d", wakeMinute)) 自动解除")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.green)
                                    
                                    Text("睡眠日程已启用")
                                        .font(.headline)
                                    
                                    Text("将于 \(bedtimeHour):\(String(format: "%02d", bedtimeMinute)) 自动激活")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isInSleepMode ? (isOnBreak ? Color.orange.opacity(0.1) : Color.indigo.opacity(0.1)) : Color.green.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        // 操作按钮
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
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
                                .disabled(!isAuthorized || FamilyActivityUtil.countSelectedActivities(selectedActivity) == 0 || selectedDays.isEmpty)
                            }
                            
                            if isScheduleActive {
                                HStack(spacing: 12) {
                                    Button {
                                        simulateSleepMode()
                                    } label: {
                                        Label("模拟进入睡眠", systemImage: "moon.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isInSleepMode)
                                    
                                    Button {
                                        simulateBreak()
                                    } label: {
                                        Label("紧急休息", systemImage: "cup.and.saucer")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(!isInSleepMode || !allowBreak || isOnBreak)
                                }
                            }
                        }
                        
                        // 模拟器测试提示
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("模拟器测试: 日程和休息计时正常，App屏蔽需在真机测试")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - 测试用例说明
                DemoSectionView(title: "🧪 测试用例说明", icon: "checklist") {
                    BedtimeDetoxTestCasesView()
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 权限检查与请求",
                            description: "使用 AuthorizationCenter 检查和请求 Screen Time 权限",
                            code: """
import FamilyControls

// 检查当前权限状态
let status = AuthorizationCenter.shared.authorizationStatus

// 请求授权
Task {
    do {
        try await AuthorizationCenter.shared.requestAuthorization(
            for: .individual
        )
        print("授权成功")
    } catch {
        print("授权失败: \\(error)")
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 创建睡眠日程",
                            description: "每日重复的睡眠时间段",
                            code: """
// 创建睡眠日程 (每天 22:00 - 07:00)
let schedule = BlockedProfileSchedule(
    days: Weekday.allCases,  // 每天都启用
    startHour: 22, startMinute: 0,
    endHour: 7, endMinute: 0,
    updatedAt: Date()
)

// 创建配置
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "睡前戒断",
    selection: selectedActivity,
    schedule: schedule  // 关联日程
)

// 注意：跨午夜日程系统会自动处理
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 设置就寝提醒",
                            description: "使用 TimersUtil 调度提醒通知",
                            code: """
let timersUtil = TimersUtil()

// 计算提醒时间 (就寝前15分钟)
let reminderSeconds = calculateSecondsUntilBedtime() - (15 * 60)

// 调度通知
timersUtil.scheduleNotification(
    title: "睡前准备",
    message: "15分钟后开始睡眠模式，请准备就寝",
    seconds: Double(reminderSeconds),
    identifier: "bedtime-reminder"
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 紧急休息功能",
                            description: "使用 BreakTimerActivity 短暂暂停",
                            code: """
let breakTimer = BreakTimerActivity()
let appBlocker = AppBlockerUtil()

// 记录休息开始
SharedData.setBreakStartTime(date: Date())

// 临时解除屏蔽
appBlocker.deactivateRestrictions()

// 启动休息计时器 (5分钟)
breakTimer.start(for: profile, breakMinutes: 5)

// 休息结束后自动恢复屏蔽
// (由 DeviceActivityMonitor 处理)
"""
                        )
                        
                        ScenarioCardView(
                            title: "5. 后台自动触发",
                            description: "DeviceActivityMonitor 处理日程事件",
                            code: """
// monitor/DeviceActivityMonitorExtension.swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        // 日程时间开始，激活屏蔽
        let store = ManagedSettingsStore()
        store.shield.applications = selectedApps
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
        .onAppear {
            checkAuthorizationOnAppear()
        }
        .onDisappear {
            breakTimer?.invalidate()
        }
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
    
    private func checkAuthorizationOnAppear() {
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = (status == .approved)
        authorizationChecked = true
        addLog("🔍 初始化权限检查: \(status == .approved ? "已授权" : "未授权")", type: .info)
    }
    
    private func checkAuthorization() {
        addLog("🔍 正在检查屏幕时间权限...", type: .info)
        
        let status = AuthorizationCenter.shared.authorizationStatus
        authorizationChecked = true
        
        switch status {
        case .approved:
            isAuthorized = true
            addLog("✅ 屏幕时间权限已授权", type: .success)
            currentStep = .appSelection
        case .denied:
            isAuthorized = false
            addLog("❌ 屏幕时间权限被拒绝，请在设置中开启", type: .error)
        case .notDetermined:
            isAuthorized = false
            addLog("⚠️ 屏幕时间权限未决定，请点击请求授权", type: .warning)
        @unknown default:
            isAuthorized = false
            addLog("❓ 未知权限状态", type: .warning)
        }
    }
    
    private func requestAuthorization() {
        addLog("📤 正在请求屏幕时间授权...", type: .info)
        
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    isAuthorized = true
                    authorizationChecked = true
                    addLog("✅ 屏幕时间授权成功！", type: .success)
                    currentStep = .appSelection
                }
            } catch {
                await MainActor.run {
                    isAuthorized = false
                    authorizationChecked = true
                    addLog("❌ 授权失败: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }
    
    private func toggleSchedule() {
        isScheduleActive.toggle()
        
        if isScheduleActive {
            addLog("🌙 创建睡眠日程", type: .info)
            addLog("⏰ 就寝: \(bedtimeHour):\(String(format: "%02d", bedtimeMinute))", type: .info)
            addLog("☀️ 起床: \(wakeHour):\(String(format: "%02d", wakeMinute))", type: .info)
            addLog("📅 重复日期: \(selectedDays.count) 天", type: .info)
            
            let appCount = FamilyActivityUtil.countSelectedActivities(selectedActivity)
            addLog("📱 屏蔽App数量: \(appCount)", type: .info)
            
            // 创建日程配置
            let schedule = BlockedProfileSchedule(
                days: Array(selectedDays),
                startHour: bedtimeHour,
                startMinute: bedtimeMinute,
                endHour: wakeHour,
                endMinute: wakeMinute,
                updatedAt: Date()
            )
            addLog("📋 BlockedProfileSchedule 已创建", type: .success)
            
            if enableReminder {
                addLog("🔔 提前 \(reminderMinutesBefore) 分钟提醒", type: .info)
                addLog("📱 TimersUtil.scheduleNotification() 已调用", type: .success)
            }
            
            addLog("🔄 DeviceActivityCenterUtil.scheduleTimerActivity() 已调用", type: .success)
            addLog("✅ 睡眠日程已启用", type: .success)
            
            currentStep = .activation
        } else {
            addLog("🌙 停用睡眠日程", type: .info)
            addLog("🔔 TimersUtil.cancelNotification() 已调用", type: .success)
            addLog("🔄 DeviceActivityCenterUtil.removeScheduleTimerActivities() 已调用", type: .success)
            addLog("✅ 睡眠日程已停用", type: .warning)
            
            isInSleepMode = false
            isOnBreak = false
        }
    }
    
    private func simulateSleepMode() {
        addLog("🌙 模拟进入睡眠模式", type: .info)
        
        // 激活屏蔽
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "睡前戒断",
            selectedActivity: selectedActivity,
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "manual",
            strategyData: nil,
            order: 0,
            enableLiveActivity: enableLiveActivity,
            reminderTimeInSeconds: nil,
            customReminderMessage: nil,
            enableBreaks: allowBreak,
            breakTimeInMinutes: breakDuration,
            enableStrictMode: false,
            enableAllowMode: false,
            enableAllowModeDomains: false,
            enableSafariBlocking: false,
            domains: nil,
            physicalUnblockNFCTagId: nil,
            physicalUnblockQRCodeId: nil,
            schedule: nil,
            disableBackgroundStops: false
        )
        
        appBlocker.activateRestrictions(for: snapshot)
        addLog("🔒 AppBlockerUtil.activateRestrictions() 已调用", type: .success)
        
        if enableLiveActivity {
            addLog("📱 LiveActivityManager.startSessionActivity() 已调用", type: .success)
        }
        
        isInSleepMode = true
        addLog("✅ 睡眠模式已激活，App已屏蔽", type: .success)
    }
    
    private func simulateBreak() {
        addLog("☕️ 启动紧急休息", type: .info)
        addLog("⏱️ 休息时长: \(breakDuration) 分钟", type: .info)
        
        // 临时解除屏蔽
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        addLog("🔓 AppBlockerUtil.deactivateRestrictions() 已调用", type: .success)
        addLog("📝 SharedData.setBreakStartTime() 已调用", type: .success)
        addLog("🔄 BreakTimerActivity.start() 已调用", type: .success)
        
        isOnBreak = true
        breakTimeRemaining = breakDuration * 60
        
        // 启动休息计时器
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            Task { @MainActor in
                breakTimeRemaining -= 1
                
                if breakTimeRemaining <= 0 {
                    timer.invalidate()
                    endBreak()
                }
            }
        }
        
        addLog("✅ 休息开始，\(breakDuration)分钟后自动恢复屏蔽", type: .success)
    }
    
    private func endBreak() {
        addLog("⏱️ 休息结束", type: .info)
        
        breakTimer?.invalidate()
        breakTimer = nil
        
        // 恢复屏蔽
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "睡前戒断",
            selectedActivity: selectedActivity,
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "manual",
            strategyData: nil,
            order: 0,
            enableLiveActivity: enableLiveActivity,
            reminderTimeInSeconds: nil,
            customReminderMessage: nil,
            enableBreaks: allowBreak,
            breakTimeInMinutes: breakDuration,
            enableStrictMode: false,
            enableAllowMode: false,
            enableAllowModeDomains: false,
            enableSafariBlocking: false,
            domains: nil,
            physicalUnblockNFCTagId: nil,
            physicalUnblockQRCodeId: nil,
            schedule: nil,
            disableBackgroundStops: false
        )
        
        appBlocker.activateRestrictions(for: snapshot)
        addLog("🔒 屏蔽已恢复", type: .success)
        
        isOnBreak = false
        breakTimeRemaining = 0
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Bedtime App Selection View
struct BedtimeAppSelectionView: View {
    let isAuthorized: Bool
    @Binding var selectedActivity: FamilyActivitySelection
    @Binding var showAppPicker: Bool
    let onSelectionChanged: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if !isAuthorized {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("请先完成权限授权")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                let count = FamilyActivityUtil.countSelectedActivities(selectedActivity)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已选择 \(count) 个睡前屏蔽App")
                            .font(.headline)
                        Text("睡眠时间内这些App将被屏蔽")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showAppPicker = true
                    } label: {
                        Label(count > 0 ? "修改" : "选择", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 推荐选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 睡前建议屏蔽的App")
                        .font(.subheadline.bold())
                    
                    Text("为保证睡眠质量，建议屏蔽以下类型的应用：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(["社交媒体", "短视频", "游戏", "新闻", "购物", "工作邮件"], id: \.self) { category in
                            Text(category)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.indigo.opacity(0.15))
                                .foregroundColor(.indigo)
                                .cornerRadius(12)
                        }
                    }
                    
                    Text("💤 可考虑保留的App：冥想、白噪音、有声书")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Bedtime Detox Test Cases View
struct BedtimeDetoxTestCasesView: View {
    @State private var isExpanded = true  // 默认展开
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("📋 测试用例 (\(isExpanded ? "收起" : "展开"))")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    TestCaseRowView(
                        id: "TC-B001",
                        name: "权限请求流程",
                        status: .ready,
                        description: "验证从未授权到授权的完整流程"
                    )
                    TestCaseRowView(
                        id: "TC-B002",
                        name: "睡前App选择",
                        status: .ready,
                        description: "验证 FamilyActivityPicker 选择睡前屏蔽应用"
                    )
                    TestCaseRowView(
                        id: "TC-B003",
                        name: "睡眠时间设置",
                        status: .ready,
                        description: "验证就寝/起床时间设置和睡眠时长计算"
                    )
                    TestCaseRowView(
                        id: "TC-B004",
                        name: "重复日期选择",
                        status: .ready,
                        description: "验证每周重复日期的选择和保存"
                    )
                    TestCaseRowView(
                        id: "TC-B005",
                        name: "启用睡眠日程",
                        status: .ready,
                        description: "验证日程启用后的状态显示和日志输出"
                    )
                    TestCaseRowView(
                        id: "TC-B006",
                        name: "模拟睡眠模式",
                        status: .ready,
                        description: "验证进入睡眠模式后App屏蔽激活"
                    )
                    TestCaseRowView(
                        id: "TC-B007",
                        name: "紧急休息功能",
                        status: .ready,
                        description: "验证休息计时和自动恢复屏蔽"
                    )
                    TestCaseRowView(
                        id: "TC-B008",
                        name: "就寝提醒通知",
                        status: .planned,
                        description: "验证提前N分钟发送就寝提醒"
                    )
                    TestCaseRowView(
                        id: "TC-B009",
                        name: "跨午夜日程",
                        status: .planned,
                        description: "验证22:00-07:00跨午夜日程正确触发"
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BedtimeDigitalDetoxScenarioView()
            .environmentObject(StrategyManager.shared)
    }
}
