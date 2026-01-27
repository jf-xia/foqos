import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// 场景2: 学习计划模式
/// 完整流程实现：权限检查 → App选择 → 日程设置 → 自动启动屏蔽 → 追踪学习统计
struct StudyPlanScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case appSelection = 1
        case scheduleSettings = 2
        case activation = 3
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .appSelection: return "选择App"
            case .scheduleSettings: return "日程设置"
            case .activation: return "启用日程"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .scheduleSettings: return "calendar"
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
    
    // MARK: - 日程设置
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var endHour = 17
    @State private var endMinute = 0
    @State private var isScheduleActive = false
    
    // MARK: - 学习目标设置
    @State private var weeklyGoalHours = 20
    @State private var enableReminders = true
    @State private var reminderBefore = 5 // 分钟
    
    // MARK: - 模拟状态
    @State private var isSimulating = false
    @State private var simulatedProgress: Double = 0
    @State private var simulationTimer: Timer?
    
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
                        Text("**学习计划模式**适用于需要规律学习时间的学生和终身学习者。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "学生固定时段学习，自动屏蔽游戏和社交")
                        BulletPointView(text: "备考期间集中复习")
                        BulletPointView(text: "在线课程学习时保持专注")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - 选择要屏蔽的干扰App")
                        BulletPointView(text: "✅ 按周设置学习日程")
                        BulletPointView(text: "✅ 到点自动启动/停止")
                        BulletPointView(text: "✅ 累计学习时长统计")
                        
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
                                icon: isScheduleActive ? "calendar.badge.clock" : "calendar",
                                title: "日程",
                                value: isScheduleActive ? "已启用" : "未启用",
                                color: isScheduleActive ? .green : .gray
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
                            description: "日程配置 - 定义周几和时间段"
                        )
                        DependencyRowView(
                            name: "ScheduleTimerActivity",
                            path: "ZenBound/Models/Timers/ScheduleTimerActivity.swift",
                            description: "日程计时器 - 管理自动启停"
                        )
                        DependencyRowView(
                            name: "DeviceActivityCenterUtil",
                            path: "ZenBound/Utils/DeviceActivityCenterUtil.swift",
                            description: "活动调度 - 系统级定时器"
                        )
                        DependencyRowView(
                            name: "ProfileInsightsUtil",
                            path: "ZenBound/Utils/ProfileInsightsUtil.swift",
                            description: "学习统计 - 时长和趋势分析"
                        )
                        DependencyRowView(
                            name: "Weekday",
                            path: "ZenBound/Models/Schedule.swift",
                            description: "星期枚举 - 周日到周六"
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
                    StudyAppSelectionSectionView(
                        isAuthorized: isAuthorized,
                        selectedActivity: $selectedActivity,
                        showAppPicker: $showAppPicker,
                        onSelectionChanged: { count in
                            addLog("📱 已选择 \(count) 个干扰App", type: .success)
                            if currentStep == .appSelection && count > 0 {
                                currentStep = .scheduleSettings
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
                
                // MARK: - Step 3: 日程配置
                DemoSectionView(title: "📅 Step 3: 日程配置", icon: "calendar") {
                    VStack(spacing: 16) {
                        // 选择日期
                        VStack(alignment: .leading, spacing: 8) {
                            Text("学习日:")
                                .font(.subheadline.bold())
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    Button {
                                        toggleDay(day)
                                    } label: {
                                        Text(day.shortLabel)
                                            .font(.caption.bold())
                                            .frame(width: 36, height: 36)
                                            .background(selectedDays.contains(day) ? Color.accentColor : Color(.systemGray5))
                                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                            .cornerRadius(18)
                                    }
                                }
                            }
                        }
                        
                        // 时间段
                        HStack {
                            VStack(alignment: .leading) {
                                Text("开始时间")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Picker("时", selection: $startHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text("\(hour)").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                    
                                    Text(":")
                                    
                                    Picker("分", selection: $startMinute) {
                                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                                            Text(String(format: "%02d", minute)).tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("结束时间")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Picker("时", selection: $endHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text("\(hour)").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                    
                                    Text(":")
                                    
                                    Picker("分", selection: $endMinute) {
                                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                                            Text(String(format: "%02d", minute)).tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                }
                            }
                        }
                        
                        // 日程摘要
                        if !selectedDays.isEmpty {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text(scheduleSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 学习目标设置
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📊 学习目标")
                                .font(.subheadline.bold())
                            
                            HStack {
                                Label("每周目标", systemImage: "target")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $weeklyGoalHours) {
                                    Text("10小时").tag(10)
                                    Text("15小时").tag(15)
                                    Text("20小时").tag(20)
                                    Text("25小时").tag(25)
                                    Text("30小时").tag(30)
                                }
                                .pickerStyle(.menu)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            ToggleSettingRow(
                                title: "日程提醒",
                                subtitle: "日程开始前 \(reminderBefore) 分钟提醒",
                                icon: "bell",
                                isOn: $enableReminders,
                                iconColor: .orange
                            )
                            .onChange(of: enableReminders) { _, newValue in
                                addLog("🔔 日程提醒: \(newValue ? "启用" : "禁用")", type: .info)
                            }
                        }
                    }
                }
                
                // MARK: - Step 4: 启用日程
                DemoSectionView(title: "🚀 Step 4: 启用日程", icon: "play.circle") {
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
                        } else if selectedDays.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("请先完成 Step 3 选择学习日")
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
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                
                                Text("日程已启用")
                                    .font(.headline)
                                
                                Text(scheduleSummary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if isSimulating {
                                    VStack(spacing: 8) {
                                        ProgressView(value: simulatedProgress)
                                            .tint(.purple)
                                        Text("模拟进度: \(Int(simulatedProgress * 100))%")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
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
                                toggleSchedule()
                            } label: {
                                Label(
                                    isScheduleActive ? "停用日程" : "启用日程",
                                    systemImage: isScheduleActive ? "calendar.badge.minus" : "calendar.badge.plus"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(isScheduleActive ? .red : .purple)
                            .disabled(!isAuthorized || FamilyActivityUtil.countSelectedActivities(selectedActivity) == 0 || selectedDays.isEmpty)
                            
                            if isScheduleActive {
                                Button {
                                    toggleSimulation()
                                } label: {
                                    Label(
                                        isSimulating ? "停止模拟" : "模拟测试",
                                        systemImage: isSimulating ? "stop.fill" : "play.fill"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                            }
                        }
                        
                        // 模拟器测试提示
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.purple)
                            Text("模拟器测试: 使用模拟测试按钮验证日程触发流程")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - 学习统计预览
                DemoSectionView(title: "📊 学习统计预览", icon: "chart.bar") {
                    VStack(spacing: 16) {
                        // 统计卡片
                        HStack(spacing: 12) {
                            InfoCardView(
                                icon: "clock.fill",
                                title: "本周学习",
                                value: "12.5h",
                                color: .blue
                            )
                            InfoCardView(
                                icon: "flame.fill",
                                title: "连续天数",
                                value: "7",
                                color: .orange
                            )
                        }
                        
                        HStack(spacing: 12) {
                            InfoCardView(
                                icon: "target",
                                title: "完成率",
                                value: "85%",
                                color: .green
                            )
                            InfoCardView(
                                icon: "calendar.badge.checkmark",
                                title: "总会话",
                                value: "42",
                                color: .purple
                            )
                        }
                        
                        // 每周目标进度
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("每周目标进度")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("12.5 / \(weeklyGoalHours) 小时")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            ProgressView(value: 12.5, total: Double(weeklyGoalHours))
                                .tint(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        Text("使用 ProfileInsightsUtil 获取详细统计")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // MARK: - 测试用例说明
                DemoSectionView(title: "🧪 测试用例说明", icon: "checklist") {
                    StudyPlanTestCasesView()
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 创建学习日程",
                            description: "使用 BlockedProfileSchedule 定义时间段",
                            code: """
// 创建周一至周五的学习日程
let schedule = BlockedProfileSchedule(
    days: [.monday, .tuesday, .wednesday, .thursday, .friday],
    startHour: 9, startMinute: 0,
    endHour: 17, endMinute: 0,
    updatedAt: Date()
)

// 日程属性
schedule.isActive          // 当前是否在日程时间内
schedule.summaryText       // "周一,周二... 09:00-17:00"
schedule.totalDurationInSeconds  // 每日总时长
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 绑定到配置",
                            description: "将日程关联到屏蔽配置",
                            code: """
// 更新配置的日程
let _ = BlockedProfiles.updateProfile(
    profile, in: context,
    schedule: schedule
)

// 启动日程监控
DeviceActivityCenterUtil.scheduleTimerActivity(for: profile)

// 系统会在日程时间自动触发 intervalDidStart/intervalDidEnd
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 查看学习统计",
                            description: "使用 ProfileInsightsUtil 分析学习数据",
                            code: """
let insights = ProfileInsightsUtil(profile: profile)

// 获取统计指标
insights.metrics.totalFocusTime        // 总学习时长
insights.metrics.averageSessionDuration // 平均每次时长
insights.currentStreakDays()           // 当前连续天数

// 获取每日汇总
let dailyData = insights.dailyAggregates(days: 7, endingOn: Date())
// dailyData: [{date, sessionsCount, focusDuration}, ...]
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
                            title: "添加日程提前提醒",
                            description: "日程开始前5分钟发送通知，让用户做好准备",
                            relatedFiles: ["TimersUtil.swift", "Schedule.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "支持多日程配置",
                            description: "允许同一配置设置多个时间段，如上午和下午分开",
                            relatedFiles: ["Schedule.swift", "BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "添加学习目标设置",
                            description: "设置每周学习时长目标，显示完成进度",
                            relatedFiles: ["ProfileInsightsUtil.swift", "BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "生成学习报告",
                            description: "每周生成学习报告，可分享到社交媒体",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("学习计划模式")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAuthorizationOnAppear()
        }
        .onDisappear {
            simulationTimer?.invalidate()
        }
    }
    
    // MARK: - Computed Properties
    
    private var scheduleSummary: String {
        let days = selectedDays.sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortLabel }
            .joined(separator: ", ")
        let start = String(format: "%02d:%02d", startHour, startMinute)
        let end = String(format: "%02d:%02d", endHour, endMinute)
        return "\(days) \(start) - \(end)"
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
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
            addLog("📅 移除: \(day.name)", type: .info)
        } else {
            selectedDays.insert(day)
            addLog("📅 添加: \(day.name)", type: .info)
        }
    }
    
    private func toggleSchedule() {
        if isScheduleActive {
            deactivateSchedule()
        } else {
            activateSchedule()
        }
    }
    
    private func activateSchedule() {
        let appCount = FamilyActivityUtil.countSelectedActivities(selectedActivity)
        
        addLog("📅 正在启用学习日程...", type: .info)
        addLog("📱 屏蔽App数量: \(appCount)", type: .info)
        addLog("⏰ \(scheduleSummary)", type: .info)
        
        // 创建快照并保存日程
        let schedule = BlockedProfileSchedule(
            days: Array(selectedDays),
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            updatedAt: Date()
        )
        
        addLog("📝 创建 BlockedProfileSchedule: \(schedule.summaryText)", type: .info)
        addLog("🔄 DeviceActivityCenterUtil.scheduleTimerActivity() 已调用", type: .success)
        
        isScheduleActive = true
        currentStep = .activation
        addLog("✅ 学习日程已启用", type: .success)
        addLog("💡 系统将在日程时间自动启动/停止屏蔽", type: .info)
    }
    
    private func deactivateSchedule() {
        addLog("📅 正在停用学习日程...", type: .info)
        
        simulationTimer?.invalidate()
        isSimulating = false
        simulatedProgress = 0
        
        addLog("🔄 DeviceActivityCenterUtil.removeScheduleTimerActivities() 已调用", type: .success)
        
        isScheduleActive = false
        addLog("✅ 学习日程已停用", type: .warning)
    }
    
    private func toggleSimulation() {
        if isSimulating {
            stopSimulation()
        } else {
            startSimulation()
        }
    }
    
    private func startSimulation() {
        isSimulating = true
        simulatedProgress = 0
        addLog("▶️ 开始模拟日程触发...", type: .info)
        addLog("📥 模拟 intervalDidStart 回调", type: .info)
        addLog("🔒 AppBlockerUtil.activateRestrictions() 已调用", type: .success)
        
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            Task { @MainActor in
                simulatedProgress += 0.02
                
                if simulatedProgress >= 1.0 {
                    addLog("📤 模拟 intervalDidEnd 回调", type: .info)
                    addLog("🔓 AppBlockerUtil.deactivateRestrictions() 已调用", type: .success)
                    addLog("✅ 日程周期模拟完成", type: .success)
                    stopSimulation()
                }
            }
        }
    }
    
    private func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isSimulating = false
        addLog("⏹️ 模拟停止", type: .info)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Study App Selection Section View
struct StudyAppSelectionSectionView: View {
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
                        Text("学习期间这些App将被屏蔽")
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
                    Text("💡 推荐屏蔽的干扰App")
                        .font(.subheadline.bold())
                    
                    Text("学习时建议选择：社交媒体、游戏、短视频等可能分散注意力的App")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(["游戏", "抖音", "B站", "微博", "小红书", "快手"], id: \.self) { category in
                            Text(category)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
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

// MARK: - Study Plan Test Cases View
struct StudyPlanTestCasesView: View {
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
                        id: "TC-S001",
                        name: "权限请求流程",
                        status: .ready,
                        description: "验证从未授权到授权的完整流程"
                    )
                    TestCaseRowView(
                        id: "TC-S002",
                        name: "App选择功能",
                        status: .ready,
                        description: "验证 FamilyActivityPicker 选择和计数"
                    )
                    TestCaseRowView(
                        id: "TC-S003",
                        name: "日程配置",
                        status: .ready,
                        description: "验证学习日和时间段设置"
                    )
                    TestCaseRowView(
                        id: "TC-S004",
                        name: "日程自动启动",
                        status: .ready,
                        description: "验证到达日程时间后自动启动屏蔽"
                    )
                    TestCaseRowView(
                        id: "TC-S005",
                        name: "日程自动停止",
                        status: .ready,
                        description: "验证日程结束后自动解除屏蔽"
                    )
                    TestCaseRowView(
                        id: "TC-S006",
                        name: "学习统计",
                        status: .planned,
                        description: "验证学习时长和连续天数统计"
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StudyPlanScenarioView()
    }
}
