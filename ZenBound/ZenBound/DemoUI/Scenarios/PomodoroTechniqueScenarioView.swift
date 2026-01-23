import SwiftUI
import SwiftData

/// 场景5: 番茄工作法
/// 25分钟专注 + 5分钟休息的循环工作法
struct PomodoroTechniqueScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logMessages: [LogMessage] = []
    
    // 番茄钟设置
    @State private var focusDuration = 25
    @State private var shortBreakDuration = 5
    @State private var longBreakDuration = 15
    @State private var sessionsBeforeLongBreak = 4
    
    // 状态
    @State private var currentPhase: PomodoroPhase = .idle
    @State private var completedPomodoros = 0
    @State private var remainingSeconds = 0
    @State private var timer: Timer?
    
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
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**番茄工作法**是一种经典的时间管理技术，通过循环的专注和休息来提高效率。")
                        
                        Text("**标准流程：**")
                        BulletPointView(text: "25分钟专注工作")
                        BulletPointView(text: "5分钟短休息")
                        BulletPointView(text: "每4个番茄后15分钟长休息")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "自动计时和切换")
                        BulletPointView(text: "屏蔽干扰应用")
                        BulletPointView(text: "番茄数统计")
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
                            .disabled(currentPhase != .idle)
                            
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
                    }
                }
                
                // MARK: - 参数设置
                DemoSectionView(title: "⚙️ 参数设置", icon: "slider.horizontal.3") {
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
                    }
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
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func startPomodoro() {
        currentPhase = .focus
        remainingSeconds = focusDuration * 60
        
        addLog("🍅 开始番茄钟 #\(completedPomodoros + 1)", type: .info)
        addLog("⏱️ 专注时长: \(focusDuration) 分钟", type: .info)
        addLog("🔒 ShortcutTimerBlockingStrategy.startBlocking()", type: .success)
        addLog("📱 LiveActivityManager.startSessionActivity()", type: .success)
        
        startTimer()
    }
    
    private func stopPomodoro() {
        timer?.invalidate()
        currentPhase = .idle
        remainingSeconds = 0
        
        addLog("⏹️ 番茄钟已停止", type: .warning)
        addLog("🔓 AppBlockerUtil.deactivateRestrictions()", type: .success)
    }
    
    private func resetPomodoro() {
        timer?.invalidate()
        currentPhase = .idle
        remainingSeconds = 0
        completedPomodoros = 0
        
        addLog("🔄 番茄钟已重置", type: .info)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                handlePhaseComplete()
            }
        }
    }
    
    private func handlePhaseComplete() {
        timer?.invalidate()
        
        switch currentPhase {
        case .focus:
            completedPomodoros += 1
            addLog("✅ 番茄 #\(completedPomodoros) 完成!", type: .success)
            
            if completedPomodoros % sessionsBeforeLongBreak == 0 {
                currentPhase = .longBreak
                remainingSeconds = longBreakDuration * 60
                addLog("🚶 开始长休息 (\(longBreakDuration)分钟)", type: .info)
            } else {
                currentPhase = .shortBreak
                remainingSeconds = shortBreakDuration * 60
                addLog("☕️ 开始短休息 (\(shortBreakDuration)分钟)", type: .info)
            }
            startTimer()
            
        case .shortBreak, .longBreak:
            addLog("⏰ 休息结束", type: .info)
            currentPhase = .idle
            remainingSeconds = 0
            
        case .idle:
            break
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

#Preview {
    NavigationStack {
        PomodoroTechniqueScenarioView()
    }
}
