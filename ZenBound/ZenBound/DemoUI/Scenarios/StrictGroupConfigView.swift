import SwiftUI
import SwiftData

/// 场景: 严格组配置页面 (Strict Group)
/// 限制App当天的使用时间范围和使用时长，达到限制后完全阻止用户继续使用该App，直到第二天重置
struct StrictGroupConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 应用选择
    @State private var selectedAppsCount = 0
    @State private var selectedWebsitesCount = 0
    @State private var blockedKeywords: [String] = []
    @State private var newKeyword = ""
    
    // MARK: - 严格限制设置
    @State private var dailyTimeLimit = 60          // 每日总时长限制（分钟）
    @State private var singleSessionLimit = 15     // 单次使用时长限制（分钟）
    @State private var alwaysActive = true         // 是否全天启用
    
    // 时间段设置
    @State private var scheduleStartHour = 9
    @State private var scheduleStartMinute = 0
    @State private var scheduleEndHour = 22
    @State private var scheduleEndMinute = 0
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    @State private var schedules: [(start: String, end: String, days: Set<Weekday>)] = []
    
    // 其他设置
    @State private var enableEmergencyUnlock = true  // 紧急解锁
    @State private var blockAppStoreInstalls = false // 限制App Store安装
    @State private var emergencyUnlockCount = 3     // 紧急解锁次数
    
    // MARK: - Shield 设置
    @State private var shieldMessage = "Daily limit reached"
    @State private var shieldColor: Color = .orange
    @State private var shieldButtonAction = "openTask" // openTask / emergencyUse
    
    private let shieldMessages = [
        "Daily limit reached",
        "Come back tomorrow",
        "Time's up for today!",
        "Take a break"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**严格组配置**限制App当天的使用时间范围和使用时长，达到限制后完全阻止用户继续使用，直到第二天重置。")
                        
                        Text("**核心功能：**")
                        BulletPointView(text: "设置每日总使用时长上限")
                        BulletPointView(text: "限制单次连续使用时长")
                        BulletPointView(text: "自定义生效时间段和日期")
                        BulletPointView(text: "紧急解锁机制（有限次数）")
                        BulletPointView(text: "可选择屏蔽关键词和网站")
                        
                        Text("**适用场景：**")
                        BulletPointView(text: "严格控制社交媒体/游戏使用时间")
                        BulletPointView(text: "戒除手机成瘾习惯")
                        BulletPointView(text: "儿童/青少年屏幕时间管理")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "BlockedProfiles",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "配置存储 - 时间限制、严格模式等"
                        )
                        DependencyRowView(
                            name: "Schedule (BlockedProfileSchedule)",
                            path: "ZenBound/Models/Schedule.swift",
                            description: "时间段调度 - 生效时间配置"
                        )
                        DependencyRowView(
                            name: "ScheduleTimerActivity",
                            path: "ZenBound/Models/Timers/ScheduleTimerActivity.swift",
                            description: "调度计时 - 自动开始/结束屏蔽"
                        )
                        DependencyRowView(
                            name: "StrategyManager.emergencyUnblock",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "紧急解锁 - 有限次数的快速解锁"
                        )
                        DependencyRowView(
                            name: "DeviceActivityMonitorExtension",
                            path: "monitor/DeviceActivityMonitorExtension.swift",
                            description: "后台监控 - 时间到期自动触发屏蔽"
                        )
                        DependencyRowView(
                            name: "enableStrictMode",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "严格模式标志 - 防止轻易解锁"
                        )
                    }
                }
                
                // MARK: - 应用选择
                DemoSectionView(title: "📱 应用选择", icon: "apps.iphone") {
                    VStack(spacing: 12) {
                        AppSelectionPlaceholder(
                            title: "选择干扰应用",
                            selectedCount: selectedAppsCount
                        ) {
                            // 实际实现时调用 FamilyActivityPicker
                            selectedAppsCount = 12
                            addLog("📱 已选择 12 个干扰应用", type: .info)
                        }
                        
                        AppSelectionPlaceholder(
                            title: "选择干扰网站",
                            selectedCount: selectedWebsitesCount
                        ) {
                            selectedWebsitesCount = 5
                            addLog("🌐 已选择 5 个干扰网站", type: .info)
                        }
                        
                        // 关键词屏蔽
                        VStack(alignment: .leading, spacing: 8) {
                            Text("屏蔽关键词")
                                .font(.subheadline.bold())
                            
                            HStack {
                                TextField("输入关键词", text: $newKeyword)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button {
                                    if !newKeyword.isEmpty {
                                        blockedKeywords.append(newKeyword)
                                        addLog("🔤 添加关键词: \(newKeyword)", type: .info)
                                        newKeyword = ""
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                }
                                .disabled(newKeyword.isEmpty)
                            }
                            
                            if !blockedKeywords.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(blockedKeywords, id: \.self) { keyword in
                                        HStack(spacing: 4) {
                                            Text(keyword)
                                                .font(.caption)
                                            Button {
                                                blockedKeywords.removeAll { $0 == keyword }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // MARK: - 严格限制设置
                DemoSectionView(title: "⏱️ 时间限制设置", icon: "clock") {
                    VStack(spacing: 12) {
                        DurationPickerView(
                            title: "每日总时长限制",
                            icon: "hourglass",
                            selectedMinutes: $dailyTimeLimit,
                            options: [5, 10, 15, 30, 45, 60, 90, 120, 180]
                        )
                        .onChange(of: dailyTimeLimit) { _, newValue in
                            addLog("⏱️ 每日时长限制设置为 \(newValue) 分钟", type: .info)
                        }
                        
                        DurationPickerView(
                            title: "单次使用时长限制",
                            icon: "timer",
                            selectedMinutes: $singleSessionLimit,
                            options: [5, 10, 15, 30, 45, 60]
                        )
                        .onChange(of: singleSessionLimit) { _, newValue in
                            addLog("⏱️ 单次时长限制设置为 \(newValue) 分钟", type: .info)
                        }
                        
                        // 剩余时间显示
                        HStack {
                            VStack(spacing: 4) {
                                Text("今日剩余")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(dailyTimeLimit) 分钟")
                                    .font(.title2.bold())
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(spacing: 4) {
                                Text("单次上限")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(singleSessionLimit) 分钟")
                                    .font(.title2.bold())
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // MARK: - 时间段调度
                DemoSectionView(title: "📅 时间段调度", icon: "calendar.badge.clock") {
                    VStack(spacing: 16) {
                        ToggleSettingRow(
                            title: "全天启用",
                            subtitle: "24小时持续生效",
                            icon: "clock.fill",
                            isOn: $alwaysActive
                        )
                        .onChange(of: alwaysActive) { _, newValue in
                            addLog("🕐 全天启用: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        if !alwaysActive {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("自定义时间段")
                                    .font(.subheadline.bold())
                                
                                SchedulePickerView(
                                    startHour: $scheduleStartHour,
                                    startMinute: $scheduleStartMinute,
                                    endHour: $scheduleEndHour,
                                    endMinute: $scheduleEndMinute,
                                    selectedDays: $selectedDays
                                )
                                
                                Button {
                                    let start = String(format: "%02d:%02d", scheduleStartHour, scheduleStartMinute)
                                    let end = String(format: "%02d:%02d", scheduleEndHour, scheduleEndMinute)
                                    schedules.append((start: start, end: end, days: selectedDays))
                                    addLog("📅 添加时间段: \(start) - \(end)", type: .success)
                                } label: {
                                    Label("添加时间段", systemImage: "plus.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                
                                // 已添加的时间段
                                if !schedules.isEmpty {
                                    ForEach(schedules.indices, id: \.self) { index in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(schedules[index].start) - \(schedules[index].end)")
                                                    .font(.subheadline.bold())
                                                Text(schedules[index].days.map { $0.shortLabel }.joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Button {
                                                schedules.remove(at: index)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut, value: alwaysActive)
                }
                
                // MARK: - 其他设置
                DemoSectionView(title: "🔐 其他设置", icon: "gearshape") {
                    VStack(spacing: 12) {
                        VStack(spacing: 12) {
                            ToggleSettingRow(
                                title: "紧急解锁",
                                subtitle: "允许有限次数的快速解锁",
                                icon: "exclamationmark.shield",
                                isOn: $enableEmergencyUnlock,
                                iconColor: .red
                            )
                            .onChange(of: enableEmergencyUnlock) { _, newValue in
                                addLog("🚨 紧急解锁: \(newValue ? "开启" : "关闭")", type: .info)
                            }
                            
                            if enableEmergencyUnlock {
                                CountPickerView(
                                    title: "每周紧急解锁次数",
                                    icon: "key.fill",
                                    selectedCount: $emergencyUnlockCount,
                                    options: [1, 2, 3, 5, 10],
                                    suffix: "次"
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .onChange(of: emergencyUnlockCount) { _, newValue in
                                    addLog("🔑 紧急解锁次数设置为 \(newValue) 次/周", type: .info)
                                }
                            }
                        }
                        .animation(.easeInOut, value: enableEmergencyUnlock)
                        
                        ToggleSettingRow(
                            title: "限制 App Store 安装新应用",
                            subtitle: "防止安装替代应用绕过限制",
                            icon: "bag.badge.minus",
                            isOn: $blockAppStoreInstalls,
                            iconColor: .purple
                        )
                        .onChange(of: blockAppStoreInstalls) { _, newValue in
                            addLog("🛍️ 限制App Store安装: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                    }
                }
                
                // MARK: - Shield 设置
                DemoSectionView(title: "🛡️ Shield 设置", icon: "shield.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("**Shield 按钮动作**")
                            .font(.subheadline)
                        
                        VStack(spacing: 8) {
                            Button {
                                shieldButtonAction = "openTask"
                            } label: {
                                HStack {
                                    Image(systemName: "checklist")
                                        .foregroundColor(.blue)
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
                                .background(shieldButtonAction == "openTask" ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            Button {
                                shieldButtonAction = "emergencyUse"
                            } label: {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("非娱乐App紧急使用")
                                            .foregroundColor(.primary)
                                        Text("消耗紧急解锁次数")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if shieldButtonAction == "emergencyUse" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(shieldButtonAction == "emergencyUse" ? Color.orange.opacity(0.1) : Color(.systemGray6))
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
                            title: "1. 创建严格模式配置",
                            description: "设置时间限制和严格模式",
                            code: """
// 创建严格组配置
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "严格限制",
    selection: distractingApps,
    blockingStrategyId: ManualBlockingStrategy.id,
    enableStrictMode: true,          // 启用严格模式
    enableSafariBlocking: true,      // 屏蔽Safari
    domains: blockedWebsites,        // 屏蔽网站列表
    schedule: BlockedProfileSchedule(
        days: selectedDays.map { $0 },
        startHour: 9, startMinute: 0,
        endHour: 22, endMinute: 0
    )
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 配置时间段调度",
                            description: "自动开始/结束屏蔽",
                            code: """
// 调度时间段屏蔽
DeviceActivityCenterUtil.scheduleTimerActivity(for: profile)

// 内部实现:
// 1. 计算时间间隔
let (start, end) = getScheduleInterval(from: profile)

// 2. 注册设备活动监控
let center = DeviceActivityCenter()
try center.startMonitoring(
    activityName,
    during: DeviceActivitySchedule(
        intervalStart: start,
        intervalEnd: end,
        repeats: true
    )
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 紧急解锁实现",
                            description: "有限次数的快速解锁",
                            code: """
// StrategyManager.emergencyUnblock()
func emergencyUnblock(context: ModelContext) {
    // 检查剩余次数
    guard getRemainingEmergencyUnblocks() > 0 else {
        onErrorMessage?("本周紧急解锁次数已用完")
        return
    }
    
    // 消耗一次解锁机会
    emergencyUnblocksRemaining -= 1
    
    // 解除屏蔽
    appBlocker.deactivateRestrictions()
    
    // 结束当前会话
    if let session = activeSession {
        session.endSession()
        liveActivityManager.endSessionActivity()
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 每日时长追踪",
                            description: "累计使用时间检查",
                            code: """
// 在 DeviceActivityMonitor 中追踪使用时长
// 需要扩展现有功能

func trackUsageTime(for profile: SharedData.ProfileSnapshot) {
    let today = Calendar.current.startOfDay(for: Date())
    let todayUsageKey = "usage_\\(profile.id)_\\(today)"
    
    var totalUsage = UserDefaults.standard.integer(forKey: todayUsageKey)
    totalUsage += sessionDuration
    
    if totalUsage >= dailyTimeLimit * 60 {
        // 达到每日限制，激活屏蔽
        store.shield.applications = profile.selectedActivity.applicationTokens
        
        // 发送通知
        sendLimitReachedNotification()
    }
    
    UserDefaults.standard.set(totalUsage, forKey: todayUsageKey)
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
                            title: "实现每日使用时长追踪",
                            description: "当前缺少累计使用时长功能，需要在DeviceActivityReport或后台持续追踪应用使用时间",
                            relatedFiles: ["DeviceActivityMonitorExtension.swift", "SharedData.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "单次使用时长限制",
                            description: "需要实现连续使用检测，超过单次限制后强制休息",
                            relatedFiles: ["StrategyTimerActivity.swift", "AppBlockerUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "App Store安装限制",
                            description: "需要使用Screen Time API的应用类别限制功能",
                            relatedFiles: ["AppBlockerUtil.swift", "ManagedSettingsStore"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "关键词屏蔽功能",
                            description: "需要集成Safari内容屏蔽器或VPN配置来实现关键词过滤",
                            relatedFiles: ["新建 ContentBlocker Extension"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "多时间段调度",
                            description: "支持配置多个不同的时间段，各时间段可以有不同的限制规则",
                            relatedFiles: ["Schedule.swift", "BlockedProfiles.swift"]
                        )
                    }
                }
                
                // MARK: - 操作按钮
                ActionButtonsView(
                    onSave: saveConfiguration,
                    onCancel: { dismiss() },
                    saveColor: .orange
                )
            }
            .padding()
        }
        .navigationTitle("严格组配置")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Private Methods
    
    private func saveConfiguration() {
        addLog("💾 正在保存严格组配置...", type: .info)
        addLog("📱 选择应用: \(selectedAppsCount)个", type: .success)
        addLog("⏱️ 每日时长: \(dailyTimeLimit)分钟", type: .success)
        addLog("⏱️ 单次时长: \(singleSessionLimit)分钟", type: .success)
        addLog("🚨 紧急解锁: \(enableEmergencyUnlock ? "\(emergencyUnlockCount)次/周" : "禁用")", type: .success)
        addLog("✅ 配置保存成功!", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Flow Layout for Keywords
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    NavigationStack {
        StrictGroupConfigView()
    }
}
