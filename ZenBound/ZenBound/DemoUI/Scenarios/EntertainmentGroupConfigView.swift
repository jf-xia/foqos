import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

/// 场景: 娱乐组配置页面 (Entertainment Group)
/// 完整流程实现：权限检查 → App选择 → 每小时15分钟限制 → 激活屏蔽 → 日志追踪
struct EntertainmentGroupConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case appSelection = 1
        case timeSettings = 2
        case activation = 3
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .appSelection: return "选择App"
            case .timeSettings: return "时间设置"
            case .activation: return "激活配置"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .appSelection: return "apps.iphone"
            case .timeSettings: return "clock"
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
    @State private var entertainmentCategories: Set<String> = ["Games", "Social", "Entertainment"]
    
    // MARK: - 假期选择
    @State private var enableWeekends = true              // 周末生效
    @State private var selectedHolidays: [Date] = []      // 选择的假期
    @State private var selectedCustomDates: [Date] = []   // 自定义日期
    @State private var showHolidayPicker = false
    @State private var showCustomDatePicker = false
    @State private var tempSelectedDate = Date()
    
    // MARK: - 娱乐限制设置 (默认每小时15分钟)
    @State private var hourlyTimeLimit = 15               // 每小时可用时长（分钟）- 默认15分钟
    @State private var dailyTimeLimit = 120               // 每日总时长（分钟）
    @State private var singleSessionLimit = 15            // 单次时长（分钟）- 默认与每小时限制匹配
    @State private var enableHourlyLimit = true           // 启用每小时限制
    
    // 延长使用设置
    @State private var enableExtension = true             // 允许延长使用
    @State private var extensionCount = 2                 // 延长次数
    @State private var extensionMinutes = 5               // 每次延长时间（改为5分钟）
    
    // 休息强制设置
    @State private var enableRestBlock = true             // 启用休息强制
    @State private var blockAllAppsWhenRest = false       // 休息时屏蔽所有App
    @State private var restDurationMinutes = 45           // 强制休息时长（分钟）- 每小时剩余45分钟
    @State private var restReminderMessage = "Time to take a break!"
    
    private let restMessages = [
        "Time to take a break!",
        "How about some fresh air?",
        "Let's do something fun outside!",
        "Your eyes need a rest!"
    ]
    
    // 活动任务设置
    @State private var enableActivityTasks = false        // 启用活动任务
    @State private var selectedTasks: Set<String> = []    // 选择的任务
    @State private var extraTimePerTask = 5               // 每个任务额外时间（改为5分钟）
    
    // MARK: - Shield 设置
    @State private var shieldMessage = "Enjoy your time!"
    @State private var shieldColor: Color = .green
    @State private var shieldButtonAction = "extend5" // extend5 / openTask
    
    private let shieldMessages = [
        "Enjoy your time!",
        "Remember to take breaks!",
        "Balance is key!",
        "Having fun? Don't forget to rest!"
    ]
    
    // MARK: - 测试与模拟
    @State private var isSimulatingUsage = false
    @State private var simulatedUsageMinutes = 0
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
                        Text("**娱乐组配置**实现完整的屏幕时间管理流程：")
                        
                        Text("**核心功能：**")
                        BulletPointView(text: "✅ 权限检查 - Screen Time 授权")
                        BulletPointView(text: "✅ App选择 - FamilyActivityPicker 集成")
                        BulletPointView(text: "✅ 每小时15分钟默认限制")
                        BulletPointView(text: "✅ 周末/假期专属娱乐时间配额")
                        BulletPointView(text: "✅ 单次使用后强制休息")
                        BulletPointView(text: "✅ 完整日志追踪和测试")
                        
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
                                title: "已选App",
                                value: "\(FamilyActivityUtil.countSelectedActivities(selectedActivity))个",
                                color: .blue
                            )
                            
                            StatusCardView(
                                icon: "clock.fill",
                                title: "每小时",
                                value: "\(hourlyTimeLimit)分钟",
                                color: .orange
                            )
                        }
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
                
                // MARK: - Step 2: App选择
                DemoSectionView(title: "📱 Step 2: 选择娱乐App", icon: "apps.iphone") {
                    AppSelectionSectionView(
                        isAuthorized: isAuthorized,
                        selectedActivity: $selectedActivity,
                        showAppPicker: $showAppPicker,
                        entertainmentCategories: entertainmentCategories,
                        onSelectionChanged: { count in
                            addLog("📱 已选择 \(count) 个App/类别", type: .success)
                            if currentStep == .appSelection && count > 0 {
                                currentStep = .timeSettings
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
                
                // MARK: - Step 3: 每小时15分钟限制设置
                DemoSectionView(title: "⏱️ Step 3: 每小时15分钟限制", icon: "clock") {
                    HourlyLimitSectionView(
                        enableHourlyLimit: $enableHourlyLimit,
                        hourlyTimeLimit: $hourlyTimeLimit,
                        restDurationMinutes: $restDurationMinutes,
                        dailyTimeLimit: $dailyTimeLimit,
                        singleSessionLimit: $singleSessionLimit,
                        onSettingsChanged: { setting, value in
                            addLog("⏱️ \(setting): \(value)", type: .info)
                        }
                    )
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "BlockedProfiles",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "配置存储 - 时间限制、休息设置等"
                        )
                        DependencyRowView(
                            name: "BreakTimerActivity",
                            path: "ZenBound/Models/Timers/BreakTimerActivity.swift",
                            description: "休息计时 - 强制休息管理"
                        )
                        DependencyRowView(
                            name: "StrategyManager",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "会话管理 - 延长时间处理"
                        )
                        DependencyRowView(
                            name: "Schedule",
                            path: "ZenBound/Models/Schedule.swift",
                            description: "日期调度 - 周末/假期检测"
                        )
                        DependencyRowView(
                            name: "ShieldConfigurationExtension",
                            path: "shieldConfig/ShieldConfigurationExtension.swift",
                            description: "Shield配置 - 延长按钮实现"
                        )
                        DependencyRowView(
                            name: "TimersUtil",
                            path: "ZenBound/Utils/TimersUtil.swift",
                            description: "通知调度 - 休息提醒"
                        )
                    }
                }
                
                // MARK: - 假期选择
                DemoSectionView(title: "📅 假期选择", icon: "calendar") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "周末生效",
                            subtitle: "周六和周日自动应用此配置",
                            icon: "sun.max",
                            isOn: $enableWeekends,
                            iconColor: .orange
                        )
                        .onChange(of: enableWeekends) { _, newValue in
                            addLog("🗓️ 周末生效: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        // 假期选择
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("选择假期", systemImage: "gift")
                                    .font(.subheadline)
                                Spacer()
                                Button {
                                    showHolidayPicker = true
                                } label: {
                                    Label("添加", systemImage: "plus.circle")
                                        .font(.caption)
                                }
                            }
                            
                            if !selectedHolidays.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(selectedHolidays, id: \.self) { date in
                                        HStack(spacing: 4) {
                                            Text(formatDate(date))
                                                .font(.caption)
                                            Button {
                                                selectedHolidays.removeAll { $0 == date }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            } else {
                                Text("未选择假期")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        // 自定义日期
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("自定义日期", systemImage: "calendar.badge.plus")
                                    .font(.subheadline)
                                Spacer()
                                Button {
                                    showCustomDatePicker = true
                                } label: {
                                    Label("添加", systemImage: "plus.circle")
                                        .font(.caption)
                                }
                            }
                            
                            if !selectedCustomDates.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(selectedCustomDates, id: \.self) { date in
                                        HStack(spacing: 4) {
                                            Text(formatDate(date))
                                                .font(.caption)
                                            Button {
                                                selectedCustomDates.removeAll { $0 == date }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            } else {
                                Text("未添加自定义日期")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .sheet(isPresented: $showHolidayPicker) {
                    DatePickerSheet(
                        title: "选择假期",
                        selectedDate: $tempSelectedDate,
                        onConfirm: {
                            if !selectedHolidays.contains(tempSelectedDate) {
                                selectedHolidays.append(tempSelectedDate)
                                addLog("🎉 添加假期: \(formatDate(tempSelectedDate))", type: .success)
                            }
                        }
                    )
                }
                .sheet(isPresented: $showCustomDatePicker) {
                    DatePickerSheet(
                        title: "选择自定义日期",
                        selectedDate: $tempSelectedDate,
                        onConfirm: {
                            if !selectedCustomDates.contains(tempSelectedDate) {
                                selectedCustomDates.append(tempSelectedDate)
                                addLog("📅 添加自定义日期: \(formatDate(tempSelectedDate))", type: .success)
                            }
                        }
                    )
                }
                
                // MARK: - 娱乐限制设置
                DemoSectionView(title: "🎮 娱乐限制设置", icon: "gamecontroller") {
                    VStack(spacing: 12) {
                        DurationPickerView(
                            title: "每日总时长限制",
                            icon: "hourglass",
                            selectedMinutes: $dailyTimeLimit,
                            options: [60, 90, 120, 180, 240, 300]
                        )
                        .onChange(of: dailyTimeLimit) { _, newValue in
                            addLog("⏱️ 每日时长限制设置为 \(newValue) 分钟", type: .info)
                        }
                        
                        DurationPickerView(
                            title: "单次使用时长限制",
                            icon: "timer",
                            selectedMinutes: $singleSessionLimit,
                            options: [10, 15, 30, 45, 60]
                        )
                        .onChange(of: singleSessionLimit) { _, newValue in
                            addLog("⏱️ 单次时长限制设置为 \(newValue) 分钟", type: .info)
                        }
                        
                        // 时间配额展示
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                Text("\(dailyTimeLimit / 60)小时\(dailyTimeLimit % 60)分")
                                    .font(.headline)
                                Text("每日配额")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("\(dailyTimeLimit / singleSessionLimit)次")
                                    .font(.headline)
                                Text("可用次数")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // MARK: - 延长使用设置
                DemoSectionView(title: "⏰ 延长使用设置", icon: "plus.circle") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "允许延长使用时间",
                            subtitle: "在Shield上点击延长使用按钮",
                            icon: "clock.arrow.2.circlepath",
                            isOn: $enableExtension,
                            iconColor: .purple
                        )
                        .onChange(of: enableExtension) { _, newValue in
                            addLog("⏰ 延长使用: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        if enableExtension {
                            VStack(spacing: 12) {
                                CountPickerView(
                                    title: "延长次数限制",
                                    icon: "number",
                                    selectedCount: $extensionCount,
                                    options: [1, 2, 3, 5],
                                    suffix: "次/天"
                                )
                                .onChange(of: extensionCount) { _, newValue in
                                    addLog("🔢 延长次数设置为 \(newValue) 次/天", type: .info)
                                }
                                
                                DurationPickerView(
                                    title: "每次延长时间",
                                    icon: "timer",
                                    selectedMinutes: $extensionMinutes,
                                    options: [5, 10, 15, 20, 30]
                                )
                                .onChange(of: extensionMinutes) { _, newValue in
                                    addLog("⏱️ 每次延长 \(newValue) 分钟", type: .info)
                                }
                                
                                // 延长时间摘要
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.purple)
                                    Text("每天最多可额外获得 \(extensionCount * extensionMinutes) 分钟")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut, value: enableExtension)
                }
                
                // MARK: - 休息强制设置
                DemoSectionView(title: "😌 休息强制设置", icon: "figure.walk") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "单次使用后强制休息",
                            subtitle: "达到单次时长后必须休息",
                            icon: "pause.circle",
                            isOn: $enableRestBlock,
                            iconColor: .teal
                        )
                        .onChange(of: enableRestBlock) { _, newValue in
                            addLog("😌 强制休息: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        if enableRestBlock {
                            VStack(spacing: 12) {
                                ToggleSettingRow(
                                    title: "休息时屏蔽所有App",
                                    subtitle: "休息期间完全禁止使用手机",
                                    icon: "iphone.slash",
                                    isOn: $blockAllAppsWhenRest
                                )
                                .onChange(of: blockAllAppsWhenRest) { _, newValue in
                                    addLog("📱 休息时屏蔽所有App: \(newValue ? "开启" : "关闭")", type: .info)
                                }
                                
                                DurationPickerView(
                                    title: "强制休息时长",
                                    icon: "bell.badge",
                                    selectedMinutes: $restDurationMinutes,
                                    options: [30, 45, 50, 55]
                                )
                                .onChange(of: restDurationMinutes) { _, newValue in
                                    addLog("😌 强制休息时长设置为 \(newValue) 分钟", type: .info)
                                }
                                
                                // 休息提醒消息
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("休息提醒消息")
                                        .font(.subheadline.bold())
                                    
                                    ForEach(restMessages, id: \.self) { message in
                                        Button {
                                            restReminderMessage = message
                                        } label: {
                                            HStack {
                                                Text(message)
                                                    .foregroundColor(.primary)
                                                    .font(.caption)
                                                Spacer()
                                                if restReminderMessage == message {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                }
                                            }
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut, value: enableRestBlock)
                }
                
                // MARK: - 活动任务设置
                DemoSectionView(title: "🎯 活动任务", icon: "checkmark.seal") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "启用活动任务",
                            subtitle: "完成任务获取额外娱乐时间",
                            icon: "star.fill",
                            isOn: $enableActivityTasks,
                            iconColor: .yellow
                        )
                        .onChange(of: enableActivityTasks) { _, newValue in
                            addLog("🎯 活动任务: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        if enableActivityTasks {
                            VStack(spacing: 12) {
                                Text("选择可用任务")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TaskSelectionView(selectedTasks: $selectedTasks)
                                
                                DurationPickerView(
                                    title: "每个任务额外时间",
                                    icon: "gift",
                                    selectedMinutes: $extraTimePerTask,
                                    options: [5, 10, 15, 20]
                                )
                                .onChange(of: extraTimePerTask) { _, newValue in
                                    addLog("🎁 每个任务奖励 \(newValue) 分钟", type: .info)
                                }
                                
                                if !selectedTasks.isEmpty {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.yellow)
                                        Text("完成 \(selectedTasks.count) 个任务可获得 \(selectedTasks.count * extraTimePerTask) 分钟额外时间")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut, value: enableActivityTasks)
                }
                
                // MARK: - Shield 设置
                DemoSectionView(title: "🛡️ Shield 设置", icon: "shield.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("**Shield 按钮动作**")
                            .font(.subheadline)
                        
                        VStack(spacing: 8) {
                            Button {
                                shieldButtonAction = "extend10"
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("再玩 \(extensionMinutes) 分钟")
                                            .foregroundColor(.primary)
                                        Text("获取额外使用时间（消耗延长次数）")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if shieldButtonAction == "extend10" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(shieldButtonAction == "extend10" ? Color.green.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            Button {
                                shieldButtonAction = "openTask"
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.seal")
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("打开 ZenBound 任务")
                                            .foregroundColor(.primary)
                                        Text("完成任务转移注意力/获取额外时间")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if shieldButtonAction == "openTask" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(shieldButtonAction == "openTask" ? Color.yellow.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                        
                        ShieldThemeSettingsView(
                            selectedMessage: $shieldMessage,
                            selectedColor: $shieldColor,
                            defaultMessages: shieldMessages
                        )
                    }
                }
                
                // MARK: - Step 4: 激活与测试
                DemoSectionView(title: "🚀 Step 4: 激活与测试", icon: "play.circle") {
                    ActivationTestSectionView(
                        isConfigurationActive: $isConfigurationActive,
                        isAuthorized: isAuthorized,
                        selectedActivityCount: FamilyActivityUtil.countSelectedActivities(selectedActivity),
                        hourlyTimeLimit: hourlyTimeLimit,
                        isSimulatingUsage: $isSimulatingUsage,
                        simulatedUsageMinutes: $simulatedUsageMinutes,
                        onActivate: activateConfiguration,
                        onDeactivate: deactivateConfiguration,
                        onStartSimulation: startUsageSimulation,
                        onStopSimulation: stopUsageSimulation,
                        addLog: addLog
                    )
                }
                
                // MARK: - 测试用例说明
                DemoSectionView(title: "🧪 测试用例说明", icon: "checklist") {
                    TestCasesDocumentationView()
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 操作按钮
                ActionButtonsView(
                    onSave: saveConfiguration,
                    onCancel: { dismiss() },
                    saveColor: .green
                )
            }
            .padding()
        }
        .navigationTitle("娱乐组配置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 初始化时检查权限状态
            checkAuthorizationOnAppear()
        }
        .onDisappear {
            // 清理模拟器定时器
            stopUsageSimulation()
        }
    }
    
    // MARK: - Private Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    /// 页面出现时检查权限
    private func checkAuthorizationOnAppear() {
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = (status == .approved)
        authorizationChecked = true
        addLog("🔍 初始化权限检查: \(status == .approved ? "已授权" : "未授权")", type: .info)
    }
    
    /// 检查授权状态
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
    
    /// 请求授权
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
    
    /// 激活配置
    private func activateConfiguration() {
        guard isAuthorized else {
            addLog("❌ 无法激活：未获得屏幕时间授权", type: .error)
            return
        }
        
        let appCount = FamilyActivityUtil.countSelectedActivities(selectedActivity)
        guard appCount > 0 else {
            addLog("❌ 无法激活：未选择任何App", type: .error)
            return
        }
        
        addLog("🚀 正在激活娱乐组配置...", type: .info)
        addLog("📱 屏蔽App数量: \(appCount)", type: .info)
        addLog("⏱️ 每小时限制: \(hourlyTimeLimit)分钟", type: .info)
        addLog("😌 强制休息: \(restDurationMinutes)分钟/小时", type: .info)
        
        // 1. 保存配置到 SharedData，供 Extension 访问
        let entertainmentConfig = SharedData.EntertainmentConfig(
            isActive: true,
            selectedActivity: selectedActivity,
            hourlyLimitMinutes: hourlyTimeLimit,
            dailyLimitMinutes: dailyTimeLimit,
            restDurationMinutes: restDurationMinutes,
            enableHourlyLimit: enableHourlyLimit,
            currentHourUsageMinutes: 0,
            lastResetHour: Calendar.current.component(.hour, from: Date()),
            todayTotalUsageMinutes: 0,
            lastResetDate: Date(),
            shieldMessage: shieldMessage,
            enableWeekends: enableWeekends
        )
        SharedData.entertainmentConfig = entertainmentConfig
        addLog("💾 配置已保存到 App Group", type: .info)
        
        // 2. 启动 DeviceActivityCenter 监控（带阈值事件）
        if enableHourlyLimit {
            DeviceActivityCenterUtil.startEntertainmentHourlyMonitoring(
                selection: selectedActivity,
                hourlyLimitMinutes: hourlyTimeLimit
            )
            addLog("📡 每小时 \(hourlyTimeLimit) 分钟限制监控已启动", type: .success)
            addLog("   - 已创建 24 个独立的小时监控区间", type: .info)
            addLog("   - 每个小时开始时自动重置使用时间", type: .info)
            addLog("   - 当使用达到 \(hourlyTimeLimit) 分钟时将触发 Shield", type: .info)
            if hourlyTimeLimit > 5 {
                addLog("   - 警告将在剩余 5 分钟时显示", type: .info)
            }
        }
        
        addLog("📊 配置摘要:", type: .info)
        addLog("   - Apps: \(selectedActivity.applicationTokens.count)", type: .info)
        addLog("   - Categories: \(selectedActivity.categoryTokens.count)", type: .info)
        addLog("   - Websites: \(selectedActivity.webDomainTokens.count)", type: .info)
        
        isConfigurationActive = true
        currentStep = .activation
        addLog("✅ 娱乐组配置激活成功！", type: .success)
        addLog("💡 提示: 使用选定的娱乐App累计 \(hourlyTimeLimit) 分钟后将被屏蔽", type: .info)
    }
    
    /// 停用配置
    private func deactivateConfiguration() {
        addLog("🛑 正在停用娱乐组配置...", type: .info)
        
        // 1. 停止 DeviceActivityCenter 监控
        DeviceActivityCenterUtil.stopEntertainmentMonitoring()
        addLog("📡 监控已停止", type: .info)
        
        // 2. 清除 SharedData 中的配置
        if var config = SharedData.entertainmentConfig {
            config.isActive = false
            SharedData.entertainmentConfig = config
        }
        addLog("💾 配置状态已更新", type: .info)
        
        // 3. 清除任何现有的屏蔽
        let appBlocker = AppBlockerUtil()
        appBlocker.deactivateRestrictions()
        
        isConfigurationActive = false
        stopUsageSimulation()
        addLog("✅ 娱乐组配置已停用", type: .success)
    }
    
    /// 开始使用时间模拟
    private func startUsageSimulation() {
        guard isConfigurationActive else {
            addLog("❌ 请先激活配置", type: .error)
            return
        }
        
        isSimulatingUsage = true
        simulatedUsageMinutes = 0
        addLog("▶️ 开始模拟使用时间...", type: .info)
        
        // 每秒增加1分钟（加速模拟）
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                simulatedUsageMinutes += 1
                
                // 检查是否达到每小时限制
                if simulatedUsageMinutes >= hourlyTimeLimit {
                    addLog("⏰ 已达到每小时\(hourlyTimeLimit)分钟限制！", type: .warning)
                    addLog("🔒 触发强制休息 \(restDurationMinutes) 分钟", type: .info)
                    stopUsageSimulation()
                    
                    // 模拟Shield显示
                    addLog("🛡️ Shield已显示: \"\(shieldMessage)\"", type: .info)
                } else if simulatedUsageMinutes == hourlyTimeLimit - 5 {
                    addLog("⚠️ 剩余5分钟，即将达到限制", type: .warning)
                } else if simulatedUsageMinutes == hourlyTimeLimit - 1 {
                    addLog("⚠️ 剩余1分钟！", type: .warning)
                }
            }
        }
    }
    
    /// 停止使用时间模拟
    private func stopUsageSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isSimulatingUsage = false
        if simulatedUsageMinutes > 0 {
            addLog("⏹️ 模拟停止，已使用 \(simulatedUsageMinutes) 分钟", type: .info)
        }
    }
    
    private func saveConfiguration() {
        addLog("💾 正在保存娱乐组配置...", type: .info)
        addLog("🔐 权限状态: \(isAuthorized ? "已授权" : "未授权")", type: isAuthorized ? .success : .warning)
        addLog("📱 已选App: \(FamilyActivityUtil.countSelectedActivities(selectedActivity))个", type: .success)
        addLog("⏱️ 每小时限制: \(hourlyTimeLimit)分钟", type: .success)
        addLog("📅 周末生效: \(enableWeekends ? "是" : "否")", type: .success)
        addLog("⏱️ 每日时长: \(dailyTimeLimit)分钟", type: .success)
        addLog("⏱️ 单次时长: \(singleSessionLimit)分钟", type: .success)
        addLog("⏰ 延长设置: \(enableExtension ? "\(extensionCount)次×\(extensionMinutes)分钟" : "禁用")", type: .success)
        addLog("😌 强制休息: \(enableRestBlock ? "\(restDurationMinutes)分钟/小时" : "关闭")", type: .success)
        addLog("🎯 活动任务: \(enableActivityTasks ? "\(selectedTasks.count)个任务" : "禁用")", type: .success)
        addLog("✅ 配置保存成功!", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - App Selection Section
struct AppSelectionSectionView: View {
    let isAuthorized: Bool
    @Binding var selectedActivity: FamilyActivitySelection
    @Binding var showAppPicker: Bool
    let entertainmentCategories: Set<String>
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
                // 已选择的App统计
                let count = FamilyActivityUtil.countSelectedActivities(selectedActivity)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已选择 \(count) 个项目")
                            .font(.headline)
                        Text("包含 \(selectedActivity.applicationTokens.count) 个App, \(selectedActivity.categoryTokens.count) 个类别")
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
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 预设娱乐类别提示
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 推荐选择娱乐类App")
                        .font(.subheadline.bold())
                    
                    Text("建议选择：游戏、社交媒体、视频、娱乐等类别的App进行限制")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(Array(entertainmentCategories), id: \.self) { category in
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

// MARK: - Hourly Limit Section
struct HourlyLimitSectionView: View {
    @Binding var enableHourlyLimit: Bool
    @Binding var hourlyTimeLimit: Int
    @Binding var restDurationMinutes: Int
    @Binding var dailyTimeLimit: Int
    @Binding var singleSessionLimit: Int
    let onSettingsChanged: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 每小时限制开关
            ToggleSettingRow(
                title: "启用每小时限制",
                subtitle: "每小时内App使用不超过设定时间",
                icon: "clock.badge.checkmark",
                isOn: $enableHourlyLimit,
                iconColor: .orange
            )
            .onChange(of: enableHourlyLimit) { _, newValue in
                onSettingsChanged("每小时限制", newValue ? "开启" : "关闭")
            }
            
            if enableHourlyLimit {
                // 每小时可用时长
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("每小时可用时长", systemImage: "timer")
                            .font(.subheadline)
                        Spacer()
                        
                        Picker("", selection: $hourlyTimeLimit) {
                            Text("10 分钟").tag(10)
                            Text("15 分钟").tag(15)
                            Text("20 分钟").tag(20)
                            Text("30 分钟").tag(30)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // 可视化时间分配
                    HourlyTimeVisualization(
                        usableMinutes: hourlyTimeLimit,
                        restMinutes: 60 - hourlyTimeLimit
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .onChange(of: hourlyTimeLimit) { _, newValue in
                    restDurationMinutes = 60 - newValue
                    singleSessionLimit = newValue
                    onSettingsChanged("每小时可用时长", "\(newValue)分钟")
                }
                
                // 说明卡片
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("每小时 \(hourlyTimeLimit) 分钟规则")
                            .font(.subheadline.bold())
                        Text("每小时内可使用娱乐App \(hourlyTimeLimit) 分钟，之后强制休息 \(60 - hourlyTimeLimit) 分钟。下一个小时开始时配额自动重置。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
            
            // 每日总时长
            DurationPickerView(
                title: "每日总时长上限",
                icon: "hourglass",
                selectedMinutes: $dailyTimeLimit,
                options: [60, 90, 120, 180, 240]
            )
            .onChange(of: dailyTimeLimit) { _, newValue in
                onSettingsChanged("每日总时长", "\(newValue)分钟")
            }
        }
    }
}

// MARK: - Hourly Time Visualization
struct HourlyTimeVisualization: View {
    let usableMinutes: Int
    let restMinutes: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // 进度条
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // 可用时间（绿色）
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * CGFloat(usableMinutes) / 60)
                    
                    // 休息时间（灰色）
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: geometry.size.width * CGFloat(restMinutes) / 60)
                }
                .cornerRadius(4)
            }
            .frame(height: 20)
            
            // 图例
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    Text("可用 \(usableMinutes)分钟")
                        .font(.caption)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 10, height: 10)
                    Text("休息 \(restMinutes)分钟")
                        .font(.caption)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Activation Test Section
struct ActivationTestSectionView: View {
    @Binding var isConfigurationActive: Bool
    let isAuthorized: Bool
    let selectedActivityCount: Int
    let hourlyTimeLimit: Int
    @Binding var isSimulatingUsage: Bool
    @Binding var simulatedUsageMinutes: Int
    let onActivate: () -> Void
    let onDeactivate: () -> Void
    let onStartSimulation: () -> Void
    let onStopSimulation: () -> Void
    let addLog: (String, LogType) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 配置状态
            HStack {
                Image(systemName: isConfigurationActive ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isConfigurationActive ? .green : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isConfigurationActive ? "配置已激活" : "配置未激活")
                        .font(.headline)
                    Text(isConfigurationActive ? "娱乐App已被限制" : "点击激活开始限制")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(isConfigurationActive ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            
            // 激活/停用按钮
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
                    .disabled(!isAuthorized || selectedActivityCount == 0)
                }
            }
            
            // 模拟器测试
            if isConfigurationActive {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🧪 模拟器测试")
                        .font(.subheadline.bold())
                    
                    // 模拟进度
                    VStack(spacing: 8) {
                        HStack {
                            Text("模拟使用时间")
                                .font(.caption)
                            Spacer()
                            Text("\(simulatedUsageMinutes) / \(hourlyTimeLimit) 分钟")
                                .font(.caption.bold())
                                .foregroundColor(simulatedUsageMinutes >= hourlyTimeLimit ? .red : .primary)
                        }
                        
                        ProgressView(value: Double(simulatedUsageMinutes), total: Double(hourlyTimeLimit))
                            .tint(simulatedUsageMinutes >= hourlyTimeLimit ? .red : .green)
                    }
                    
                    // 模拟控制
                    HStack(spacing: 12) {
                        if isSimulatingUsage {
                            Button {
                                onStopSimulation()
                            } label: {
                                Label("停止模拟", systemImage: "stop.fill")
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
                            // 重置模拟
                            onStopSimulation()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                addLog("🔄 模拟已重置", .info)
                            }
                        } label: {
                            Label("重置", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("模拟器以1秒=1分钟的速度运行，用于快速测试每小时限制逻辑")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // 前置条件检查
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
                        Text("选择至少1个App")
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

// MARK: - Test Cases Documentation
struct TestCasesDocumentationView: View {
    @State private var expandedCase: Int? = nil
    
    let testCases = [
        (
            id: 1,
            title: "TC-001: 权限请求流程",
            steps: """
            1. 启动App，进入娱乐组配置
            2. 点击「检查权限」按钮
            3. 如未授权，点击「请求授权」
            4. 系统弹出授权对话框
            5. 选择「允许」
            预期结果：权限状态变为「已授权」
            """,
            status: "Ready"
        ),
        (
            id: 2,
            title: "TC-002: App选择功能",
            steps: """
            1. 完成权限授权
            2. 点击「选择」按钮
            3. 在FamilyActivityPicker中选择娱乐类App
            4. 确认选择
            预期结果：显示已选择的App数量
            """,
            status: "Ready"
        ),
        (
            id: 3,
            title: "TC-003: 每小时15分钟限制",
            steps: """
            1. 设置每小时限制为15分钟
            2. 激活配置
            3. 使用模拟器测试
            4. 等待模拟到15分钟
            预期结果：触发强制休息，显示Shield
            """,
            status: "Ready"
        ),
        (
            id: 4,
            title: "TC-004: 强制休息验证",
            steps: """
            1. 达到每小时限制后
            2. 验证Shield显示
            3. 等待休息时间结束
            4. 验证配额重置
            预期结果：下一小时可继续使用15分钟
            """,
            status: "Planned"
        ),
        (
            id: 5,
            title: "TC-005: 模拟器快速测试",
            steps: """
            1. 激活配置
            2. 点击「开始模拟」
            3. 观察日志输出
            4. 验证限制触发时机
            预期结果：日志显示正确的限制触发
            """,
            status: "Ready"
        )
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
                            if expandedCase == testCase.id {
                                expandedCase = nil
                            } else {
                                expandedCase = testCase.id
                            }
                        }
                    } label: {
                        HStack {
                            StatusBadgeView(
                                testCase.status,
                                color: testCase.status == "Ready" ? .green : .orange
                            )
                            
                            Text(testCase.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: expandedCase == testCase.id ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if expandedCase == testCase.id {
                        Text(testCase.steps)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    let title: String
    @Binding var selectedDate: Date
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        onConfirm()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EntertainmentGroupConfigView()
    }
}
