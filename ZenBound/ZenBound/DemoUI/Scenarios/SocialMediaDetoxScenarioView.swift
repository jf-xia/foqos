import SwiftUI
import SwiftData

/// 场景3: 社交媒体戒断
/// 减少社交媒体依赖，培养健康的数字习惯
struct SocialMediaDetoxScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logMessages: [LogMessage] = []
    @State private var isDetoxActive = false
    @State private var currentMessage = FocusMessages.getRandomMessage()
    @State private var detoxStrength: DetoxStrength = .moderate
    @State private var enableStrictMode = false
    @State private var blockedAppsCount = 12
    
    enum DetoxStrength: String, CaseIterable {
        case light = "轻度"
        case moderate = "中度"
        case strict = "严格"
        
        var description: String {
            switch self {
            case .light: return "仅屏蔽主要社交应用"
            case .moderate: return "屏蔽社交和短视频"
            case .strict: return "屏蔽所有娱乐应用"
            }
        }
        
        var icon: String {
            switch self {
            case .light: return "leaf"
            case .moderate: return "shield.lefthalf.filled"
            case .strict: return "lock.shield"
            }
        }
        
        var color: Color {
            switch self {
            case .light: return .green
            case .moderate: return .orange
            case .strict: return .red
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**社交媒体戒断**帮助你减少对社交媒体的依赖，重获时间和注意力。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "感觉刷手机浪费太多时间")
                        BulletPointView(text: "想要培养更健康的数字习惯")
                        BulletPointView(text: "需要专注于重要事务")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "多级戒断强度可选")
                        BulletPointView(text: "励志消息激励坚持")
                        BulletPointView(text: "严格模式防止中途放弃")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "FamilyActivityUtil",
                            path: "ZenBound/Utils/FamilyActivityUtil.swift",
                            description: "活动选择 - 选取社交媒体应用"
                        )
                        DependencyRowView(
                            name: "AppBlockerUtil",
                            path: "ZenBound/Utils/AppBlockerUtil.swift",
                            description: "应用屏蔽 - 执行屏蔽限制"
                        )
                        DependencyRowView(
                            name: "FocusMessages",
                            path: "ZenBound/Utils/FocusMessages.swift",
                            description: "励志消息 - 随机激励语"
                        )
                        DependencyRowView(
                            name: "StrategyManager",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "戒断管理 - 会话和严格模式"
                        )
                        DependencyRowView(
                            name: "enableStrictMode",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "严格模式 - 防止轻易解锁"
                        )
                    }
                }
                
                // MARK: - 励志消息展示
                DemoSectionView(title: "💪 励志消息", icon: "quote.bubble") {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("\"")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                                .offset(x: -120, y: 10)
                            
                            Text(currentMessage)
                                .font(.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("\"")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                                .offset(x: 120, y: -10)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        
                        Button {
                            refreshMessage()
                        } label: {
                            Label("换一条", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 戒断强度选择
                DemoSectionView(title: "⚡️ 戒断强度", icon: "slider.horizontal.3") {
                    VStack(spacing: 16) {
                        ForEach(DetoxStrength.allCases, id: \.self) { strength in
                            Button {
                                detoxStrength = strength
                                addLog("⚡️ 切换戒断强度: \(strength.rawValue)", type: .info)
                            } label: {
                                HStack {
                                    Image(systemName: strength.icon)
                                        .font(.title2)
                                        .foregroundColor(strength.color)
                                        .frame(width: 36)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(strength.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(strength.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if detoxStrength == strength {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(strength.color)
                                    }
                                }
                                .padding()
                                .background(
                                    detoxStrength == strength
                                    ? strength.color.opacity(0.1)
                                    : Color(.systemGray6)
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            detoxStrength == strength ? strength.color : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                        }
                        
                        // 严格模式开关
                        Toggle(isOn: $enableStrictMode) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("严格模式")
                                    .font(.subheadline.bold())
                                Text("启用后无法轻易停止戒断")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: enableStrictMode) { _, newValue in
                            addLog("🔐 严格模式: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // MARK: - 戒断状态
                DemoSectionView(title: "🎮 开始戒断", icon: "play.circle") {
                    VStack(spacing: 16) {
                        if isDetoxActive {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                
                                Text("戒断进行中")
                                    .font(.headline)
                                
                                Text("已屏蔽 \(blockedAppsCount) 个应用")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(currentMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        Button {
                            toggleDetox()
                        } label: {
                            Label(
                                isDetoxActive ? "结束戒断" : "开始戒断",
                                systemImage: isDetoxActive ? "stop.fill" : "play.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isDetoxActive ? .red : detoxStrength.color)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 选择社交媒体应用",
                            description: "使用 FamilyActivitySelection 选取应用",
                            code: """
// 用户通过系统选择器选择应用
@State private var selection = FamilyActivitySelection()

// 获取选择统计
let count = FamilyActivityUtil.countSelectedActivities(
    selection,
    allowMode: false  // 屏蔽模式
)
// 返回: 选中的应用数量

// 获取分类统计
let breakdown = FamilyActivityUtil.getSelectionBreakdown(selection)
// breakdown.categories: 分类数
// breakdown.applications: 应用数
// breakdown.webDomains: 网站数
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 获取励志消息",
                            description: "FocusMessages 提供随机激励语",
                            code: """
// 获取随机励志消息
let message = FocusMessages.getRandomMessage()
// 返回: "专注于当下，未来会感谢你现在的努力。"

// 消息集合
FocusMessages.messages  // [String] 所有消息列表

// 可在屏蔽界面或通知中使用
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 启用严格模式",
                            description: "防止用户轻易放弃戒断",
                            code: """
// 创建严格模式配置
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "社交戒断",
    selection: socialMediaSelection,
    blockingStrategyId: ManualBlockingStrategy.id,
    enableStrictMode: true  // 启用严格模式
)

// 严格模式下，停止需要额外确认或等待
// 配合 emergencyUnblock() 提供紧急出口
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 执行应用屏蔽",
                            description: "AppBlockerUtil 实际屏蔽应用",
                            code: """
let appBlocker = AppBlockerUtil()

// 激活屏蔽
appBlocker.activateRestrictions(for: profile)
// 内部使用 ManagedSettingsStore 设置限制

// 解除屏蔽
appBlocker.deactivateRestrictions()

// 获取网站域名 (用于Safari屏蔽)
let domains = appBlocker.getWebDomains(from: profile)
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
                            title: "添加使用时长统计",
                            description: "显示每日节省的刷屏时间，增强成就感",
                            relatedFiles: ["ProfileInsightsUtil.swift", "BlockedProfileSession.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "预设社交媒体分类",
                            description: "提供常见社交应用的预设选择，简化配置",
                            relatedFiles: ["FamilyActivityUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "添加戒断成就系统",
                            description: "连续戒断天数达成时解锁成就徽章",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "自定义励志消息",
                            description: "允许用户添加个人化的励志语录",
                            relatedFiles: ["FocusMessages.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "社交戒断挑战",
                            description: "7天/21天/30天挑战模式，增加趣味性",
                            relatedFiles: ["StrategyManager.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("社交媒体戒断")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Private Methods
    
    private func refreshMessage() {
        withAnimation {
            currentMessage = FocusMessages.getRandomMessage()
        }
        addLog("💬 刷新励志消息", type: .info)
    }
    
    private func toggleDetox() {
        isDetoxActive.toggle()
        
        if isDetoxActive {
            addLog("🚀 开始社交媒体戒断", type: .info)
            addLog("⚡️ 强度: \(detoxStrength.rawValue)", type: .info)
            addLog("🔐 严格模式: \(enableStrictMode ? "是" : "否")", type: .info)
            addLog("📱 选中应用数: \(blockedAppsCount)", type: .info)
            addLog("🔒 AppBlockerUtil.activateRestrictions()", type: .success)
            addLog("✅ 戒断已启动", type: .success)
            
            // 刷新励志消息
            currentMessage = FocusMessages.getRandomMessage()
        } else {
            if enableStrictMode {
                addLog("⚠️ 严格模式下需要紧急解锁", type: .warning)
            }
            addLog("🔓 AppBlockerUtil.deactivateRestrictions()", type: .success)
            addLog("✅ 戒断已结束", type: .warning)
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

#Preview {
    NavigationStack {
        SocialMediaDetoxScenarioView()
    }
}
