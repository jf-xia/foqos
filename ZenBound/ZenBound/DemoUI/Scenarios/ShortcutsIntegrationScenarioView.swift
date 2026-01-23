import SwiftUI
import SwiftData

/// 场景10: 快捷指令集成
/// 通过Siri快捷指令和自动化控制屏蔽
struct ShortcutsIntegrationScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedProfile: BlockedProfiles?
    @State private var generatedDeepLink: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**快捷指令集成**让你通过Siri语音、自动化和快捷指令控制ZenBound。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "\"嘿Siri，开始工作专注\"")
                        BulletPointView(text: "到达办公室自动启动屏蔽")
                        BulletPointView(text: "NFC标签触发开始/停止")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "Siri语音控制")
                        BulletPointView(text: "自动化触发器")
                        BulletPointView(text: "深度链接支持")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "toggleSessionFromDeeplink()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "深链接控制 - 处理URL触发"
                        )
                        DependencyRowView(
                            name: "startSessionFromBackground()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "后台启动 - 无UI启动会话"
                        )
                        DependencyRowView(
                            name: "stopSessionFromBackground()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "后台停止 - 无UI停止会话"
                        )
                        DependencyRowView(
                            name: "getProfileDeepLink()",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "生成链接 - 创建配置深链接"
                        )
                        DependencyRowView(
                            name: "App Intents",
                            path: "系统框架",
                            description: "快捷指令 - iOS原生Intents"
                        )
                    }
                }
                
                // MARK: - 快捷指令示例
                DemoSectionView(title: "⚡️ 可用快捷指令", icon: "bolt.fill") {
                    VStack(spacing: 12) {
                        ShortcutCardView(
                            icon: "play.fill",
                            title: "开始专注",
                            phrase: "嘿Siri，开始工作专注",
                            description: "启动指定配置的屏蔽会话"
                        )
                        
                        ShortcutCardView(
                            icon: "stop.fill",
                            title: "结束专注",
                            phrase: "嘿Siri，结束专注",
                            description: "停止当前正在进行的会话"
                        )
                        
                        ShortcutCardView(
                            icon: "timer",
                            title: "定时专注",
                            phrase: "嘿Siri，专注30分钟",
                            description: "启动指定时长的定时会话"
                        )
                        
                        ShortcutCardView(
                            icon: "cup.and.saucer",
                            title: "开始休息",
                            phrase: "嘿Siri，休息一下",
                            description: "在会话中启动短暂休息"
                        )
                    }
                }
                
                // MARK: - 自动化场景
                DemoSectionView(title: "🔄 自动化场景", icon: "gearshape.2") {
                    VStack(spacing: 12) {
                        AutomationCardView(
                            trigger: "到达办公室",
                            icon: "building.2.fill",
                            action: "自动开始工作专注",
                            color: .blue
                        )
                        
                        AutomationCardView(
                            trigger: "离开办公室",
                            icon: "car.fill",
                            action: "自动结束工作专注",
                            color: .green
                        )
                        
                        AutomationCardView(
                            trigger: "扫描NFC标签",
                            icon: "wave.3.right",
                            action: "切换屏蔽状态",
                            color: .teal
                        )
                        
                        AutomationCardView(
                            trigger: "每天早上9点",
                            icon: "alarm.fill",
                            action: "开始学习专注",
                            color: .orange
                        )
                        
                        AutomationCardView(
                            trigger: "连接耳机",
                            icon: "airpodspro",
                            action: "开始音乐学习模式",
                            color: .purple
                        )
                    }
                }
                
                // MARK: - 深度链接生成
                DemoSectionView(title: "🔗 深度链接", icon: "link") {
                    VStack(spacing: 16) {
                        // 选择配置
                        if profiles.isEmpty {
                            Text("请先创建配置文件")
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("选择配置:")
                                    .font(.subheadline.bold())
                                
                                ForEach(profiles.prefix(3)) { profile in
                                    Button {
                                        selectedProfile = profile
                                        generateDeepLink(for: profile)
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
                        
                        // 生成的链接
                        if !generatedDeepLink.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("生成的深度链接:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    Text(generatedDeepLink)
                                        .font(.caption.monospaced())
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Button {
                                        copyToClipboard()
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            HStack {
                                Button {
                                    testStartLink()
                                } label: {
                                    Label("测试开始", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button {
                                    testStopLink()
                                } label: {
                                    Label("测试停止", systemImage: "stop.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 定义App Intent",
                            description: "创建Siri可识别的意图",
                            code: """
import AppIntents

// 开始专注意图
struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "开始专注"
    static var description = IntentDescription("启动屏蔽会话")
    
    @Parameter(title: "配置")
    var profileName: String?
    
    @Parameter(title: "时长(分钟)")
    var durationMinutes: Int?
    
    func perform() async throws -> some IntentResult {
        let manager = StrategyManager.shared
        
        // 查找配置
        guard let profile = findProfile(named: profileName) else {
            throw IntentError.profileNotFound
        }
        
        // 启动会话
        manager.startSessionFromBackground(
            profile,
            context: modelContext,
            durationInMinutes: durationMinutes
        )
        
        return .result(dialog: "已开始\\(profile.name)")
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 注册快捷指令",
                            description: "在AppShortcutsProvider中注册",
                            code: """
struct ZenBoundShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "开始\\(.applicationName)专注",
                "启动\\(.applicationName)",
                "开始工作模式"
            ],
            shortTitle: "开始专注",
            systemImageName: "brain.head.profile"
        )
        
        AppShortcut(
            intent: StopFocusIntent(),
            phrases: [
                "结束\\(.applicationName)专注",
                "停止\\(.applicationName)"
            ],
            shortTitle: "结束专注",
            systemImageName: "stop.fill"
        )
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 处理深度链接",
                            description: "在App中处理URL scheme",
                            code: """
// URL格式: zenbound://toggle?profileId=xxx&action=start

@main
struct ZenBoundApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    func handleDeepLink(_ url: URL) {
        let manager = StrategyManager.shared
        
        // 解析URL参数
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let profileId = components.queryItems?.first(where: { $0.name == "profileId" })?.value
        else { return }
        
        let action = components.queryItems?.first(where: { $0.name == "action" })?.value
        
        // 执行操作
        manager.toggleSessionFromDeeplink(
            profileId,
            url: url,
            context: modelContext
        )
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 生成深度链接",
                            description: "为配置创建可分享的链接",
                            code: """
// 获取配置的深度链接
let deepLink = BlockedProfiles.getProfileDeepLink(profile)
// 返回: "zenbound://toggle?profileId=xxx"

// 带动作参数的链接
let startLink = "\\(deepLink)&action=start"
let stopLink = "\\(deepLink)&action=stop"

// 带时长的链接
let timedLink = "\\(deepLink)&action=start&duration=25"

// 用于NFC标签或快捷指令
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
                            title: "添加更多Intent参数",
                            description: "支持配置选择、时长、严格模式等参数",
                            relatedFiles: ["新建 AppIntents/"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "Siri建议集成",
                            description: "基于使用习惯在Siri建议中显示",
                            relatedFiles: ["新建 SiriDonations.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "快捷指令小组件",
                            description: "在快捷指令App中显示ZenBound控制",
                            relatedFiles: ["widget/widgetBundle.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "Focus同步",
                            description: "与iOS Focus模式同步，自动切换配置",
                            relatedFiles: ["新建 FocusModeSync.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "CarPlay支持",
                            description: "在CarPlay中快速启动/停止专注",
                            relatedFiles: ["CarPlay框架"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("快捷指令集成")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Private Methods
    
    private func generateDeepLink(for profile: BlockedProfiles) {
        generatedDeepLink = BlockedProfiles.getProfileDeepLink(profile)
        addLog("🔗 生成深度链接: \(profile.name)", type: .info)
        addLog("📎 \(generatedDeepLink)", type: .success)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = generatedDeepLink
        addLog("📋 已复制到剪贴板", type: .success)
    }
    
    private func testStartLink() {
        guard let profile = selectedProfile else { return }
        addLog("🔗 测试开始链接", type: .info)
        addLog("📱 StrategyManager.toggleSessionFromDeeplink()", type: .success)
        addLog("✅ 模拟启动会话: \(profile.name)", type: .success)
    }
    
    private func testStopLink() {
        addLog("🔗 测试停止链接", type: .info)
        addLog("📱 StrategyManager.stopSessionFromBackground()", type: .success)
        addLog("✅ 模拟停止会话", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Shortcut Card View
struct ShortcutCardView: View {
    let icon: String
    let title: String
    let phrase: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.pink)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text("\"\(phrase)\"")
                    .font(.caption)
                    .foregroundColor(.pink)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Automation Card View
struct AutomationCardView: View {
    let trigger: String
    let icon: String
    let action: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("当 \(trigger)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(action)
                    .font(.subheadline.bold())
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(color.opacity(0.5))
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ShortcutsIntegrationScenarioView()
    }
}
