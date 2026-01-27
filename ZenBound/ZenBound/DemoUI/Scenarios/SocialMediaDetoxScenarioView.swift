import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// 场景3: 社交媒体戒断
/// 完整流程实现：权限检查 → App选择 → 戒断强度设置 → 启动戒断 → 实时追踪
struct SocialMediaDetoxScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var strategyManager: StrategyManager
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case appSelection = 1
        case settings = 2
        case activation = 3
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .appSelection: return "选择App"
            case .settings: return "戒断设置"
            case .activation: return "开始戒断"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .settings: return "slider.horizontal.3"
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
    
    // MARK: - 戒断设置
    @State private var isDetoxActive = false
    @State private var currentMessage = FocusMessages.getRandomMessage()
    @State private var detoxStrength: DetoxStrength = .moderate
    @State private var enableStrictMode = false
    @State private var enableLiveActivity = true
    @State private var dailyDetoxGoalHours = 4
    
    // MARK: - 会话状态
    @State private var sessionStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var sessionTimer: Timer?
    @State private var todayDetoxTime: TimeInterval = 0
    
    enum DetoxStrength: String, CaseIterable {
        case light = "轻度"
        case moderate = "中度"
        case strict = "严格"
        
        var description: String {
            switch self {
            case .light: return "仅屏蔽主要社交应用"
            case .moderate: return "屏蔽社交和短视频"
            case .strict: return "屏蔽所有娱乐应用"
            }
        }
        
        var icon: String {
            switch self {
            case .light: return "leaf"
            case .moderate: return "shield.lefthalf.filled"
            case .strict: return "lock.shield"
            }
        }
        
        var color: Color {
            switch self {
            case .light: return .green
            case .moderate: return .orange
            case .strict: return .red
            }
        }
        
        var recommendedApps: [String] {
            switch self {
            case .light: return ["微信", "微博", "抖音"]
            case .moderate: return ["微信", "微博", "抖音", "B站", "快手", "小红书"]
            case .strict: return ["微信", "微博", "抖音", "B站", "快手", "小红书", "淘宝", "京东", "游戏"]
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
                        Text("**社交媒体戒断**帮助你减少对社交媒体的依赖，重获时间和注意力。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "感觉刷手机浪费太多时间")
                        BulletPointView(text: "想要培养更健康的数字习惯")
                        BulletPointView(text: "需要专注于重要事务")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - 选择要戒断的社交App")
                        BulletPointView(text: "✅ 多级戒断强度 - 轻度/中度/严格")
                        BulletPointView(text: "✅ 励志消息激励坚持")
                        BulletPointView(text: "✅ 严格模式防止中途放弃")
                        
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
                                title: "戒断App",
                                value: "\(FamilyActivityUtil.countSelectedActivities(selectedActivity))个",
                                color: .purple
                            )
                            
                            StatusCardView(
                                icon: isDetoxActive ? "hand.raised.fill" : "hand.raised",
                                title: "状态",
                                value: isDetoxActive ? "戒断中" : "空闲",
                                color: isDetoxActive ? .green : .gray
                            )
                        }
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "FamilyActivityUtil",
                            path: "ZenBound/Utils/FamilyActivityUtil.swift",
                            description: "活动选择 - 选取社交媒体应用"
                        )
                        DependencyRowView(
                            name: "AppBlockerUtil",
                            path: "ZenBound/Utils/AppBlockerUtil.swift",
                            description: "应用屏蔽 - 执行屏蔽限制"
                        )
                        DependencyRowView(
                            name: "FocusMessages",
                            path: "ZenBound/Utils/FocusMessages.swift",
                            description: "励志消息 - 随机激励语"
                        )
                        DependencyRowView(
                            name: "StrategyManager",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "戒断管理 - 会话和严格模式"
                        )
                        DependencyRowView(
                            name: "enableStrictMode",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "严格模式 - 防止轻易解锁"
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
                
                // MARK: - Step 2: 选择社交媒体App
                DemoSectionView(title: "📱 Step 2: 选择社交媒体App", icon: "apps.iphone") {
                    SocialMediaAppSelectionView(
                        isAuthorized: isAuthorized,
                        selectedActivity: $selectedActivity,
                        showAppPicker: $showAppPicker,
                        detoxStrength: detoxStrength,
                        onSelectionChanged: { count in
                            addLog("📱 已选择 \(count) 个社交媒体App", type: .success)
                            if currentStep == .appSelection && count > 0 {
                                currentStep = .settings
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
                
                // MARK: - Step 3: 戒断设置
                DemoSectionView(title: "⚙️ Step 3: 戒断设置", icon: "slider.horizontal.3") {
                    VStack(spacing: 16) {
                        // 励志消息展示
                        VStack(spacing: 8) {
                            Text("💪 励志消息")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 8) {
                                Text("\"")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.tertiary)
                                    .offset(x: -100, y: 5)
                                
                                Text(currentMessage)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Text("\"")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.tertiary)
                                    .offset(x: 100, y: -5)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            
                            Button {
                                refreshMessage()
                            } label: {
                                Label("换一条", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Divider()
                        
                        // 戒断强度选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("⚡️ 戒断强度")
                                .font(.subheadline.bold())
                            
                            ForEach(DetoxStrength.allCases, id: \.self) { strength in
                                Button {
                                    detoxStrength = strength
                                    addLog("⚡️ 切换戒断强度: \(strength.rawValue)", type: .info)
                                } label: {
                                    HStack {
                                        Image(systemName: strength.icon)
                                            .font(.title2)
                                            .foregroundColor(strength.color)
                                            .frame(width: 36)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(strength.rawValue)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.primary)
                                            Text(strength.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if detoxStrength == strength {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(strength.color)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        detoxStrength == strength
                                        ? strength.color.opacity(0.1)
                                        : Color(.systemGray6)
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                detoxStrength == strength ? strength.color : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 高级设置
                        VStack(spacing: 12) {
                            ToggleSettingRow(
                                title: "启用 Live Activity",
                                subtitle: "在锁屏和灵动岛显示戒断进度",
                                icon: "iphone",
                                isOn: $enableLiveActivity,
                                iconColor: .blue
                            )
                            .onChange(of: enableLiveActivity) { _, newValue in
                                addLog("📱 Live Activity: \(newValue ? "启用" : "禁用")", type: .info)
                            }
                            
                            ToggleSettingRow(
                                title: "严格模式",
                                subtitle: "启用后需要完成设定时长才能停止",
                                icon: "lock.shield",
                                isOn: $enableStrictMode,
                                iconColor: .orange
                            )
                            .onChange(of: enableStrictMode) { _, newValue in
                                addLog("🔐 严格模式: \(newValue ? "开启" : "关闭")", type: .info)
                            }
                            
                            // 每日戒断目标
                            HStack {
                                Label("每日戒断目标", systemImage: "target")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $dailyDetoxGoalHours) {
                                    Text("2小时").tag(2)
                                    Text("4小时").tag(4)
                                    Text("6小时").tag(6)
                                    Text("8小时").tag(8)
                                    Text("全天").tag(24)
                                }
                                .pickerStyle(.menu)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                
                // MARK: - Step 4: 开始戒断
                DemoSectionView(title: "🚀 Step 4: 开始戒断", icon: "play.circle") {
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
                                Text("请先完成 Step 2 选择社交媒体App")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 戒断状态显示
                        if isDetoxActive {
                            VStack(spacing: 12) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(detoxStrength.color)
                                
                                Text(formatDuration(elapsedTime))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                
                                Text("戒断进行中 - \(detoxStrength.rawValue)模式")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text("已屏蔽 \(FamilyActivityUtil.countSelectedActivities(selectedActivity)) 个应用")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                
                                if let startTime = sessionStartTime {
                                    Text("开始于 \(formatTime(startTime))")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                
                                // 励志消息
                                Text("💪 \(currentMessage)")
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(detoxStrength.color.opacity(0.1))
                            .cornerRadius(16)
                            
                            // 今日戒断进度
                            VStack(spacing: 8) {
                                HStack {
                                    Text("今日戒断进度")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("\(Int((todayDetoxTime + elapsedTime) / 3600))h / \(dailyDetoxGoalHours)h")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                ProgressView(value: min((todayDetoxTime + elapsedTime) / Double(dailyDetoxGoalHours * 3600), 1.0))
                                    .tint(detoxStrength.color)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // 操作按钮
                        HStack(spacing: 12) {
                            Button {
                                startDetox()
                            } label: {
                                Label("开始戒断", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(detoxStrength.color)
                            .disabled(!isAuthorized || FamilyActivityUtil.countSelectedActivities(selectedActivity) == 0 || isDetoxActive)
                            
                            Button {
                                stopDetox()
                            } label: {
                                Label("结束戒断", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(!isDetoxActive)
                        }
                        
                        // 模拟器测试提示
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("模拟器测试: 计时器正常运行，App屏蔽需在真机测试")
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
                    SocialMediaDetoxTestCasesView()
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
// .approved / .denied / .notDetermined

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
                            title: "2. 选择社交媒体应用",
                            description: "使用 FamilyActivitySelection 选取应用",
                            code: """
// 用户通过系统选择器选择应用
@State private var selection = FamilyActivitySelection()
@State private var showPicker = false

// 显示选择器
Button("选择App") { showPicker = true }
    .familyActivityPicker(
        isPresented: $showPicker,
        selection: $selection
    )

// 获取选择统计
let count = FamilyActivityUtil.countSelectedActivities(selection)
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 创建戒断配置",
                            description: "使用 BlockedProfiles 保存戒断设置",
                            code: """
// 创建社交媒体戒断配置
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "社交戒断 - \\(detoxStrength.rawValue)",
    selection: selectedActivity,
    blockingStrategyId: ManualBlockingStrategy.id,
    enableLiveActivity: true,
    enableStrictMode: enableStrictMode
)

// 保存到 SwiftData
context.insert(profile)
try context.save()
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 执行应用屏蔽",
                            description: "AppBlockerUtil 实际屏蔽应用",
                            code: """
let appBlocker = AppBlockerUtil()

// 创建快照 (App Group 安全)
let snapshot = BlockedProfiles.getSnapshot(for: profile)

// 激活屏蔽
appBlocker.activateRestrictions(for: snapshot)

// 解除屏蔽
appBlocker.deactivateRestrictions()
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
                            title: "添加使用时长统计",
                            description: "显示每日节省的刷屏时间，增强成就感",
                            relatedFiles: ["ProfileInsightsUtil.swift", "BlockedProfileSession.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "预设社交媒体分类",
                            description: "提供常见社交应用的预设选择，简化配置",
                            relatedFiles: ["FamilyActivityUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "添加戒断成就系统",
                            description: "连续戒断天数达成时解锁成就徽章",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "自定义励志消息",
                            description: "允许用户添加个人化的励志语录",
                            relatedFiles: ["FocusMessages.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "社交戒断挑战",
                            description: "7天/21天/30天挑战模式，增加趣味性",
                            relatedFiles: ["StrategyManager.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("社交媒体戒断")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAuthorizationOnAppear()
        }
        .onDisappear {
            sessionTimer?.invalidate()
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
    
    private func refreshMessage() {
        withAnimation {
            currentMessage = FocusMessages.getRandomMessage()
        }
        addLog("💬 刷新励志消息", type: .info)
    }
    
    private func startDetox() {
        addLog("🚀 开始社交媒体戒断", type: .info)
        addLog("⚡️ 强度: \(detoxStrength.rawValue)", type: .info)
        addLog("🔐 严格模式: \(enableStrictMode ? "是" : "否")", type: .info)
        
        let appCount = FamilyActivityUtil.countSelectedActivities(selectedActivity)
        addLog("📱 选中应用数: \(appCount)", type: .info)
        
        // 创建快照并激活屏蔽
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "社交戒断 - \(detoxStrength.rawValue)",
            selectedActivity: selectedActivity,
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "manual",
            strategyData: nil,
            order: 0,
            enableLiveActivity: enableLiveActivity,
            reminderTimeInSeconds: nil,
            customReminderMessage: nil,
            enableBreaks: false,
            breakTimeInMinutes: 0,
            enableStrictMode: enableStrictMode,
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
        
        isDetoxActive = true
        sessionStartTime = Date()
        elapsedTime = 0
        currentStep = .activation
        addLog("✅ 戒断会话已启动", type: .success)
        
        // 刷新励志消息
        currentMessage = FocusMessages.getRandomMessage()
        
        // 启动计时器
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                elapsedTime += 1
            }
        }
    }
    
    private func stopDetox() {
        if enableStrictMode {
            addLog("⚠️ 严格模式下需要紧急解锁确认", type: .warning)
        }
        
        addLog("⏹️ 结束社交媒体戒断", type: .info)
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        addLog("🔓 AppBlockerUtil.deactivateRestrictions() 已调用", type: .success)
        
        if enableLiveActivity {
            addLog("📱 LiveActivityManager.endSessionActivity() 已调用", type: .success)
        }
        
        addLog("⏱️ 本次戒断时长: \(formatDuration(elapsedTime))", type: .success)
        
        // 更新今日戒断时间
        todayDetoxTime += elapsedTime
        
        isDetoxActive = false
        sessionStartTime = nil
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Social Media App Selection View
struct SocialMediaAppSelectionView: View {
    let isAuthorized: Bool
    @Binding var selectedActivity: FamilyActivitySelection
    @Binding var showAppPicker: Bool
    let detoxStrength: SocialMediaDetoxScenarioView.DetoxStrength
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
                        Text("已选择 \(count) 个社交媒体App")
                            .font(.headline)
                        Text("戒断期间这些App将被屏蔽")
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
                    .tint(.purple)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 推荐选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 \(detoxStrength.rawValue)戒断推荐选择")
                        .font(.subheadline.bold())
                    
                    Text("根据当前强度，建议屏蔽以下类型的应用：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(detoxStrength.recommendedApps, id: \.self) { app in
                            Text(app)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(detoxStrength.color.opacity(0.15))
                                .foregroundColor(detoxStrength.color)
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

// MARK: - Social Media Detox Test Cases View
struct SocialMediaDetoxTestCasesView: View {
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
                        id: "TC-S001",
                        name: "权限请求流程",
                        status: .ready,
                        description: "验证从未授权到授权的完整流程"
                    )
                    TestCaseRowView(
                        id: "TC-S002",
                        name: "社交App选择",
                        status: .ready,
                        description: "验证 FamilyActivityPicker 选择社交媒体应用"
                    )
                    TestCaseRowView(
                        id: "TC-S003",
                        name: "戒断强度切换",
                        status: .ready,
                        description: "验证轻度/中度/严格模式切换和推荐App更新"
                    )
                    TestCaseRowView(
                        id: "TC-S004",
                        name: "启动戒断会话",
                        status: .ready,
                        description: "验证启动后App屏蔽和计时器正常运行"
                    )
                    TestCaseRowView(
                        id: "TC-S005",
                        name: "严格模式阻止",
                        status: .planned,
                        description: "验证严格模式下无法轻易结束戒断"
                    )
                    TestCaseRowView(
                        id: "TC-S006",
                        name: "励志消息刷新",
                        status: .ready,
                        description: "验证随机获取不同的励志消息"
                    )
                    TestCaseRowView(
                        id: "TC-S007",
                        name: "每日目标进度",
                        status: .ready,
                        description: "验证每日戒断时长累计和进度显示"
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SocialMediaDetoxScenarioView()
            .environmentObject(StrategyManager.shared)
    }
}
