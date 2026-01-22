import SwiftUI
import SwiftData

/// Strategies Demo - 展示屏蔽策略
struct StrategiesDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logMessages: [LogMessage] = []
    @State private var selectedStrategyIndex = 0
    
    private let strategies = StrategyManager.availableStrategies
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BlockingStrategy 协议定义了屏蔽行为的统一接口。")
                        
                        Text("**协议方法：**")
                        BulletPointView(text: "startBlocking() - 开始屏蔽，返回可选的自定义 View")
                        BulletPointView(text: "stopBlocking() - 停止屏蔽，返回可选的自定义 View")
                        BulletPointView(text: "onSessionCreation - 会话创建回调")
                        BulletPointView(text: "onErrorMessage - 错误消息回调")
                        
                        Text("**策略属性：**")
                        BulletPointView(text: "id/name - 策略标识和名称")
                        BulletPointView(text: "description - 策略描述")
                        BulletPointView(text: "iconType - SF Symbol 图标")
                        BulletPointView(text: "color - 主题颜色")
                        BulletPointView(text: "hidden - 是否在选择器中隐藏")
                    }
                }
                
                // MARK: - 策略列表
                DemoSectionView(title: "🛡️ 可用策略 (\(strategies.count))", icon: "shield.lefthalf.filled") {
                    ForEach(Array(strategies.enumerated()), id: \.offset) { index, strategy in
                        StrategyCardView(
                            strategy: strategy,
                            isSelected: index == selectedStrategyIndex,
                            onTap: {
                                selectedStrategyIndex = index
                                logStrategyDetails(strategy)
                            }
                        )
                    }
                }
                
                // MARK: - 策略详情
                if selectedStrategyIndex < strategies.count {
                    let strategy = strategies[selectedStrategyIndex]
                    DemoSectionView(title: "📋 策略详情", icon: "info.circle") {
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRowView(label: "ID", value: type(of: strategy).id)
                            DetailRowView(label: "Name", value: strategy.name)
                            DetailRowView(label: "Description", value: strategy.description)
                            DetailRowView(label: "Icon", value: strategy.iconType)
                            DetailRowView(label: "Hidden", value: strategy.hidden ? "是" : "否")
                            
                            HStack {
                                Text("Color")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Circle()
                                    .fill(strategy.color)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            listAllStrategies()
                        } label: {
                            Label("列出所有策略", systemImage: "list.bullet")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            compareStrategies()
                        } label: {
                            Label("对比策略特性", systemImage: "chart.bar.xaxis")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            findStrategyById()
                        } label: {
                            Label("按 ID 查找策略", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: Manual 策略",
                            description: "最简单的手动开始/停止模式",
                            code: """
let strategy = ManualBlockingStrategy()

// 开始屏蔽
strategy.startBlocking(
    context: context,
    profile: profile,
    forceStart: false
)
// → 立即创建会话，无需额外 UI

// 停止屏蔽
strategy.stopBlocking(context: context, session: session)
// → 立即结束会话
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: NFC 策略",
                            description: "需要扫描 NFC 标签才能停止",
                            code: """
let strategy = NFCBlockingStrategy()

// 开始：正常开始
strategy.startBlocking(...)

// 停止：返回 NFC 扫描 View
let nfcView = strategy.stopBlocking(...)
if let view = nfcView {
    // 显示 NFC 扫描界面
    // 用户扫描正确标签后才真正停止
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: Timer 策略",
                            description: "通过 Shortcuts 启动的定时会话",
                            code: """
// 从 App Intent 启动
let strategy = ShortcutTimerBlockingStrategy()

// 设置持续时间
profile.strategyData = StrategyTimerData
    .toData(from: StrategyTimerData(durationInMinutes: 25))

// 开始会话
strategy.startBlocking(context: context, profile: profile, forceStart: true)
// → 注册 DeviceActivity，25分钟后自动结束
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Strategies")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载，共 \(strategies.count) 个策略", type: .info)
        }
    }
    
    // MARK: - Actions
    private func logStrategyDetails(_ strategy: BlockingStrategy) {
        addLog("📋 选中策略: \(strategy.name)", type: .info)
        addLog("   ID: \(type(of: strategy).id)", type: .info)
        addLog("   描述: \(strategy.description)", type: .info)
        addLog("   隐藏: \(strategy.hidden)", type: .info)
    }
    
    private func listAllStrategies() {
        addLog("📋 所有可用策略:", type: .info)
        for (index, strategy) in strategies.enumerated() {
            let visibility = strategy.hidden ? "🔒" : "👁️"
            addLog("   [\(index)] \(visibility) \(strategy.name)", type: .info)
        }
    }
    
    private func compareStrategies() {
        let visible = strategies.filter { !$0.hidden }
        let hidden = strategies.filter { $0.hidden }
        
        addLog("📊 策略对比:", type: .info)
        addLog("   可见策略: \(visible.count) 个", type: .success)
        for s in visible {
            addLog("      - \(s.name)", type: .info)
        }
        addLog("   隐藏策略: \(hidden.count) 个", type: .warning)
        for s in hidden {
            addLog("      - \(s.name)", type: .info)
        }
    }
    
    private func findStrategyById() {
        let testId = "ManualBlockingStrategy"
        if let found = strategies.first(where: { type(of: $0).id == testId }) {
            addLog("✅ 找到策略: \(found.name)", type: .success)
            addLog("   ID: \(testId)", type: .info)
        } else {
            addLog("❌ 未找到策略: \(testId)", type: .error)
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct StrategyCardView: View {
    let strategy: BlockingStrategy
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: strategy.iconType)
                    .font(.title2)
                    .foregroundColor(strategy.color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(strategy.name)
                            .font(.headline)
                        if strategy.hidden {
                            Image(systemName: "eye.slash")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct DetailRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
        }
    }
}

#Preview {
    NavigationStack {
        StrategiesDemoView()
    }
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}
