import SwiftUI
import SwiftData
import FamilyControls

/// 场景7: 紧急解锁机制
/// 严格模式下的安全阀门，防止完全被锁死
/// 完整流程：权限检查 → App选择 → 启动严格模式会话 → 紧急解锁 → 数据分析
struct EmergencyUnlockScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var strategyManager: StrategyManager
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case appSelection = 1
        case strictModeSetup = 2
        case emergencyUnlock = 3
        case analytics = 4
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .appSelection: return "选择App"
            case .strictModeSetup: return "严格模式"
            case .emergencyUnlock: return "紧急解锁"
            case .analytics: return "解锁分析"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .strictModeSetup: return "lock.shield"
            case .emergencyUnlock: return "exclamationmark.shield"
            case .analytics: return "chart.bar"
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
    
    // MARK: - 严格模式设置
    @State private var isStrictModeEnabled = true
    @State private var maxUnlocksPerPeriod = 3
    @State private var resetPeriodWeeks = 1
    @State private var unlockCooldownMinutes = 30  // 解锁后冷却时间
    @State private var requireReasonForUnlock = true
    
    // MARK: - 会话状态
    @State private var isSessionActive = false
    @State private var sessionStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var sessionTimer: Timer?
    
    // MARK: - 紧急解锁状态
    @State private var remainingUnlocks = 3
    @State private var showConfirmation = false
    @State private var unlockReason = ""
    @State private var lastUnlockTime: Date?
    @State private var isInCooldown = false
    
    // MARK: - 解锁历史（模拟数据）
    @State private var unlockHistory: [UnlockRecord] = []
    
    struct UnlockRecord: Identifiable {
        let id = UUID()
        let date: Date
        let reason: String
        let profileName: String
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
                        Text("**紧急解锁机制**是严格模式下的安全阀门，确保用户在真正紧急情况下可以解除屏蔽。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "紧急工作电话需要使用被屏蔽的应用")
                        BulletPointView(text: "家人紧急联系需要使用社交应用")
                        BulletPointView(text: "意外情况需要临时解除限制")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - 选择严格限制的App")
                        BulletPointView(text: "✅ 有限的解锁次数（如每周3次）")
                        BulletPointView(text: "✅ 解锁需要确认+原因，防止误触")
                        BulletPointView(text: "✅ 冷却期和自动重置机制")
                        BulletPointView(text: "✅ 解锁数据统计分析")
                        
                        // 当前状态卡片
                        HStack(spacing: 12) {
                            StatusCardView(
                                icon: isAuthorized ? "checkmark.shield.fill" : "shield.slash",
                                title: "权限",
                                value: isAuthorized ? "已授权" : "未授权",
                                color: isAuthorized ? .green : .red
                            )
                            
                            StatusCardView(
                                icon: "exclamationmark.shield.fill",
                                title: "剩余解锁",
                                value: "\(remainingUnlocks)次",
                                color: remainingUnlocks > 0 ? .red : .gray
                            )
                            
                            StatusCardView(
                                icon: isSessionActive ? "lock.fill" : "lock.open",
                                title: "会话",
                                value: isSessionActive ? "进行中" : "未激活",
                                color: isSessionActive ? .orange : .gray
                            )
                        }
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "StrategyManager.emergencyUnblock()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "紧急解锁 - 执行解锁操作"
                        )
                        DependencyRowView(
                            name: "enableStrictMode",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "严格模式 - 启用紧急解锁限制"
                        )
                        DependencyRowView(
                            name: "emergencyUnblocksRemaining",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "剩余次数 - UserDefaults存储"
                        )
                        DependencyRowView(
                            name: "getNextResetDate()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "重置时间 - 计算下次重置日期"
                        )
                        DependencyRowView(
                            name: "checkAndResetEmergencyUnblocks()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "自动重置 - 检查并重置次数"
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
                
                // MARK: - Step 2: 选择要严格限制的App
                DemoSectionView(title: "📱 Step 2: 选择限制App", icon: "apps.iphone") {
                    EmergencyAppSelectionSectionView(
                        isAuthorized: isAuthorized,
                        selectedActivity: $selectedActivity,
                        showAppPicker: $showAppPicker,
                        onSelectionChanged: { count in
                            addLog("📱 已选择 \(count) 个需要严格限制的App", type: .success)
                            if currentStep == .appSelection && count > 0 {
                                currentStep = .strictModeSetup
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
                
                // MARK: - Step 3: 严格模式设置
                DemoSectionView(title: "🔒 Step 3: 严格模式设置", icon: "lock.shield") {
                    VStack(spacing: 16) {
                        // 启用严格模式
                        EmergencyToggleSettingRow(
                            title: "启用严格模式",
                            subtitle: "启用后只能通过紧急解锁结束会话",
                            icon: "lock.shield.fill",
                            isOn: $isStrictModeEnabled,
                            iconColor: .red
                        )
                        .onChange(of: isStrictModeEnabled) { _, newValue in
                            addLog("🔒 严格模式: \(newValue ? "启用" : "禁用")", type: .info)
                        }
                        
                        // 每周解锁次数
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.shield")
                                    .foregroundColor(.orange)
                                Text("每周期解锁次数")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(maxUnlocksPerPeriod) 次")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Picker("解锁次数", selection: $maxUnlocksPerPeriod) {
                                ForEach([1, 2, 3, 5, 10], id: \.self) { count in
                                    Text("\(count) 次").tag(count)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: maxUnlocksPerPeriod) { _, newValue in
                                addLog("📊 每周期解锁次数: \(newValue)", type: .info)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // 重置周期
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                Text("重置周期")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(resetPeriodWeeks) 周")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Picker("重置周期", selection: $resetPeriodWeeks) {
                                ForEach([1, 2, 4], id: \.self) { weeks in
                                    Text("\(weeks) 周").tag(weeks)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: resetPeriodWeeks) { _, newValue in
                                addLog("📅 重置周期: \(newValue) 周", type: .info)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // 解锁冷却时间
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.purple)
                                Text("解锁后冷却时间")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(unlockCooldownMinutes) 分钟")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Stepper("冷却时间", value: $unlockCooldownMinutes, in: 0...120, step: 15)
                                .labelsHidden()
                            
                            Text("冷却期内无法再次启动严格模式会话")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // 要求输入原因
                        EmergencyToggleSettingRow(
                            title: "解锁时要求输入原因",
                            subtitle: "便于后续反思和分析",
                            icon: "text.bubble",
                            isOn: $requireReasonForUnlock,
                            iconColor: .green
                        )
                        
                        // 启动严格模式会话
                        Button {
                            if isSessionActive {
                                // 在严格模式下，不允许直接停止，只能紧急解锁
                                addLog("⚠️ 严格模式下只能使用紧急解锁结束会话", type: .warning)
                            } else {
                                startStrictModeSession()
                            }
                        } label: {
                            HStack {
                                Image(systemName: isSessionActive ? "lock.fill" : "lock.open.fill")
                                Text(isSessionActive ? "严格模式进行中..." : "启动严格模式会话")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isSessionActive ? .orange : .red)
                        .disabled(!isAuthorized || FamilyActivityUtil.countSelectedActivities(selectedActivity) == 0 || !isStrictModeEnabled || isInCooldown)
                        
                        if isInCooldown {
                            let cooldownRemaining = cooldownRemainingTime
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.purple)
                                Text("冷却中: \(cooldownRemaining)")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if isSessionActive {
                            // 会话计时显示
                            VStack(spacing: 8) {
                                Text(formatDuration(elapsedTime))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                                
                                Text("严格模式会话进行中")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // MARK: - Step 4: 紧急解锁操作
                DemoSectionView(title: "🆘 Step 4: 紧急解锁", icon: "exclamationmark.shield") {
                    VStack(spacing: 16) {
                        // 剩余次数显示
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.red.opacity(0.2), lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(remainingUnlocks) / CGFloat(maxUnlocksPerPeriod))
                                    .stroke(remainingUnlocks > 0 ? Color.red : Color.gray, lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut, value: remainingUnlocks)
                                
                                VStack {
                                    Text("\(remainingUnlocks)")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(remainingUnlocks > 0 ? .red : .gray)
                                    Text("剩余次数")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // 重置信息
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("重置周期: \(resetPeriodWeeks) 周")
                                    .font(.subheadline)
                                Text("下次重置: \(nextResetDateString)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        // 紧急解锁按钮
                        Button {
                            if requireReasonForUnlock {
                                showConfirmation = true
                            } else {
                                performEmergencyUnlock()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                Text("紧急解锁")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(remainingUnlocks <= 0 || !isSessionActive)
                        
                        if remainingUnlocks <= 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("本周期解锁次数已用完，等待 \(nextResetDateString) 重置")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if !isSessionActive && remainingUnlocks > 0 {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("当前没有活动的严格模式会话")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Divider()
                        
                        // 管理操作
                        HStack {
                            Button {
                                resetUnlocks()
                            } label: {
                                Label("重置次数", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                addMockUnlockHistory()
                            } label: {
                                Label("模拟解锁", systemImage: "plus.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // MARK: - Step 5: 解锁数据分析
                DemoSectionView(title: "📊 Step 5: 解锁数据分析", icon: "chart.bar") {
                    VStack(spacing: 16) {
                        // 解锁统计概览
                        HStack(spacing: 12) {
                            UnlockStatCardView(
                                title: "本周解锁",
                                value: "\(unlockHistory.count)",
                                icon: "shield.slash",
                                color: .red
                            )
                            UnlockStatCardView(
                                title: "本月解锁",
                                value: "\(unlockHistory.count + 2)",
                                icon: "calendar",
                                color: .orange
                            )
                            UnlockStatCardView(
                                title: "总计解锁",
                                value: "\(unlockHistory.count + 5)",
                                icon: "chart.bar",
                                color: .blue
                            )
                        }
                        
                        // 解锁原因分布
                        VStack(alignment: .leading, spacing: 8) {
                            Text("解锁原因分布")
                                .font(.subheadline.bold())
                            
                            UnlockReasonRow(reason: "紧急工作电话", count: 3, percentage: 42, color: .blue)
                            UnlockReasonRow(reason: "家人联系", count: 2, percentage: 28, color: .green)
                            UnlockReasonRow(reason: "医疗预约", count: 1, percentage: 14, color: .purple)
                            UnlockReasonRow(reason: "其他", count: 1, percentage: 14, color: .gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // 解锁时段分布
                        VStack(alignment: .leading, spacing: 8) {
                            Text("解锁时段分布")
                                .font(.subheadline.bold())
                            
                            HStack(spacing: 4) {
                                ForEach(0..<24, id: \.self) { hour in
                                    let intensity = getUnlockIntensityForHour(hour)
                                    Rectangle()
                                        .fill(Color.red.opacity(intensity))
                                        .frame(height: 30)
                                        .cornerRadius(2)
                                }
                            }
                            
                            HStack {
                                Text("00:00")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Text("12:00")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Text("23:00")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Text("上午9-11点是解锁高峰期，建议在此时段设置更严格的限制")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - 解锁历史
                DemoSectionView(title: "📜 解锁历史", icon: "clock.arrow.circlepath") {
                    VStack(alignment: .leading, spacing: 8) {
                        if unlockHistory.isEmpty {
                            Text("暂无解锁记录")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(unlockHistory) { record in
                                UnlockHistoryRow(
                                    date: formatUnlockDate(record.date),
                                    reason: record.reason
                                )
                            }
                        }
                        
                        // 添加默认历史记录示例
                        if unlockHistory.isEmpty {
                            UnlockHistoryRow(date: "今天 14:32", reason: "紧急工作电话")
                            UnlockHistoryRow(date: "昨天 09:15", reason: "家人急事")
                            UnlockHistoryRow(date: "3天前 18:45", reason: "医疗预约确认")
                        }
                        
                        Text("仅显示最近7天记录")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 检查剩余次数",
                            description: "获取当前可用的紧急解锁次数",
                            code: """
let manager = StrategyManager.shared

// 获取剩余次数
let remaining = manager.getRemainingEmergencyUnblocks()
// 返回: 0-3 (默认每周3次)

// 获取重置周期
let weeks = manager.getResetPeriodInWeeks()
// 返回: 1-4 周

// 获取下次重置日期
if let nextReset = manager.getNextResetDate() {
    // 显示倒计时或日期
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 执行紧急解锁",
                            description: "消耗一次解锁机会并解除屏蔽",
                            code: """
// 执行紧急解锁
manager.emergencyUnblock(context: modelContext)

// 内部逻辑:
// 1. 检查 remainingUnlocks > 0
// 2. remainingUnlocks -= 1
// 3. 调用 stopBlocking()
// 4. 记录解锁时间 (用于统计)

// 解锁后会话状态变为 .completed
// Live Activity 会被结束
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 自动重置检查",
                            description: "应用启动时检查是否需要重置",
                            code: """
// 在 App 启动时调用
manager.checkAndResetEmergencyUnblocks()

// 内部逻辑:
// 1. 读取 lastResetTimestamp
// 2. 计算距今是否超过 resetPeriodInWeeks
// 3. 如果超过，重置次数为 3

// 手动重置 (管理员功能)
manager.resetEmergencyUnblocks()
"""
                        )
                    }
                }
                
                // MARK: - 测试用例
                DemoSectionView(title: "🧪 测试用例", icon: "checkmark.circle") {
                    EmergencyUnlockTestCasesView()
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 改进建议
                DemoSectionView(title: "💡 改进建议", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ImprovementCardView(
                            priority: .high,
                            title: "添加解锁原因记录",
                            description: "每次紧急解锁时要求输入原因，便于后续反思",
                            relatedFiles: ["StrategyManager.swift", "新建 UnlockHistory.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "渐进式惩罚机制",
                            description: "频繁使用紧急解锁会减少下周的解锁次数",
                            relatedFiles: ["StrategyManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "解锁冷却期",
                            description: "紧急解锁后需要等待一段时间才能再次启动屏蔽",
                            relatedFiles: ["StrategyManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "可信联系人解锁",
                            description: "允许设置可信联系人，他们可以帮助解锁",
                            relatedFiles: ["新建 TrustedContacts.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "解锁统计报告",
                            description: "生成解锁使用报告，帮助用户了解自己的习惯",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("紧急解锁机制")
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认紧急解锁", isPresented: $showConfirmation) {
            if requireReasonForUnlock {
                TextField("请输入解锁原因", text: $unlockReason)
            }
            Button("取消", role: .cancel) {
                unlockReason = ""
            }
            Button("确认解锁", role: .destructive) {
                performEmergencyUnlock()
            }
        } message: {
            Text("确定要使用一次紧急解锁吗？\n剩余次数: \(remainingUnlocks) → \(remainingUnlocks - 1)")
        }
        .onAppear {
            initializeState()
            addLog("📱 紧急解锁场景已加载", type: .info)
            addLog("🔍 StrategyManager.checkAndResetEmergencyUnblocks() 已调用", type: .success)
        }
    }
    
    // MARK: - Computed Properties
    
    private var nextResetDateString: String {
        if let date = strategyManager.getNextResetDate() {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
        return "未知"
    }
    
    private var cooldownRemainingTime: String {
        guard let lastUnlock = lastUnlockTime else { return "0:00" }
        let elapsed = Date().timeIntervalSince(lastUnlock)
        let remaining = max(0, TimeInterval(unlockCooldownMinutes * 60) - elapsed)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Private Methods
    
    private func initializeState() {
        remainingUnlocks = strategyManager.getRemainingEmergencyUnblocks()
        strategyManager.checkAndResetEmergencyUnblocks()
    }
    
    private func checkAuthorization() {
        addLog("🔍 检查屏幕时间权限...", type: .info)
        authorizationChecked = true
        
        Task {
            let status = AuthorizationCenter.shared.authorizationStatus
            await MainActor.run {
                isAuthorized = (status == .approved)
                if isAuthorized {
                    addLog("✅ 屏幕时间权限已授权", type: .success)
                    currentStep = .appSelection
                } else {
                    addLog("⚠️ 屏幕时间权限未授权", type: .warning)
                }
            }
        }
    }
    
    private func requestAuthorization() {
        addLog("📝 请求屏幕时间权限...", type: .info)
        
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    isAuthorized = true
                    addLog("✅ 屏幕时间权限请求成功", type: .success)
                    currentStep = .appSelection
                }
            } catch {
                await MainActor.run {
                    addLog("❌ 权限请求失败: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }
    
    private func startStrictModeSession() {
        addLog("🔒 启动严格模式会话", type: .info)
        
        let appBlocker = AppBlockerUtil()
        let snapshot = SharedData.ProfileSnapshot(
            id: UUID(),
            name: "严格模式-紧急解锁测试",
            selectedActivity: selectedActivity,
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "manual",
            strategyData: nil,
            order: 0,
            enableLiveActivity: true,
            reminderTimeInSeconds: nil,
            customReminderMessage: "严格模式进行中",
            enableBreaks: false,
            breakTimeInMinutes: 0,
            enableStrictMode: true,
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
        
        isSessionActive = true
        sessionStartTime = Date()
        elapsedTime = 0
        currentStep = .emergencyUnlock
        addLog("✅ 严格模式会话已启动", type: .success)
        addLog("⚠️ 只能通过紧急解锁结束此会话", type: .warning)
        
        // 启动计时器
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                elapsedTime += 1
            }
        }
    }
    
    private func performEmergencyUnlock() {
        guard remainingUnlocks > 0 else { return }
        
        addLog("🆘 执行紧急解锁", type: .warning)
        
        if requireReasonForUnlock && !unlockReason.isEmpty {
            addLog("📝 解锁原因: \(unlockReason)", type: .info)
            
            // 记录解锁历史
            unlockHistory.insert(UnlockRecord(
                date: Date(),
                reason: unlockReason,
                profileName: "严格模式会话"
            ), at: 0)
        }
        
        addLog("📉 剩余次数: \(remainingUnlocks) → \(remainingUnlocks - 1)", type: .info)
        
        // 停止会话
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        addLog("🔓 AppBlockerUtil.deactivateRestrictions() 已调用", type: .success)
        
        remainingUnlocks -= 1
        isSessionActive = false
        lastUnlockTime = Date()
        currentStep = .analytics
        unlockReason = ""
        
        // 检查冷却
        checkCooldown()
        
        addLog("✅ 紧急解锁成功", type: .success)
        addLog("⏱️ 本次会话时长: \(formatDuration(elapsedTime))", type: .info)
    }
    
    private func resetUnlocks() {
        addLog("🔄 重置解锁次数", type: .info)
        remainingUnlocks = maxUnlocksPerPeriod
        strategyManager.resetEmergencyUnblocks()
        addLog("📊 剩余次数已重置为 \(maxUnlocksPerPeriod)", type: .success)
    }
    
    private func addMockUnlockHistory() {
        let reasons = ["紧急工作电话", "家人急事", "医疗预约确认", "重要通知", "临时任务"]
        let record = UnlockRecord(
            date: Date().addingTimeInterval(-Double.random(in: 0...86400 * 3)),
            reason: reasons.randomElement() ?? "其他",
            profileName: "测试配置"
        )
        unlockHistory.insert(record, at: 0)
        addLog("📝 已添加模拟解锁记录", type: .info)
    }
    
    private func checkCooldown() {
        guard unlockCooldownMinutes > 0, let lastUnlock = lastUnlockTime else {
            isInCooldown = false
            return
        }
        
        let elapsed = Date().timeIntervalSince(lastUnlock)
        isInCooldown = elapsed < TimeInterval(unlockCooldownMinutes * 60)
        
        if isInCooldown {
            addLog("⏳ 冷却期生效，\(unlockCooldownMinutes)分钟后可再次启动严格模式", type: .warning)
        }
    }
    
    private func getUnlockIntensityForHour(_ hour: Int) -> Double {
        // 模拟解锁时段分布 - 上午9-11点高峰
        switch hour {
        case 9, 10, 11: return 0.8
        case 8, 12, 14: return 0.5
        case 15, 16, 17: return 0.4
        case 18, 19, 20: return 0.3
        default: return 0.1
        }
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
    
    private func formatUnlockDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_CN")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天 \(dateFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "昨天 \(dateFormatter.string(from: date))"
        } else {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Unlock History Row
struct UnlockHistoryRow: View {
    let date: String
    let reason: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.shield")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reason)
                    .font(.subheadline)
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Emergency App Selection Section View
struct EmergencyAppSelectionSectionView: View {
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
                        Text("已选择 \(count) 个App")
                            .font(.headline)
                        Text("这些App将在严格模式下被完全屏蔽")
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
                    Text("💡 建议选择")
                        .font(.subheadline.bold())
                    
                    Text("选择容易让你分心或无法控制使用时间的App，如社交媒体、游戏、视频等")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Unlock Stat Card View
struct UnlockStatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Unlock Reason Row
struct UnlockReasonRow: View {
    let reason: String
    let count: Int
    let percentage: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(reason)
                    .font(.caption)
                Spacer()
                Text("\(count)次 (\(percentage)%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 6)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Emergency Toggle Setting Row
struct EmergencyToggleSettingRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Emergency Unlock Test Cases View
struct EmergencyUnlockTestCasesView: View {
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
                        id: "TC-E001",
                        name: "权限请求流程",
                        status: .ready,
                        description: "验证从未授权到授权的完整流程"
                    )
                    TestCaseRowView(
                        id: "TC-E002",
                        name: "App选择功能",
                        status: .ready,
                        description: "验证 FamilyActivityPicker 选择和计数"
                    )
                    TestCaseRowView(
                        id: "TC-E003",
                        name: "严格模式启动",
                        status: .ready,
                        description: "验证启动严格模式会话后正常停止被禁用"
                    )
                    TestCaseRowView(
                        id: "TC-E004",
                        name: "紧急解锁流程",
                        status: .ready,
                        description: "验证紧急解锁消耗次数并成功解除屏蔽"
                    )
                    TestCaseRowView(
                        id: "TC-E005",
                        name: "解锁原因记录",
                        status: .ready,
                        description: "验证解锁时输入原因并保存到历史"
                    )
                    TestCaseRowView(
                        id: "TC-E006",
                        name: "冷却期机制",
                        status: .ready,
                        description: "验证解锁后冷却期内无法再次启动严格模式"
                    )
                    TestCaseRowView(
                        id: "TC-E007",
                        name: "次数重置",
                        status: .ready,
                        description: "验证达到重置周期后自动重置解锁次数"
                    )
                    TestCaseRowView(
                        id: "TC-E008",
                        name: "解锁数据分析",
                        status: .ready,
                        description: "验证解锁统计和时段分布显示正确"
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmergencyUnlockScenarioView()
            .environmentObject(StrategyManager.shared)
    }
}
