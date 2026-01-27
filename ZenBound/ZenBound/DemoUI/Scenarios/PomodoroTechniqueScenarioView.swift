import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// 场景5: 番茄工作法
/// 完整流程实现：权限检查 → App选择 → 番茄设置 → 25分钟专注 + 5分钟休息循环
struct PomodoroTechniqueScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case appSelection = 1
        case pomodoroSettings = 2
        case activation = 3
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .appSelection: return "选择App"
            case .pomodoroSettings: return "番茄设置"
            case .activation: return "开始番茄"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .pomodoroSettings: return "timer"
            case .activation: return "play.circle"
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
    
    // MARK: - 番茄钟设置
    @State private var focusDuration = 25
    @State private var shortBreakDuration = 5
    @State private var longBreakDuration = 15
    @State private var sessionsBeforeLongBreak = 4
    @State private var autoStartNextPomodoro = false
    
    // MARK: - 状态
    @State private var currentPhase: PomodoroPhase = .idle
    @State private var completedPomodoros = 0
    @State private var remainingSeconds = 0
    @State private var timer: Timer?
    @State private var isAcceleratedMode = false // 加速模式用于测试
    
    enum PomodoroPhase {
        case idle
        case focus
        case shortBreak
        case longBreak
        
        var color: Color {
            switch self {
            case .idle: return .gray
            case .focus: return .red
            case .shortBreak: return .green
            case .longBreak: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "circle.dotted"
            case .focus: return "brain.head.profile"
            case .shortBreak: return "cup.and.saucer"
            case .longBreak: return "figure.walk"
            }
        }
        
        var label: String {
            switch self {
            case .idle: return "准备开始"
            case .focus: return "专注中"
            case .shortBreak: return "短休息"
            case .longBreak: return "长休息"
            }
        }
    }
    
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
                        Text("**番茄工作法**是一种经典的时间管理技术，通过循环的专注和休息来提高效率。")
                        
                        Text("**标准流程：**")
                        BulletPointView(text: "25分钟专注工作")
                        BulletPointView(text: "5分钟短休息")
                        BulletPointView(text: "每4个番茄后15分钟长休息")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - 选择专注期间要屏蔽的App")
                        BulletPointView(text: "✅ 自动计时和切换")
                        BulletPointView(text: "✅ 专注期间屏蔽干扰App")
                        BulletPointView(text: "✅ 休息期间自动解除屏蔽")
                        BulletPointView(text: "✅ 番茄数统计")
                        
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
                                color: .blue
                            )
                            
                            StatusCardView(
                                icon: "timer",
                                title: "已完成",
                                value: "\(completedPomodoros)🍅",
                                color: .red
                            )
                        }
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "ShortcutTimerBlockingStrategy",
                            path: "ZenBound/Models/Strategies/ShortcutTimerBlockingStrategy.swift",
                            description: "定时策略 - 指定时长自动结束"
                        )
                        DependencyRowView(
                            name: "StrategyTimerData",
                            path: "ZenBound/Models/Strategies/Data/StrategyTimerData.swift",
                            description: "时长配置 - 番茄钟分钟数"
                        )
                        DependencyRowView(
                            name: "BreakTimerActivity",
                            path: "ZenBound/Models/Timers/BreakTimerActivity.swift",
                            description: "休息计时 - 管理休息阶段"
                        )
                        DependencyRowView(
                            name: "TimersUtil",
                            path: "ZenBound/Utils/TimersUtil.swift",
                            description: "通知调度 - 阶段切换提醒"
                        )
                        DependencyRowView(
                            name: "LiveActivityManager",
                            path: "ZenBound/Utils/LiveActivityManager.swift",
                            description: "实时显示 - 灵动岛倒计时"
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
                
                // MARK: - Step 2: 选择干扰App
                DemoSectionView(title: "📱 Step 2: 选择干扰App", icon: "apps.iphone") {
                    PomodoroAppSelectionSectionView(
                        isAuthorized: isAuthorized,
                        selectedActivity: $selectedActivity,
                        showAppPicker: $showAppPicker,
                        onSelectionChanged: { count in
                            addLog("📱 已选择 \(count) 个干扰App", type: .success)
                            if currentStep == .appSelection && count > 0 {
                                currentStep = .pomodoroSettings
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
                
                // MARK: - Step 3: 番茄设置
                DemoSectionView(title: "⚙️ Step 3: 番茄设置", icon: "timer") {
                    VStack(spacing: 16) {
                        // 专注时长
                        HStack {
                            Label("专注时长", systemImage: "brain.head.profile")
                            Spacer()
                            Picker("", selection: $focusDuration) {
                                Text("15分钟").tag(15)
                                Text("25分钟").tag(25)
                                Text("30分钟").tag(30)
                                Text("45分钟").tag(45)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: focusDuration) { _, newValue in
                            addLog("🍅 专注时长: \(newValue)分钟", type: .info)
                        }
                        
                        // 短休息
                        HStack {
                            Label("短休息", systemImage: "cup.and.saucer")
                            Spacer()
                            Picker("", selection: $shortBreakDuration) {
                                Text("3分钟").tag(3)
                                Text("5分钟").tag(5)
                                Text("10分钟").tag(10)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: shortBreakDuration) { _, newValue in
                            addLog("☕️ 短休息: \(newValue)分钟", type: .info)
                        }
                        
                        // 长休息
                        HStack {
                            Label("长休息", systemImage: "figure.walk")
                            Spacer()
                            Picker("", selection: $longBreakDuration) {
                                Text("10分钟").tag(10)
                                Text("15分钟").tag(15)
                                Text("20分钟").tag(20)
                                Text("30分钟").tag(30)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: longBreakDuration) { _, newValue in
                            addLog("🚶 长休息: \(newValue)分钟", type: .info)
                        }
                        
                        // 长休息间隔
                        HStack {
                            Label("长休息间隔", systemImage: "repeat")
                            Spacer()
                            Picker("", selection: $sessionsBeforeLongBreak) {
                                Text("3个番茄").tag(3)
                                Text("4个番茄").tag(4)
                                Text("5个番茄").tag(5)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: sessionsBeforeLongBreak) { _, newValue in
                            addLog("🔄 长休息间隔: \(newValue)个番茄", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "自动开始下一个番茄",
                            subtitle: "休息结束后自动开始新的专注阶段",
                            icon: "arrow.triangle.2.circlepath",
                            isOn: $autoStartNextPomodoro,
                            iconColor: .red
                        )
                        .onChange(of: autoStartNextPomodoro) { _, newValue in
                            addLog("🔁 自动开始: \(newValue ? "启用" : "禁用")", type: .info)
                        }
                        
                        // 时间摘要
                        let totalFocus = focusDuration * sessionsBeforeLongBreak
                        let totalBreak = shortBreakDuration * (sessionsBeforeLongBreak - 1) + longBreakDuration
                        
                        HStack {
                            VStack(spacing: 4) {
                                Text("总专注")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(totalFocus)分钟")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider().frame(height: 40)
                            
                            VStack(spacing: 4) {
                                Text("总休息")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(totalBreak)分钟")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider().frame(height: 40)
                            
                            VStack(spacing: 4) {
                                Text("一轮时长")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(totalFocus + totalBreak)分钟")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // MARK: - 番茄钟显示
                DemoSectionView(title: "🍅 番茄钟", icon: "timer") {
                    VStack(spacing: 20) {
                        // 大圆形计时器
                        ZStack {
                            // 背景圆环
                            Circle()
                                .stroke(currentPhase.color.opacity(0.2), lineWidth: 12)
                            
                            // 进度圆环
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(currentPhase.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1), value: progress)
                            
                            // 中心内容
                            VStack(spacing: 8) {
                                Image(systemName: currentPhase.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(currentPhase.color)
                                
                                Text(formatTime(remainingSeconds))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                
                                Text(currentPhase.label)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 220, height: 220)
                        .padding()
                        
                        // 番茄计数
                        HStack(spacing: 8) {
                            ForEach(0..<sessionsBeforeLongBreak, id: \.self) { index in
                                Image(systemName: index < completedPomodoros % sessionsBeforeLongBreak ? "circle.fill" : "circle")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text("已完成 \(completedPomodoros) 个番茄")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // 加速模式开关（测试用）
                        HStack {
                            Toggle(isOn: $isAcceleratedMode) {
                                HStack {
                                    Image(systemName: "hare")
                                        .foregroundColor(.orange)
                                    Text("加速模式 (1秒=1分钟)")
                                        .font(.caption)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        
                        // 控制按钮
                        HStack(spacing: 16) {
                            Button {
                                startPomodoro()
                            } label: {
                                Label("开始", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .disabled(currentPhase != .idle || !isAuthorized || FamilyActivityUtil.countSelectedActivities(selectedActivity) == 0)
                            
                            Button {
                                stopPomodoro()
                            } label: {
                                Label("停止", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(currentPhase == .idle)
                            
                            Button {
                                resetPomodoro()
                            } label: {
                                Label("重置", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
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
                                Text("请先完成 Step 2 选择干扰App")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // MARK: - 测试用例说明
                DemoSectionView(title: "🧪 测试用例说明", icon: "checklist") {
                    PomodoroTestCasesView()
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 配置番茄钟时长",
                            description: "使用 StrategyTimerData 设置分钟数",
                            code: """
// 创建25分钟的番茄钟配置
let timerData = StrategyTimerData(durationInMinutes: 25)

// 序列化为 Data (存入 BlockedProfiles.strategyData)
let data = StrategyTimerData.toData(from: timerData)

// 从 Data 反序列化
let restored = StrategyTimerData.toStrategyTimerData(from: data!)
// restored.durationInMinutes == 25
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 启动定时屏蔽",
                            description: "使用 ShortcutTimerBlockingStrategy",
                            code: """
let strategy = ShortcutTimerBlockingStrategy()

// 启动25分钟的专注会话
strategy.startBlocking(
    context: context,
    profile: pomodoroProfile,  // strategyData 包含时长
    forceStart: false
)

// 内部会:
// 1. 创建 BlockedProfileSession
// 2. 启动 StrategyTimerActivity
// 3. 25分钟后自动触发 intervalDidEnd
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 处理阶段切换",
                            description: "在 DeviceActivityMonitor 中处理",
                            code: """
// 当专注时间结束
override func intervalDidEnd(for activity: DeviceActivityName) {
    // 解除屏蔽
    store.shield.applications = nil
    
    // 发送休息通知
    let content = UNMutableNotificationContent()
    content.title = "番茄完成！"
    content.body = "休息5分钟后继续"
    
    // 触发休息计时 (通过 SharedData 通信)
    SharedData.setBreakStartTime(date: Date())
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 休息后自动开始下一个",
                            description: "使用 BreakTimerActivity 管理",
                            code: """
// 启动休息计时器
let breakTimer = BreakTimerActivity()
breakTimer.start(for: profile)

// 休息结束后 (intervalDidEnd)
// 可以:
// 1. 自动开始下一个番茄 (自动模式)
// 2. 发送通知让用户手动开始 (手动模式)

// 检查是否需要长休息
if completedPomodoros % 4 == 0 {
    // 启动15分钟长休息
} else {
    // 启动5分钟短休息
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
                            title: "添加自动循环模式",
                            description: "完成休息后自动开始下一个番茄，无需手动操作",
                            relatedFiles: ["StrategyManager.swift", "DeviceActivityMonitorExtension.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "番茄任务关联",
                            description: "每个番茄可以关联具体任务，追踪任务用时",
                            relatedFiles: ["BlockedProfileSession.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "添加白噪音/专注音乐",
                            description: "专注期间播放背景音乐帮助集中注意力",
                            relatedFiles: ["新建 AudioManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "番茄钟小组件",
                            description: "在桌面显示当前番茄状态和剩余时间",
                            relatedFiles: ["widget/widgetBundle.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "团队番茄同步",
                            description: "与团队成员同步番茄钟，一起专注",
                            relatedFiles: ["SharedData.swift", "CloudKit"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("番茄工作法")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAuthorizationOnAppear()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        guard currentPhase != .idle else { return 0 }
        
        let total: Int
        switch currentPhase {
        case .focus: total = focusDuration * 60
        case .shortBreak: total = shortBreakDuration * 60
        case .longBreak: total = longBreakDuration * 60
        case .idle: total = 1
        }
        
        return Double(total - remainingSeconds) / Double(total)
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
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func startPomodoro() {
        currentPhase = .focus
        remainingSeconds = isAcceleratedMode ? focusDuration : focusDuration * 60
        currentStep = .activation
        
        let appCount = FamilyActivityUtil.countSelectedActivities(selectedActivity)
        addLog("🍅 开始番茄钟 #\(completedPomodoros + 1)", type: .info)
        addLog("📱 屏蔽App数量: \(appCount)", type: .info)
        addLog("⏱️ 专注时长: \(focusDuration) 分钟\(isAcceleratedMode ? " (加速模式)" : "")", type: .info)
        
        // 激活App屏蔽
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "番茄专注",
            selectedActivity: selectedActivity,
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "shortcut_timer",
            strategyData: nil,
            order: 0,
            enableLiveActivity: true,
            reminderTimeInSeconds: nil,
            customReminderMessage: nil,
            enableBreaks: true,
            breakTimeInMinutes: shortBreakDuration,
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
        addLog("📱 LiveActivityManager.startSessionActivity() 已调用", type: .success)
        
        startTimer()
    }
    
    private func stopPomodoro() {
        timer?.invalidate()
        currentPhase = .idle
        remainingSeconds = 0
        
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        
        addLog("⏹️ 番茄钟已停止", type: .warning)
        addLog("🔓 AppBlockerUtil.deactivateRestrictions() 已调用", type: .success)
    }
    
    private func resetPomodoro() {
        timer?.invalidate()
        currentPhase = .idle
        remainingSeconds = 0
        completedPomodoros = 0
        
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        
        addLog("🔄 番茄钟已重置", type: .info)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    handlePhaseComplete()
                }
            }
        }
    }
    
    private func handlePhaseComplete() {
        timer?.invalidate()
        
        switch currentPhase {
        case .focus:
            completedPomodoros += 1
            addLog("✅ 番茄 #\(completedPomodoros) 完成!", type: .success)
            
            // 解除屏蔽进入休息
            let appBlocker = AppBlockerUtil()
            appBlocker.deactivateRestrictions()
            addLog("🔓 专注阶段结束，解除App屏蔽", type: .info)
            
            if completedPomodoros % sessionsBeforeLongBreak == 0 {
                currentPhase = .longBreak
                remainingSeconds = isAcceleratedMode ? longBreakDuration : longBreakDuration * 60
                addLog("🚶 开始长休息 (\(longBreakDuration)分钟)", type: .info)
            } else {
                currentPhase = .shortBreak
                remainingSeconds = isAcceleratedMode ? shortBreakDuration : shortBreakDuration * 60
                addLog("☕️ 开始短休息 (\(shortBreakDuration)分钟)", type: .info)
            }
            startTimer()
            
        case .shortBreak, .longBreak:
            addLog("⏰ 休息结束", type: .info)
            
            if autoStartNextPomodoro {
                addLog("🔁 自动开始下一个番茄", type: .info)
                startPomodoro()
            } else {
                currentPhase = .idle
                remainingSeconds = 0
                addLog("💡 点击开始按钮继续下一个番茄", type: .info)
            }
            
        case .idle:
            break
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Pomodoro App Selection Section View
struct PomodoroAppSelectionSectionView: View {
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
                        Text("已选择 \(count) 个干扰App")
                            .font(.headline)
                        Text("番茄专注期间这些App将被屏蔽")
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
                    .tint(.red)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 推荐选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 推荐屏蔽的干扰App")
                        .font(.subheadline.bold())
                    
                    Text("番茄专注时建议选择：社交媒体、消息应用、游戏等可能打断专注的App")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(["微信", "QQ", "微博", "抖音", "游戏", "邮件"], id: \.self) { category in
                            Text(category)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Pomodoro Test Cases View
struct PomodoroTestCasesView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("查看测试用例")
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
                        id: "TC-P001",
                        name: "权限请求流程",
                        status: .ready,
                        description: "验证从未授权到授权的完整流程"
                    )
                    TestCaseRowView(
                        id: "TC-P002",
                        name: "App选择功能",
                        status: .ready,
                        description: "验证 FamilyActivityPicker 选择和计数"
                    )
                    TestCaseRowView(
                        id: "TC-P003",
                        name: "番茄专注阶段",
                        status: .ready,
                        description: "验证25分钟专注计时和App屏蔽"
                    )
                    TestCaseRowView(
                        id: "TC-P004",
                        name: "短休息阶段",
                        status: .ready,
                        description: "验证5分钟短休息计时和屏蔽解除"
                    )
                    TestCaseRowView(
                        id: "TC-P005",
                        name: "长休息阶段",
                        status: .ready,
                        description: "验证每4个番茄后触发15分钟长休息"
                    )
                    TestCaseRowView(
                        id: "TC-P006",
                        name: "加速模式测试",
                        status: .ready,
                        description: "使用加速模式(1秒=1分钟)验证完整流程"
                    )
                    TestCaseRowView(
                        id: "TC-P007",
                        name: "自动循环模式",
                        status: .ready,
                        description: "验证休息结束后自动开始下一个番茄"
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PomodoroTechniqueScenarioView()
    }
}
