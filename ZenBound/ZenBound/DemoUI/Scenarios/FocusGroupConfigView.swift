import SwiftUI
import SwiftData

/// 场景: 专注组配置页面 (Focus Group)
/// 使用番茄工作法，强制用户在使用一段时间后休息，促进健康使用习惯
struct FocusGroupConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 番茄时钟设置
    @State private var pomodoroDuration = 25        // 番茄时长（分钟）
    @State private var breakDuration = 5           // 休息时长（分钟）
    @State private var pomodoroCycles = 3          // 番茄周期数
    
    // MARK: - 专注限制设置
    @State private var disableNotifications = true  // 专注期间禁用通知
    @State private var blockAllApps = false         // 专注期间禁止所有App
    @State private var preventAppSwitching = true   // 专注期间禁止切换App
    @State private var photoCheckIn = false         // 完成每个番茄时间后拍照打卡
    @State private var reminderBefore5Min = true    // 番茄时钟结束前5分钟提醒
    @State private var breakEndReminder = true      // 休息时间结束前1分钟提醒
    @State private var bonusEntertainmentTime = 5   // 完成番茄后获取额外娱乐时间
    @State private var enableBonusTime = false      // 启用额外娱乐时间奖励
    
    // MARK: - Shield 设置
    @State private var shieldMessage = "Focus Time!"
    @State private var shieldColor: Color = .red
    
    private let shieldMessages = [
        "Focus Time!",
        "Take a deep breath",
        "You can do it!",
        "Stay focused, stay strong!"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**专注组配置**使用番茄工作法，强制用户在专注一段时间后休息，促进健康使用习惯。")
                        
                        Text("**核心功能：**")
                        BulletPointView(text: "自定义番茄时长、休息时长和周期数")
                        BulletPointView(text: "专注期间屏蔽干扰应用和通知")
                        BulletPointView(text: "完成番茄后获取额外娱乐时间奖励")
                        BulletPointView(text: "支持拍照打卡记录专注成果")
                        
                        Text("**适用场景：**")
                        BulletPointView(text: "需要集中注意力完成工作/学习任务")
                        BulletPointView(text: "培养健康的时间管理习惯")
                        BulletPointView(text: "防止长时间连续使用电子设备")
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
                            name: "TimersUtil",
                            path: "ZenBound/Utils/TimersUtil.swift",
                            description: "通知调度 - 提前提醒功能"
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
                
                // MARK: - 番茄时钟设置
                DemoSectionView(title: "🍅 番茄时钟设置", icon: "timer") {
                    VStack(spacing: 12) {
                        DurationPickerView(
                            title: "番茄时长",
                            icon: "brain.head.profile",
                            selectedMinutes: $pomodoroDuration,
                            options: [15, 25, 30, 45, 60]
                        )
                        .onChange(of: pomodoroDuration) { _, newValue in
                            addLog("⏱️ 番茄时长设置为 \(newValue) 分钟", type: .info)
                        }
                        
                        DurationPickerView(
                            title: "休息时长",
                            icon: "cup.and.saucer",
                            selectedMinutes: $breakDuration,
                            options: [5, 10, 15, 20]
                        )
                        .onChange(of: breakDuration) { _, newValue in
                            addLog("☕️ 休息时长设置为 \(newValue) 分钟", type: .info)
                        }
                        
                        CountPickerView(
                            title: "番茄周期",
                            icon: "repeat",
                            selectedCount: $pomodoroCycles,
                            options: [1, 2, 3, 4, 5, 6],
                            suffix: "个"
                        )
                        .onChange(of: pomodoroCycles) { _, newValue in
                            addLog("🔄 番茄周期设置为 \(newValue) 个", type: .info)
                        }
                        
                        // 时间摘要
                        HStack {
                            VStack(spacing: 4) {
                                Text("总专注时间")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(pomodoroDuration * pomodoroCycles) 分钟")
                                    .font(.title3.bold())
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(spacing: 4) {
                                Text("总休息时间")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(breakDuration * (pomodoroCycles - 1)) 分钟")
                                    .font(.title3.bold())
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(spacing: 4) {
                                Text("总时长")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(totalSessionTime) 分钟")
                                    .font(.title3.bold())
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // MARK: - 专注限制设置
                DemoSectionView(title: "🔒 专注限制设置", icon: "lock.shield") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "专注期间禁用通知",
                            subtitle: "防止通知打断专注",
                            icon: "bell.slash",
                            isOn: $disableNotifications
                        )
                        .onChange(of: disableNotifications) { _, newValue in
                            addLog("🔕 禁用通知: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "专注期间禁止所有App",
                            subtitle: "除白名单外的所有应用",
                            icon: "app.badge.fill",
                            isOn: $blockAllApps
                        )
                        .onChange(of: blockAllApps) { _, newValue in
                            addLog("📱 禁止所有App: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "专注期间禁止切换App",
                            subtitle: "强制停留在当前应用",
                            icon: "rectangle.on.rectangle.slash",
                            isOn: $preventAppSwitching
                        )
                        .onChange(of: preventAppSwitching) { _, newValue in
                            addLog("🚫 禁止切换App: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "完成番茄后拍照打卡",
                            subtitle: "记录你的专注成果",
                            icon: "camera",
                            isOn: $photoCheckIn
                        )
                        .onChange(of: photoCheckIn) { _, newValue in
                            addLog("📸 拍照打卡: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "番茄结束前5分钟提醒",
                            subtitle: "提前准备收尾工作",
                            icon: "bell.badge",
                            isOn: $reminderBefore5Min
                        )
                        .onChange(of: reminderBefore5Min) { _, newValue in
                            addLog("⏰ 5分钟提前提醒: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "休息结束前1分钟提醒",
                            subtitle: "准备开始下一个番茄",
                            icon: "alarm",
                            isOn: $breakEndReminder
                        )
                        .onChange(of: breakEndReminder) { _, newValue in
                            addLog("⏰ 休息结束提醒: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        // 额外娱乐时间奖励
                        VStack(spacing: 12) {
                            ToggleSettingRow(
                                title: "完成番茄后获取额外娱乐时间",
                                subtitle: "作为完成专注的奖励",
                                icon: "gift",
                                isOn: $enableBonusTime,
                                iconColor: .orange
                            )
                            .onChange(of: enableBonusTime) { _, newValue in
                                addLog("🎁 额外娱乐时间奖励: \(newValue ? "开启" : "关闭")", type: .info)
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
                                    addLog("🎮 每个番茄奖励 \(newValue) 分钟娱乐时间", type: .info)
                                }
                            }
                        }
                        .animation(.easeInOut, value: enableBonusTime)
                    }
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
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 创建番茄配置文件",
                            description: "配置番茄时钟参数",
                            code: """
// 创建专注组配置
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "番茄专注",
    selection: selectedApps,
    blockingStrategyId: ShortcutTimerBlockingStrategy.id,
    strategyData: StrategyTimerData.toData(
        from: StrategyTimerData(durationInMinutes: 25)
    ),
    enableLiveActivity: true,
    reminderTimeInSeconds: 5 * 60,  // 5分钟提前提醒
    enableBreaks: true,
    breakTimeInMinutes: 5
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 启动番茄会话",
                            description: "开始专注计时",
                            code: """
// 启动番茄工作法会话
let strategy = ShortcutTimerBlockingStrategy()
strategy.startBlocking(
    context: context,
    profile: focusProfile,
    forceStart: false
)

// 调度提前提醒
let timersUtil = TimersUtil()
timersUtil.scheduleNotification(
    title: "番茄即将完成",
    message: "还有5分钟，准备收尾工作",
    seconds: (pomodoroDuration - 5) * 60,
    identifier: "pomodoro_reminder"
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 处理休息阶段",
                            description: "番茄完成后自动休息",
                            code: """
// 番茄完成后启动休息
func startBreak(for profile: BlockedProfiles) {
    // 解除应用屏蔽
    appBlocker.deactivateRestrictions()
    
    // 启动休息计时器
    let breakTimer = BreakTimerActivity()
    breakTimer.start(for: profile)
    
    // 更新 Live Activity
    liveActivityManager.updateBreakState(session: session)
    
    // 调度休息结束提醒
    timersUtil.scheduleNotification(
        title: "休息即将结束",
        message: "1分钟后开始下一个番茄",
        seconds: (breakDuration - 1) * 60,
        identifier: "break_end_reminder"
    )
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 奖励额外娱乐时间",
                            description: "完成番茄后的激励机制",
                            code: """
// 完成番茄后增加娱乐配额
func rewardBonusTime(completedPomodoros: Int) {
    let bonusMinutes = completedPomodoros * bonusEntertainmentTime
    
    // 更新娱乐配置的可用时间
    // 这需要与娱乐组配置联动
    UserDefaults.standard.set(
        bonusMinutes,
        forKey: "earnedEntertainmentMinutes"
    )
    
    // 发送完成通知
    let content = UNMutableNotificationContent()
    content.title = "🎉 番茄完成!"
    content.body = "你获得了 \\(bonusMinutes) 分钟额外娱乐时间"
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
                            title: "添加禁止切换App功能",
                            description: "当前iOS不支持直接禁止切换App，可考虑使用Guided Access API或在切换时立即显示Shield",
                            relatedFiles: ["ShieldConfigurationExtension.swift", "DeviceActivityMonitorExtension.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "实现拍照打卡功能",
                            description: "番茄完成时调用相机API拍照，存储到相册并关联Session记录",
                            relatedFiles: ["BlockedProfileSession.swift", "新建 PhotoCheckInManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "番茄与娱乐组联动",
                            description: "完成番茄自动增加娱乐组可用时间，需要建立配置间的关联机制",
                            relatedFiles: ["BlockedProfiles.swift", "SharedData.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "添加专注勿扰模式",
                            description: "集成iOS Focus Mode API，专注期间自动开启勿扰",
                            relatedFiles: ["FocusFilter.swift (新建)", "AppIntents"]
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
    }
    
    // MARK: - Computed Properties
    
    private var totalSessionTime: Int {
        pomodoroDuration * pomodoroCycles + breakDuration * (pomodoroCycles - 1)
    }
    
    // MARK: - Private Methods
    
    private func saveConfiguration() {
        addLog("💾 正在保存专注组配置...", type: .info)
        addLog("🍅 番茄时长: \(pomodoroDuration)分钟", type: .success)
        addLog("☕️ 休息时长: \(breakDuration)分钟", type: .success)
        addLog("🔄 番茄周期: \(pomodoroCycles)个", type: .success)
        addLog("🛡️ Shield消息: \(shieldMessage)", type: .success)
        addLog("✅ 配置保存成功!", type: .success)
        
        // 实际实现时创建 BlockedProfiles
        // BlockedProfiles.createProfile(...)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

#Preview {
    NavigationStack {
        FocusGroupConfigView()
    }
}
