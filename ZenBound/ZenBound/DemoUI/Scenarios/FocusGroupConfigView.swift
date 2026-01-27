import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// 场景: 专注组配置页面 (Focus Group)
/// 完整流程实现：权限检查 → App选择 → 番茄时钟设置 → 激活屏蔽 → 日志追踪
/// 使用番茄工作法，强制用户在使用一段时间后休息，促进健康使用习惯
struct FocusGroupConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case appSelection = 1
        case pomodoroSettings = 2
        case focusSettings = 3
        case activation = 4
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .appSelection: return "选择App"
            case .pomodoroSettings: return "番茄设置"
            case .focusSettings: return "专注限制"
            case .activation: return "激活测试"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .pomodoroSettings: return "timer"
            case .focusSettings: return "lock.shield"
            case .activation: return "play.circle"
            }
        }
    }
    
    @State private var currentStep: ConfigurationStep = .authorization
    @State private var isConfigurationActive = false
    
    // MARK: - 权限状态
    @State private var authorizationChecked = false
    @State private var isAuthorized = false
    
    // MARK: - App选择 (FamilyActivitySelection)
    @State private var selectedActivity = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var focusCategories: Set<String> = ["Work", "Productivity", "Reading"]
    
    // MARK: - 番茄时钟设置
    @State private var pomodoroDuration = 25
    @State private var breakDuration = 5
    @State private var pomodoroCycles = 3
    @State private var longBreakDuration = 15
    
    // MARK: - 专注限制设置
    @State private var disableNotifications = true
    @State private var blockAllApps = false
    @State private var preventAppSwitching = true
    @State private var photoCheckIn = false
    @State private var reminderBefore5Min = true
    @State private var breakEndReminder = true
    @State private var bonusEntertainmentTime = 5
    @State private var enableBonusTime = false
    
    // MARK: - Shield 设置
    @State private var shieldMessage = "Focus Time!"
    @State private var shieldColor: Color = .red
    
    private let shieldMessages = [
        "Focus Time!",
        "Take a deep breath",
        "You can do it!",
        "Stay focused, stay strong!"
    ]
    
    // MARK: - 测试与模拟
    @State private var isSimulatingSession = false
    @State private var simulatedMinutes = 0
    @State private var currentPhase: PomodoroPhase = .focus
    @State private var currentCycle = 1
    @State private var simulationTimer: Timer?
    
    enum PomodoroPhase: String {
        case focus = "专注中"
        case shortBreak = "短休息"
        case longBreak = "长休息"
        case completed = "已完成"
        
        var color: Color {
            switch self {
            case .focus: return .red
            case .shortBreak: return .green
            case .longBreak: return .blue
            case .completed: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .focus: return "brain.head.profile"
            case .shortBreak: return "cup.and.saucer"
            case .longBreak: return "figure.walk"
            case .completed: return "checkmark.seal.fill"
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
                        Text("**专注组配置**使用番茄工作法，帮助用户集中注意力完成任务：")
                        
                        Text("**核心功能：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - 选择专注期间要屏蔽的干扰App")
                        BulletPointView(text: "✅ 番茄时钟 - 25分钟专注 + 5分钟休息")
                        BulletPointView(text: "✅ 周期管理 - 多个番茄循环")
                        BulletPointView(text: "✅ 奖励机制 - 完成后获取娱乐时间")
                        BulletPointView(text: "✅ 完整测试 - 模拟器加速验证")
                        
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
                                title: "番茄时长",
                                value: "\(pomodoroDuration)分钟",
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
                            description: "定时屏蔽策略 - 番茄时钟核心"
                        )
                        DependencyRowView(
                            name: "StrategyTimerData",
                            path: "ZenBound/Models/Strategies/Data/StrategyTimerData.swift",
                            description: "存储番茄时长配置"
                        )
                        DependencyRowView(
                            name: "BreakTimerActivity",
                            path: "ZenBound/Models/Timers/BreakTimerActivity.swift",
                            description: "休息计时管理"
                        )
                        DependencyRowView(
                            name: "LiveActivityManager",
                            path: "ZenBound/Utils/LiveActivityManager.swift",
                            description: "实时活动 - 显示倒计时"
                        )
                        DependencyRowView(
                            name: "AppBlockerUtil",
                            path: "ZenBound/Utils/AppBlockerUtil.swift",
                            description: "应用屏蔽控制"
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
                    FocusAppSelectionSectionView(
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
                
                // MARK: - Step 3: 番茄时钟设置
                DemoSectionView(title: "🍅 Step 3: 番茄时钟设置", icon: "timer") {
                    PomodoroSettingsSectionView(
                        pomodoroDuration: $pomodoroDuration,
                        breakDuration: $breakDuration,
                        pomodoroCycles: $pomodoroCycles,
                        longBreakDuration: $longBreakDuration,
                        onSettingsChanged: { setting, value in
                            addLog("🍅 \(setting): \(value)", type: .info)
                        }
                    )
                }
                
                // MARK: - Step 4: 专注限制设置
                DemoSectionView(title: "🔒 Step 4: 专注限制设置", icon: "lock.shield") {
                    FocusRestrictionsSectionView(
                        disableNotifications: $disableNotifications,
                        blockAllApps: $blockAllApps,
                        reminderBefore5Min: $reminderBefore5Min,
                        breakEndReminder: $breakEndReminder,
                        enableBonusTime: $enableBonusTime,
                        bonusEntertainmentTime: $bonusEntertainmentTime,
                        onSettingsChanged: { setting, value in
                            addLog("🔒 \(setting): \(value)", type: .info)
                        }
                    )
                }
                
                // MARK: - Shield 设置
                DemoSectionView(title: "🛡️ Shield 设置", icon: "shield.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("**Shield 按钮**")
                            .font(.subheadline)
                        
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundColor(.accentColor)
                            Text("打开 ZenBound 番茄时钟")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        ShieldThemeSettingsView(
                            selectedMessage: $shieldMessage,
                            selectedColor: $shieldColor,
                            defaultMessages: shieldMessages
                        )
                    }
                }
                
                // MARK: - Step 5: 激活与测试
                DemoSectionView(title: "🚀 Step 5: 激活与测试", icon: "play.circle") {
                    PomodoroActivationTestSectionView(
                        isConfigurationActive: $isConfigurationActive,
                        isAuthorized: isAuthorized,
                        selectedActivityCount: FamilyActivityUtil.countSelectedActivities(selectedActivity),
                        pomodoroDuration: pomodoroDuration,
                        breakDuration: breakDuration,
                        pomodoroCycles: pomodoroCycles,
                        isSimulatingSession: $isSimulatingSession,
                        simulatedMinutes: $simulatedMinutes,
                        currentPhase: $currentPhase,
                        currentCycle: $currentCycle,
                        onActivate: activateConfiguration,
                        onDeactivate: deactivateConfiguration,
                        onStartSimulation: startPomodoroSimulation,
                        onStopSimulation: stopPomodoroSimulation,
                        addLog: addLog
                    )
                }
                
                // MARK: - 测试用例说明
                DemoSectionView(title: "🧪 测试用例说明", icon: "checklist") {
                    FocusTestCasesDocumentationView()
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 改进建议
                DemoSectionView(title: "💡 改进建议", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ImprovementCardView(
                            priority: .high,
                            title: "添加禁止切换App功能",
                            description: "当前iOS不支持直接禁止切换App，可考虑使用Guided Access API或在切换时立即显示Shield",
                            relatedFiles: ["ShieldConfigurationExtension.swift", "DeviceActivityMonitorExtension.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "番茄与娱乐组联动",
                            description: "完成番茄自动增加娱乐组可用时间，需要建立配置间的关联机制",
                            relatedFiles: ["BlockedProfiles.swift", "SharedData.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "番茄统计仪表盘",
                            description: "展示每日/每周完成的番茄数、专注时长趋势",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                    }
                }
                
                // MARK: - 操作按钮
                ActionButtonsView(
                    onSave: saveConfiguration,
                    onCancel: { dismiss() },
                    saveColor: .red
                )
            }
            .padding()
        }
        .navigationTitle("专注组配置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAuthorizationOnAppear()
        }
        .onDisappear {
            stopPomodoroSimulation()
        }
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
    
    private func activateConfiguration() {
        guard isAuthorized else {
            addLog("❌ 无法激活：未获得屏幕时间授权", type: .error)
            return
        }
        
        let appCount = FamilyActivityUtil.countSelectedActivities(selectedActivity)
        guard appCount > 0 else {
            addLog("❌ 无法激活：未选择任何干扰App", type: .error)
            return
        }
        
        addLog("🚀 正在激活专注组配置...", type: .info)
        addLog("📱 屏蔽App数量: \(appCount)", type: .info)
        addLog("🍅 番茄时长: \(pomodoroDuration)分钟", type: .info)
        addLog("☕️ 休息时长: \(breakDuration)分钟", type: .info)
        addLog("🔄 番茄周期: \(pomodoroCycles)个", type: .info)
        
        // 激活应用屏蔽
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "Focus Session",
            selectedActivity: selectedActivity,
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "shortcut_timer",
            strategyData: nil,
            order: 0,
            enableLiveActivity: true,
            reminderTimeInSeconds: reminderBefore5Min ? UInt32(5 * 60) : nil,
            customReminderMessage: nil,
            enableBreaks: true,
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
        addLog("🔒 干扰App已被屏蔽", type: .success)
        
        isConfigurationActive = true
        currentStep = .activation
        currentPhase = .focus
        currentCycle = 1
        addLog("✅ 专注组配置激活成功！", type: .success)
        addLog("💡 提示: 使用模拟器测试完整的番茄工作法流程", type: .info)
    }
    
    private func deactivateConfiguration() {
        addLog("🛑 正在停用专注组配置...", type: .info)
        
        stopPomodoroSimulation()
        
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        addLog("🔓 干扰App屏蔽已解除", type: .info)
        
        isConfigurationActive = false
        currentPhase = .focus
        currentCycle = 1
        simulatedMinutes = 0
        addLog("✅ 专注组配置已停用", type: .success)
    }
    
    private func startPomodoroSimulation() {
        guard isConfigurationActive else {
            addLog("❌ 请先激活配置", type: .error)
            return
        }
        
        isSimulatingSession = true
        simulatedMinutes = 0
        currentPhase = .focus
        currentCycle = 1
        addLog("▶️ 开始模拟番茄会话 (周期 1/\(pomodoroCycles))...", type: .info)
        addLog("🍅 进入专注阶段: \(pomodoroDuration) 分钟", type: .info)
        
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                simulatedMinutes += 1
                
                let currentPhaseDuration = getCurrentPhaseDuration()
                
                if simulatedMinutes >= currentPhaseDuration {
                    transitionToNextPhase()
                } else {
                    checkReminders()
                }
            }
        }
    }
    
    private func getCurrentPhaseDuration() -> Int {
        switch currentPhase {
        case .focus: return pomodoroDuration
        case .shortBreak: return breakDuration
        case .longBreak: return longBreakDuration
        case .completed: return 0
        }
    }
    
    private func checkReminders() {
        let remaining = getCurrentPhaseDuration() - simulatedMinutes
        
        switch currentPhase {
        case .focus:
            if remaining == 5 && reminderBefore5Min {
                addLog("⏰ 提醒: 番茄时钟还剩5分钟", type: .warning)
            } else if remaining == 1 {
                addLog("⏰ 提醒: 番茄时钟还剩1分钟!", type: .warning)
            }
        case .shortBreak, .longBreak:
            if remaining == 1 && breakEndReminder {
                addLog("⏰ 提醒: 休息即将结束，准备开始下一个番茄", type: .warning)
            }
        case .completed:
            break
        }
    }
    
    private func transitionToNextPhase() {
        simulatedMinutes = 0
        
        switch currentPhase {
        case .focus:
            addLog("✅ 番茄 \(currentCycle) 完成!", type: .success)
            
            if currentCycle >= pomodoroCycles {
                currentPhase = .longBreak
                addLog("🎉 所有番茄周期完成! 进入长休息: \(longBreakDuration) 分钟", type: .success)
                
                if enableBonusTime {
                    let totalBonus = bonusEntertainmentTime * pomodoroCycles
                    addLog("🎁 获得额外娱乐时间奖励: \(totalBonus) 分钟", type: .success)
                }
            } else {
                currentPhase = .shortBreak
                addLog("☕️ 进入短休息: \(breakDuration) 分钟", type: .info)
                
                let appBlocker = AppBlockerUtil()
                appBlocker.deactivateRestrictions()
                addLog("🔓 休息期间暂时解除屏蔽", type: .info)
            }
            
        case .shortBreak:
            currentCycle += 1
            currentPhase = .focus
            addLog("🍅 休息结束，开始番茄 \(currentCycle)/\(pomodoroCycles)", type: .info)
            
            activateRestrictions()
            addLog("🔒 专注期间恢复屏蔽", type: .info)
            
        case .longBreak:
            currentPhase = .completed
            addLog("🎊 恭喜! 整个番茄会话完成!", type: .success)
            stopPomodoroSimulation()
            
        case .completed:
            break
        }
    }
    
    private func activateRestrictions() {
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "Focus Session",
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
    }
    
    private func stopPomodoroSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isSimulatingSession = false
        if simulatedMinutes > 0 || currentCycle > 1 {
            addLog("⏹️ 模拟停止 (周期 \(currentCycle), 阶段: \(currentPhase.rawValue))", type: .info)
        }
    }
    
    private func saveConfiguration() {
        addLog("💾 正在保存专注组配置...", type: .info)
        addLog("🔐 权限状态: \(isAuthorized ? "已授权" : "未授权")", type: isAuthorized ? .success : .warning)
        addLog("📱 已选App: \(FamilyActivityUtil.countSelectedActivities(selectedActivity))个", type: .success)
        addLog("🍅 番茄时长: \(pomodoroDuration)分钟", type: .success)
        addLog("☕️ 休息时长: \(breakDuration)分钟", type: .success)
        addLog("🔄 番茄周期: \(pomodoroCycles)个", type: .success)
        addLog("🛡️ Shield消息: \(shieldMessage)", type: .success)
        addLog("✅ 配置保存成功!", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Focus App Selection Section
struct FocusAppSelectionSectionView: View {
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
                        Text("专注期间这些App将被屏蔽")
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 推荐选择干扰类App")
                        .font(.subheadline.bold())
                    
                    Text("建议选择：社交媒体、游戏、娱乐、视频等可能分散注意力的App")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(["社交媒体", "游戏", "视频", "新闻", "购物"], id: \.self) { category in
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

// MARK: - Pomodoro Settings Section
struct PomodoroSettingsSectionView: View {
    @Binding var pomodoroDuration: Int
    @Binding var breakDuration: Int
    @Binding var pomodoroCycles: Int
    @Binding var longBreakDuration: Int
    let onSettingsChanged: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            DurationPickerView(
                title: "番茄时长",
                icon: "brain.head.profile",
                selectedMinutes: $pomodoroDuration,
                options: [15, 25, 30, 45, 60]
            )
            .onChange(of: pomodoroDuration) { _, newValue in
                onSettingsChanged("番茄时长", "\(newValue)分钟")
            }
            
            DurationPickerView(
                title: "短休息时长",
                icon: "cup.and.saucer",
                selectedMinutes: $breakDuration,
                options: [5, 10, 15, 20]
            )
            .onChange(of: breakDuration) { _, newValue in
                onSettingsChanged("休息时长", "\(newValue)分钟")
            }
            
            CountPickerView(
                title: "番茄周期",
                icon: "repeat",
                selectedCount: $pomodoroCycles,
                options: [1, 2, 3, 4, 5, 6],
                suffix: "个"
            )
            .onChange(of: pomodoroCycles) { _, newValue in
                onSettingsChanged("番茄周期", "\(newValue)个")
            }
            
            DurationPickerView(
                title: "长休息时长",
                icon: "figure.walk",
                selectedMinutes: $longBreakDuration,
                options: [15, 20, 30]
            )
            .onChange(of: longBreakDuration) { _, newValue in
                onSettingsChanged("长休息时长", "\(newValue)分钟")
            }
            
            // 时间摘要
            let totalFocus = pomodoroDuration * pomodoroCycles
            let totalBreak = breakDuration * (pomodoroCycles - 1) + longBreakDuration
            let totalSession = totalFocus + totalBreak
            
            HStack {
                VStack(spacing: 4) {
                    Text("总专注时间")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(totalFocus) 分钟")
                        .font(.title3.bold())
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text("总休息时间")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(totalBreak) 分钟")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text("总时长")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(totalSession) 分钟")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 番茄周期可视化
            PomodoroTimelineView(
                pomodoroDuration: pomodoroDuration,
                breakDuration: breakDuration,
                cycles: pomodoroCycles,
                longBreakDuration: longBreakDuration
            )
        }
    }
}

// MARK: - Pomodoro Timeline View
struct PomodoroTimelineView: View {
    let pomodoroDuration: Int
    let breakDuration: Int
    let cycles: Int
    let longBreakDuration: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("番茄周期时间线")
                .font(.subheadline.bold())
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<cycles, id: \.self) { index in
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                )
                            Text("\(pomodoroDuration)m")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if index < cycles - 1 {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: 20, height: 2)
                            
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 16, height: 16)
                                Text("\(breakDuration)m")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: 20, height: 2)
                        }
                    }
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 20, height: 2)
                    
                    VStack(spacing: 2) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "figure.walk")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                        Text("\(longBreakDuration)m")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("专注").font(.caption2)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Text("短休息").font(.caption2)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 10, height: 10)
                    Text("长休息").font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Focus Restrictions Section
struct FocusRestrictionsSectionView: View {
    @Binding var disableNotifications: Bool
    @Binding var blockAllApps: Bool
    @Binding var reminderBefore5Min: Bool
    @Binding var breakEndReminder: Bool
    @Binding var enableBonusTime: Bool
    @Binding var bonusEntertainmentTime: Int
    let onSettingsChanged: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ToggleSettingRow(
                title: "专注期间禁用通知",
                subtitle: "防止通知打断专注",
                icon: "bell.slash",
                isOn: $disableNotifications
            )
            .onChange(of: disableNotifications) { _, newValue in
                onSettingsChanged("禁用通知", newValue ? "开启" : "关闭")
            }
            
            ToggleSettingRow(
                title: "专注期间禁止所有App",
                subtitle: "除白名单外的所有应用",
                icon: "app.badge.fill",
                isOn: $blockAllApps
            )
            .onChange(of: blockAllApps) { _, newValue in
                onSettingsChanged("禁止所有App", newValue ? "开启" : "关闭")
            }
            
            ToggleSettingRow(
                title: "番茄结束前5分钟提醒",
                subtitle: "提前准备收尾工作",
                icon: "bell.badge",
                isOn: $reminderBefore5Min
            )
            .onChange(of: reminderBefore5Min) { _, newValue in
                onSettingsChanged("5分钟提醒", newValue ? "开启" : "关闭")
            }
            
            ToggleSettingRow(
                title: "休息结束前1分钟提醒",
                subtitle: "准备开始下一个番茄",
                icon: "alarm",
                isOn: $breakEndReminder
            )
            .onChange(of: breakEndReminder) { _, newValue in
                onSettingsChanged("休息结束提醒", newValue ? "开启" : "关闭")
            }
            
            VStack(spacing: 12) {
                ToggleSettingRow(
                    title: "完成番茄后获取额外娱乐时间",
                    subtitle: "作为完成专注的奖励",
                    icon: "gift",
                    isOn: $enableBonusTime,
                    iconColor: .orange
                )
                .onChange(of: enableBonusTime) { _, newValue in
                    onSettingsChanged("额外娱乐时间", newValue ? "开启" : "关闭")
                }
                
                if enableBonusTime {
                    DurationPickerView(
                        title: "每个番茄奖励时间",
                        icon: "gamecontroller",
                        selectedMinutes: $bonusEntertainmentTime,
                        options: [5, 10, 15, 20, 30]
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .onChange(of: bonusEntertainmentTime) { _, newValue in
                        onSettingsChanged("每番茄奖励", "\(newValue)分钟")
                    }
                }
            }
            .animation(.easeInOut, value: enableBonusTime)
        }
    }
}

// MARK: - Pomodoro Activation Test Section
struct PomodoroActivationTestSectionView: View {
    @Binding var isConfigurationActive: Bool
    let isAuthorized: Bool
    let selectedActivityCount: Int
    let pomodoroDuration: Int
    let breakDuration: Int
    let pomodoroCycles: Int
    @Binding var isSimulatingSession: Bool
    @Binding var simulatedMinutes: Int
    @Binding var currentPhase: FocusGroupConfigView.PomodoroPhase
    @Binding var currentCycle: Int
    let onActivate: () -> Void
    let onDeactivate: () -> Void
    let onStartSimulation: () -> Void
    let onStopSimulation: () -> Void
    let addLog: (String, LogType) -> Void
    
    private var currentPhaseDuration: Int {
        switch currentPhase {
        case .focus: return pomodoroDuration
        case .shortBreak: return breakDuration
        case .longBreak: return 15
        case .completed: return 0
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isConfigurationActive ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isConfigurationActive ? .green : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isConfigurationActive ? "配置已激活" : "配置未激活")
                        .font(.headline)
                    Text(isConfigurationActive ? "干扰App已被屏蔽" : "点击激活开始专注")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(isConfigurationActive ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            
            HStack(spacing: 12) {
                if isConfigurationActive {
                    Button {
                        onDeactivate()
                    } label: {
                        Label("停用", systemImage: "stop.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button {
                        onActivate()
                    } label: {
                        Label("激活配置", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!isAuthorized || selectedActivityCount == 0)
                }
            }
            
            if isConfigurationActive {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🧪 番茄模拟器")
                        .font(.subheadline.bold())
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: currentPhase.icon)
                                    .foregroundColor(currentPhase.color)
                                Text(currentPhase.rawValue)
                                    .font(.headline)
                                    .foregroundColor(currentPhase.color)
                            }
                            Text("周期 \(currentCycle)/\(pomodoroCycles)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(simulatedMinutes)/\(currentPhaseDuration)")
                                .font(.title2.bold().monospacedDigit())
                            Text("分钟")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(currentPhase.color.opacity(0.1))
                    .cornerRadius(10)
                    
                    if currentPhaseDuration > 0 {
                        ProgressView(value: Double(simulatedMinutes), total: Double(currentPhaseDuration))
                            .tint(currentPhase.color)
                    }
                    
                    HStack(spacing: 12) {
                        if isSimulatingSession {
                            Button {
                                onStopSimulation()
                            } label: {
                                Label("暂停", systemImage: "pause.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                        } else {
                            Button {
                                onStartSimulation()
                            } label: {
                                Label("开始模拟", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                        
                        Button {
                            onStopSimulation()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                addLog("🔄 模拟已重置", .info)
                            }
                        } label: {
                            Label("重置", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("模拟器以1秒=1分钟的速度运行，用于快速测试番茄工作法流程")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            if !isAuthorized || selectedActivityCount == 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ 激活前置条件")
                        .font(.subheadline.bold())
                    
                    HStack(spacing: 8) {
                        Image(systemName: isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isAuthorized ? .green : .red)
                        Text("屏幕时间权限")
                            .font(.caption)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: selectedActivityCount > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(selectedActivityCount > 0 ? .green : .red)
                        Text("选择至少1个干扰App")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Focus Test Cases Documentation
struct FocusTestCasesDocumentationView: View {
    @State private var expandedCase: Int? = nil
    
    let testCases = [
        (id: 1, title: "TC-F001: 权限请求流程", steps: "1. 启动App，进入专注组配置\n2. 点击「检查权限」按钮\n3. 如未授权，点击「请求授权」\n4. 系统弹出授权对话框\n5. 选择「允许」\n预期结果：权限状态变为「已授权」", status: "Ready"),
        (id: 2, title: "TC-F002: App选择功能", steps: "1. 完成权限授权\n2. 点击「选择」按钮\n3. 在FamilyActivityPicker中选择干扰类App\n4. 确认选择\n预期结果：显示已选择的干扰App数量", status: "Ready"),
        (id: 3, title: "TC-F003: 番茄时钟配置", steps: "1. 设置番茄时长为25分钟\n2. 设置休息时长为5分钟\n3. 设置番茄周期为3个\n4. 查看时间摘要\n预期结果：总时长正确计算显示", status: "Ready"),
        (id: 4, title: "TC-F004: 番茄周期模拟", steps: "1. 激活配置\n2. 点击「开始模拟」\n3. 等待番茄阶段完成\n4. 观察自动切换到休息阶段\n5. 观察周期循环\n预期结果：完整的番茄-休息-番茄循环", status: "Ready"),
        (id: 5, title: "TC-F005: 额外娱乐时间奖励", steps: "1. 开启「额外娱乐时间奖励」\n2. 完成所有番茄周期\n3. 检查日志输出\n预期结果：日志显示获得的奖励时间", status: "Planned"),
        (id: 6, title: "TC-F006: 提前提醒功能", steps: "1. 开启5分钟提前提醒\n2. 开启休息结束提醒\n3. 运行模拟器\n4. 观察提醒触发时机\n预期结果：在正确时间点显示提醒日志", status: "Planned")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("以下测试用例可在模拟器中验证：")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ForEach(testCases, id: \.id) { testCase in
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation {
                            expandedCase = expandedCase == testCase.id ? nil : testCase.id
                        }
                    } label: {
                        HStack {
                            StatusBadgeView(testCase.status, color: testCase.status == "Ready" ? .green : .orange)
                            Text(testCase.title).font(.subheadline).foregroundColor(.primary)
                            Spacer()
                            Image(systemName: expandedCase == testCase.id ? "chevron.up" : "chevron.down").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    
                    if expandedCase == testCase.id {
                        Text(testCase.steps).font(.caption).foregroundStyle(.secondary).padding(8).background(Color(.systemGray6)).cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FocusGroupConfigView()
    }
}
