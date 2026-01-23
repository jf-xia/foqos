import SwiftUI
import SwiftData
import FamilyControls

/// 场景1: 工作专注模式
/// 一键启动工作专注，屏蔽干扰应用，显示Live Activity实时进度
struct WorkFocusScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var strategyManager: StrategyManager
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedProfile: BlockedProfiles?
    @State private var isBlocking = false
    @State private var elapsedTime: TimeInterval = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**工作专注模式**适用于需要集中注意力完成工作任务的场景。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "处理重要工作任务时，屏蔽社交媒体和娱乐应用")
                        BulletPointView(text: "开会时屏蔽通知干扰")
                        BulletPointView(text: "写作或编程时保持专注")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "一键启动/停止")
                        BulletPointView(text: "实时显示专注时长 (Live Activity)")
                        BulletPointView(text: "手动控制，灵活自由")
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
                
                // MARK: - 实时演示
                DemoSectionView(title: "🎮 实时演示", icon: "play.circle") {
                    VStack(spacing: 16) {
                        // 选择配置
                        if profiles.isEmpty {
                            EmptyStateView(
                                icon: "person.crop.rectangle.stack",
                                title: "无可用配置",
                                message: "请先创建屏蔽配置文件"
                            )
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("选择配置:")
                                    .font(.subheadline.bold())
                                
                                ForEach(profiles.prefix(3)) { profile in
                                    Button {
                                        selectedProfile = profile
                                        addLog("📋 选中配置: \(profile.name)", type: .info)
                                    } label: {
                                        HStack {
                                            Text(profile.name)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if selectedProfile?.id == profile.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // 专注状态显示
                        if isBlocking {
                            VStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                
                                Text(formatDuration(elapsedTime))
                                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                                
                                Text("专注中...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        // 操作按钮
                        HStack {
                            Button {
                                startWorkFocus()
                            } label: {
                                Label("开始专注", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedProfile == nil || isBlocking)
                            
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
                    }
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
            isBlocking = strategyManager.isBlocking
            selectedProfile = profiles.first
        }
    }
    
    // MARK: - Private Methods
    
    private func startWorkFocus() {
        guard let profile = selectedProfile else { return }
        
        addLog("🚀 启动工作专注模式", type: .info)
        addLog("📋 配置: \(profile.name)", type: .info)
        
        // 模拟启动流程
        isBlocking = true
        elapsedTime = 0
        
        addLog("🔒 AppBlockerUtil.activateRestrictions()", type: .success)
        addLog("📱 LiveActivityManager.startSessionActivity()", type: .success)
        addLog("✅ 专注会话已启动", type: .success)
        
        // 模拟计时
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if isBlocking {
                elapsedTime += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func stopWorkFocus() {
        addLog("⏹️ 结束工作专注模式", type: .info)
        addLog("🔓 AppBlockerUtil.deactivateRestrictions()", type: .success)
        addLog("📱 LiveActivityManager.endSessionActivity()", type: .success)
        addLog("⏱️ 本次专注时长: \(formatDuration(elapsedTime))", type: .success)
        
        isBlocking = false
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
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Dependency Row View
struct DependencyRowView: View {
    let name: String
    let path: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(.accentColor)
                Spacer()
            }
            Text(path)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Improvement Card View
struct ImprovementCardView: View {
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
        
        var label: String {
            switch self {
            case .high: return "高优先级"
            case .medium: return "中优先级"
            case .low: return "低优先级"
            }
        }
    }
    
    let priority: Priority
    let title: String
    let description: String
    let relatedFiles: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusBadgeView(priority.label, color: priority.color)
                Spacer()
            }
            
            Text(title)
                .font(.subheadline.bold())
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("相关文件:")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                ForEach(relatedFiles, id: \.self) { file in
                    Text(file)
                        .font(.caption2.monospaced())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        WorkFocusScenarioView()
            .environmentObject(StrategyManager.shared)
    }
}
