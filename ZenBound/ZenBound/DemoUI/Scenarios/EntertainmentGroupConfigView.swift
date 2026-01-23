import SwiftUI
import SwiftData

/// 场景: 娱乐组配置页面 (Entertainment Group)
/// 支持设置周末或假期App每日总使用时长、每小时单次使用时长限制
struct EntertainmentGroupConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 假期选择
    @State private var enableWeekends = true              // 周末生效
    @State private var selectedHolidays: [Date] = []      // 选择的假期
    @State private var selectedCustomDates: [Date] = []   // 自定义日期
    @State private var showHolidayPicker = false
    @State private var showCustomDatePicker = false
    @State private var tempSelectedDate = Date()
    
    // MARK: - 娱乐限制设置
    @State private var dailyTimeLimit = 120               // 每日总时长（分钟）
    @State private var singleSessionLimit = 30            // 单次时长（分钟）
    
    // 延长使用设置
    @State private var enableExtension = true             // 允许延长使用
    @State private var extensionCount = 2                 // 延长次数
    @State private var extensionMinutes = 10              // 每次延长时间
    
    // 休息强制设置
    @State private var enableRestBlock = true             // 启用休息强制
    @State private var blockAllAppsWhenRest = false       // 休息时屏蔽所有App
    @State private var restReminderInterval = 60          // 提醒间隔（分钟）
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
    @State private var extraTimePerTask = 10              // 每个任务额外时间
    
    // MARK: - Shield 设置
    @State private var shieldMessage = "Enjoy your time!"
    @State private var shieldColor: Color = .green
    @State private var shieldButtonAction = "extend10" // extend10 / openTask
    
    private let shieldMessages = [
        "Enjoy your time!",
        "Remember to take breaks!",
        "Balance is key!",
        "Having fun? Don't forget to rest!"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**娱乐组配置**支持设置周末或假期App每日总使用时长、每小时单次使用时长限制，平衡娱乐与健康。")
                        
                        Text("**核心功能：**")
                        BulletPointView(text: "周末/假期专属娱乐时间配额")
                        BulletPointView(text: "单次使用后强制休息")
                        BulletPointView(text: "可延长使用时间（有限次数）")
                        BulletPointView(text: "完成活动任务赚取额外时间")
                        
                        Text("**适用场景：**")
                        BulletPointView(text: "儿童/青少年周末娱乐管理")
                        BulletPointView(text: "假期游戏时间控制")
                        BulletPointView(text: "培养健康娱乐习惯")
                    }
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
                                    title: "休息提醒间隔",
                                    icon: "bell.badge",
                                    selectedMinutes: $restReminderInterval,
                                    options: [30, 60, 90, 120]
                                )
                                .onChange(of: restReminderInterval) { _, newValue in
                                    addLog("🔔 休息提醒间隔设置为 \(newValue) 分钟", type: .info)
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
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 检测是否为娱乐日",
                            description: "周末/假期/自定义日期检查",
                            code: """
// 检测今天是否应用娱乐组配置
func isEntertainmentDay() -> Bool {
    let calendar = Calendar.current
    let today = Date()
    
    // 检查周末
    if enableWeekends {
        let weekday = calendar.component(.weekday, from: today)
        if weekday == 1 || weekday == 7 { // 周日或周六
            return true
        }
    }
    
    // 检查假期列表
    let todayStart = calendar.startOfDay(for: today)
    if selectedHolidays.contains(where: {
        calendar.startOfDay(for: $0) == todayStart
    }) {
        return true
    }
    
    // 检查自定义日期
    if selectedCustomDates.contains(where: {
        calendar.startOfDay(for: $0) == todayStart
    }) {
        return true
    }
    
    return false
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 延长使用时间实现",
                            description: "Shield按钮扩展使用时间",
                            code: """
// 在 ShieldActionExtension 中处理延长请求
func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
) {
    guard action == .primaryButtonPressed else {
        completionHandler(.close)
        return
    }
    
    // 检查延长次数
    let remainingExtensions = getRemainingExtensions()
    guard remainingExtensions > 0 else {
        completionHandler(.close)
        return
    }
    
    // 消耗一次延长机会
    decrementExtensionCount()
    
    // 临时解除屏蔽
    let store = ManagedSettingsStore()
    store.shield.applications = nil
    
    // 设置延长计时器
    scheduleReblock(after: extensionMinutes * 60)
    
    completionHandler(.close)
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 强制休息实现",
                            description: "单次使用后启动休息",
                            code: """
// 达到单次使用时长后强制休息
func enforceRest(for profile: BlockedProfiles) {
    // 激活屏蔽
    let appBlocker = AppBlockerUtil()
    
    if blockAllAppsWhenRest {
        // 屏蔽所有应用
        appBlocker.activateRestrictions(for: allAppsSelection)
    } else {
        // 仅屏蔽娱乐应用
        appBlocker.activateRestrictions(for: profile)
    }
    
    // 启动休息计时器
    let breakTimer = BreakTimerActivity()
    breakTimer.start(for: profile)
    
    // 发送休息提醒
    let timersUtil = TimersUtil()
    timersUtil.scheduleNotification(
        title: "休息时间",
        message: restReminderMessage,
        seconds: 0,
        identifier: "rest_start"
    )
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 活动任务奖励",
                            description: "完成任务获取额外时间",
                            code: """
// 完成活动任务后奖励额外时间
func rewardTaskCompletion(taskId: String) {
    guard selectedTasks.contains(taskId) else { return }
    
    // 增加可用时间
    let currentQuota = UserDefaults.standard.integer(
        forKey: "entertainment_quota"
    )
    let newQuota = currentQuota + extraTimePerTask * 60
    UserDefaults.standard.set(newQuota, forKey: "entertainment_quota")
    
    // 标记任务完成
    var completedTasks = UserDefaults.standard.stringArray(
        forKey: "completed_tasks_today"
    ) ?? []
    completedTasks.append(taskId)
    UserDefaults.standard.set(
        completedTasks,
        forKey: "completed_tasks_today"
    )
    
    // 发送奖励通知
    sendRewardNotification(minutes: extraTimePerTask)
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
                            title: "实现活动任务系统",
                            description: "需要创建任务管理模块，支持各种任务类型的验证和奖励机制",
                            relatedFiles: ["新建 TaskManager.swift", "新建 TaskModels.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "Shield延长按钮实现",
                            description: "在ShieldActionExtension中实现延长使用时间的逻辑",
                            relatedFiles: ["ShieldActionExtension.swift", "SharedData.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "假期日历集成",
                            description: "集成系统日历或节假日API，自动识别法定假日",
                            relatedFiles: ["新建 HolidayManager.swift", "EventKit"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "跨日期配额追踪",
                            description: "需要持久化存储每日使用配额和剩余时间",
                            relatedFiles: ["SharedData.swift", "BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "家长监督模式",
                            description: "允许家长远程查看和调整孩子的娱乐配额",
                            relatedFiles: ["CloudKit", "新建 FamilySync.swift"]
                        )
                    }
                }
                
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
    }
    
    // MARK: - Private Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func saveConfiguration() {
        addLog("💾 正在保存娱乐组配置...", type: .info)
        addLog("📅 周末生效: \(enableWeekends ? "是" : "否")", type: .success)
        addLog("⏱️ 每日时长: \(dailyTimeLimit)分钟", type: .success)
        addLog("⏱️ 单次时长: \(singleSessionLimit)分钟", type: .success)
        addLog("⏰ 延长设置: \(enableExtension ? "\(extensionCount)次×\(extensionMinutes)分钟" : "禁用")", type: .success)
        addLog("😌 强制休息: \(enableRestBlock ? "开启" : "关闭")", type: .success)
        addLog("🎯 活动任务: \(enableActivityTasks ? "\(selectedTasks.count)个任务" : "禁用")", type: .success)
        addLog("✅ 配置保存成功!", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
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

#Preview {
    NavigationStack {
        EntertainmentGroupConfigView()
    }
}
