import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// 场景1: 工作专注模式
/// 完整流程实现：权限检查 → App选择 → 一键启动专注 → 实时显示进度 → 结束会话
struct WorkFocusScenarioView: View {
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
            case .settings: return "专注设置"
            case .activation: return "开始专注"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .settings: return "gearshape"
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
    
    // MARK: - 专注设置
    @State private var enableLiveActivity = true
    @State private var enableStrictMode = false
    @State private var reminderTimeMinutes = 30
    @State private var customReminderMessage = "继续专注，你做得很好！"
    
    // MARK: - 会话状态
    @State private var isBlocking = false
    @State private var sessionStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var sessionTimer: Timer?
    
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
                        Text("**工作专注模式**适用于需要集中注意力完成工作任务的场景。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "处理重要工作任务时，屏蔽社交媒体和娱乐应用")
                        BulletPointView(text: "开会时屏蔽通知干扰")
                        BulletPointView(text: "写作或编程时保持专注")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - 选择要屏蔽的干扰App")
                        BulletPointView(text: "✅ 一键启动/停止")
                        BulletPointView(text: "✅ 实时显示专注时长 (Live Activity)")
                        
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
                                icon: isBlocking ? "lock.fill" : "lock.open",
                                title: "状态",
                                value: isBlocking ? "专注中" : "空闲",
                                color: isBlocking ? .green : .gray
                            )
                        }
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "BlockedProfiles",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "配置管理 - 定义要屏蔽的应用"
                        )
                        DependencyRowView(
                            name: "ManualBlockingStrategy",
                            path: "ZenBound/Models/Strategies/ManualBlockingStrategy.swift",
                            description: "手动控制策略 - 即时开始/停止"
                        )
                        DependencyRowView(
                            name: "LiveActivityManager",
                            path: "ZenBound/Utils/LiveActivityManager.swift",
                            description: "实时活动 - 锁屏和灵动岛显示"
                        )
                        DependencyRowView(
                            name: "AppBlockerUtil",
                            path: "ZenBound/Utils/AppBlockerUtil.swift",
                            description: "应用屏蔽 - Screen Time API封装"
                        )
                        DependencyRowView(
                            name: "StrategyManager",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "会话协调 - 管理屏蔽生命周期"
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
                    WorkAppSelectionSectionView(
                        isAuthorized: isAuthorized,
                        selectedActivity: $selectedActivity,
                        showAppPicker: $showAppPicker,
                        onSelectionChanged: { count in
                            addLog("📱 已选择 \(count) 个干扰App", type: .success)
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
                
                // MARK: - Step 3: 专注设置
                DemoSectionView(title: "⚙️ Step 3: 专注设置", icon: "gearshape") {
                    VStack(spacing: 16) {
                        ToggleSettingRow(
                            title: "启用 Live Activity",
                            subtitle: "在锁屏和灵动岛显示专注进度",
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
                            addLog("🔒 严格模式: \(newValue ? "启用" : "禁用")", type: .info)
                        }
                        
                        // 提醒设置
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("定时提醒", systemImage: "bell")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $reminderTimeMinutes) {
                                    Text("15分钟").tag(15)
                                    Text("30分钟").tag(30)
                                    Text("45分钟").tag(45)
                                    Text("60分钟").tag(60)
                                    Text("关闭").tag(0)
                                }
                                .pickerStyle(.menu)
                            }
                            
                            if reminderTimeMinutes > 0 {
                                TextField("自定义提醒消息", text: $customReminderMessage)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // MARK: - Step 4: 开始专注
                DemoSectionView(title: "🚀 Step 4: 开始专注", icon: "play.circle") {
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
                                Text("请先完成 Step 2 选择干扰App")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 专注状态显示
                        if isBlocking {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                
                                Text(formatDuration(elapsedTime))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                
                                Text("专注中...")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                if let startTime = sessionStartTime {
                                    Text("开始于 \(formatTime(startTime))")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        // 操作按钮
                        HStack(spacing: 12) {
                            Button {
                                startWorkFocus()
                            } label: {
                                Label("开始专注", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(!isAuthorized || FamilyActivityUtil.countSelectedActivities(selectedActivity) == 0 || isBlocking)
                            
                            Button {
                                stopWorkFocus()
                            } label: {
                                Label("结束专注", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(!isBlocking)
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
                    WorkFocusTestCasesView()
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 创建工作配置",
                            description: "使用 BlockedProfiles.createProfile 创建专注配置",
                            code: """
// 创建工作专注配置
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "工作专注",
    selection: workAppsSelection,     // FamilyActivitySelection
    blockingStrategyId: ManualBlockingStrategy.id,
    enableLiveActivity: true,         // 启用灵动岛显示
    enableStrictMode: false           // 非严格模式，可随时停止
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 启动专注会话",
                            description: "使用 StrategyManager 启动屏蔽会话",
                            code: """
// 获取策略并启动
let strategy = StrategyManager.getStrategyFromId(
    id: profile.blockingStrategyId ?? ManualBlockingStrategy.id
)

// 启动屏蔽
strategy.startBlocking(
    context: context,
    profile: profile,
    forceStart: false
)

// 启动 Live Activity
LiveActivityManager.shared.startSessionActivity(session: session)
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 停止专注会话",
                            description: "结束会话并更新统计",
                            code: """
// 停止屏蔽
strategy.stopBlocking(context: context, session: session)

// 结束 Live Activity
LiveActivityManager.shared.endSessionActivity()

// 会话数据自动保存到 BlockedProfileSession
// 可通过 ProfileInsightsUtil 查看统计
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
                            title: "添加专注提醒通知",
                            description: "当专注时长达到设定目标时，通过通知提醒用户",
                            relatedFiles: ["TimersUtil.swift", "LiveActivityManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "支持专注音效",
                            description: "启动/停止时播放提示音，增强仪式感",
                            relatedFiles: ["StrategyManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "添加专注统计小组件",
                            description: "在桌面小组件显示今日专注时长",
                            relatedFiles: ["widget/widgetBundle.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("工作专注模式")
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
    
    private func startWorkFocus() {
        addLog("🚀 启动工作专注模式", type: .info)
        
        let appCount = FamilyActivityUtil.countSelectedActivities(selectedActivity)
        addLog("📱 屏蔽App数量: \(appCount)", type: .info)
        
        // 创建快照并激活屏蔽
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "工作专注",
            selectedActivity: selectedActivity,
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "manual",
            strategyData: nil,
            order: 0,
            enableLiveActivity: enableLiveActivity,
            reminderTimeInSeconds: reminderTimeMinutes > 0 ? UInt32(reminderTimeMinutes * 60) : nil,
            customReminderMessage: customReminderMessage,
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
        
        isBlocking = true
        sessionStartTime = Date()
        elapsedTime = 0
        currentStep = .activation
        addLog("✅ 专注会话已启动", type: .success)
        
        // 启动计时器
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                elapsedTime += 1
                
                // 检查提醒时间
                if reminderTimeMinutes > 0 && Int(elapsedTime) == reminderTimeMinutes * 60 {
                    addLog("⏰ 提醒: \(customReminderMessage)", type: .warning)
                }
            }
        }
    }
    
    private func stopWorkFocus() {
        addLog("⏹️ 结束工作专注模式", type: .info)
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        addLog("🔓 AppBlockerUtil.deactivateRestrictions() 已调用", type: .success)
        
        if enableLiveActivity {
            addLog("📱 LiveActivityManager.endSessionActivity() 已调用", type: .success)
        }
        
        addLog("⏱️ 本次专注时长: \(formatDuration(elapsedTime))", type: .success)
        
        isBlocking = false
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

// MARK: - Work App Selection Section View
struct WorkAppSelectionSectionView: View {
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
                    .tint(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 推荐选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 推荐屏蔽的干扰App")
                        .font(.subheadline.bold())
                    
                    Text("工作专注时建议选择：社交媒体、游戏、视频、新闻等可能分散注意力的App")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(["微信", "微博", "抖音", "B站", "淘宝", "游戏"], id: \.self) { category in
                            Text(category)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
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

// MARK: - Work Focus Test Cases View
struct WorkFocusTestCasesView: View {
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
                        id: "TC-W001",
                        name: "权限请求流程",
                        status: .ready,
                        description: "验证从未授权到授权的完整流程"
                    )
                    TestCaseRowView(
                        id: "TC-W002",
                        name: "App选择功能",
                        status: .ready,
                        description: "验证 FamilyActivityPicker 选择和计数"
                    )
                    TestCaseRowView(
                        id: "TC-W003",
                        name: "一键启动专注",
                        status: .ready,
                        description: "验证启动后App屏蔽和计时器正常运行"
                    )
                    TestCaseRowView(
                        id: "TC-W004",
                        name: "结束专注会话",
                        status: .ready,
                        description: "验证结束后屏蔽解除和时长记录"
                    )
                    TestCaseRowView(
                        id: "TC-W005",
                        name: "Live Activity显示",
                        status: .planned,
                        description: "验证灵动岛和锁屏显示专注进度"
                    )
                    TestCaseRowView(
                        id: "TC-W006",
                        name: "定时提醒功能",
                        status: .ready,
                        description: "验证达到设定时间后触发提醒"
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkFocusScenarioView()
            .environmentObject(StrategyManager.shared)
    }
}
