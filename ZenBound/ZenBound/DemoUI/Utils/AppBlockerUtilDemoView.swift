import SwiftUI

/// AppBlockerUtil Demo - 展示 Screen Time 屏蔽控制
struct AppBlockerUtilDemoView: View {
    @State private var logMessages: [LogMessage] = []
    @State private var isRestrictionActive = false
    
    private let appBlocker = AppBlockerUtil()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AppBlockerUtil 封装了 ManagedSettingsStore，是应用屏蔽的核心执行器。")
                        
                        Text("**核心功能：**")
                        BulletPointView(text: "activateRestrictions() - 激活屏蔽限制")
                        BulletPointView(text: "deactivateRestrictions() - 解除屏蔽限制")
                        BulletPointView(text: "getWebDomains() - 获取网站域名集合")
                        
                        Text("**屏蔽模式：**")
                        BulletPointView(text: "Block Mode - 屏蔽指定的 App/类别/网站")
                        BulletPointView(text: "Allow Mode - 只允许指定的 App，屏蔽其他所有")
                        
                        Text("**额外功能：**")
                        BulletPointView(text: "denyAppRemoval - 严格模式，禁止卸载 App")
                        BulletPointView(text: "webContent.blockedByFilter - 网页内容过滤")
                    }
                }
                
                // MARK: - 当前状态
                DemoSectionView(title: "🔒 当前状态", icon: "lock.shield") {
                    HStack {
                        Circle()
                            .fill(isRestrictionActive ? .green : .gray)
                            .frame(width: 12, height: 12)
                        Text(isRestrictionActive ? "屏蔽已激活" : "屏蔽未激活")
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Text("⚠️ 实际激活需要 Family Controls 授权")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        Button {
                            simulateActivate()
                        } label: {
                            Label("模拟激活屏蔽", systemImage: "lock.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        
                        Button {
                            simulateDeactivate()
                        } label: {
                            Label("模拟解除屏蔽", systemImage: "lock.open")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Divider()
                        
                        Button {
                            explainModes()
                        } label: {
                            Label("解释 Block/Allow 模式", systemImage: "questionmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - API 映射
                DemoSectionView(title: "🗺️ ManagedSettings API 映射", icon: "map") {
                    VStack(alignment: .leading, spacing: 12) {
                        APIMapRowView(
                            api: "store.shield.applications",
                            description: "屏蔽指定 App",
                            type: "Set<ApplicationToken>?"
                        )
                        APIMapRowView(
                            api: "store.shield.applicationCategories",
                            description: "屏蔽 App 类别",
                            type: "ShieldSettings.ActivityCategoryPolicy<Application>"
                        )
                        APIMapRowView(
                            api: "store.shield.webDomains",
                            description: "屏蔽网站域名",
                            type: "Set<WebDomainToken>?"
                        )
                        APIMapRowView(
                            api: "store.webContent.blockedByFilter",
                            description: "网页内容过滤",
                            type: "WebContentSettings.FilterPolicy<WebDomain>"
                        )
                        APIMapRowView(
                            api: "store.application.denyAppRemoval",
                            description: "禁止卸载 App",
                            type: "Bool"
                        )
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: Block Mode (默认)",
                            description: "屏蔽用户选择的 App 和网站",
                            code: """
// 用户选择了 Instagram, TikTok, twitter.com
let selection = profile.selectedActivity

// Block Mode: 屏蔽这些，允许其他
store.shield.applications = selection.applicationTokens
store.shield.webDomains = selection.webDomainTokens
store.shield.applicationCategories = .specific(selection.categoryTokens)
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: Allow Mode (白名单)",
                            description: "只允许特定 App，屏蔽所有其他",
                            code: """
// 用户选择了允许使用的 App
let allowedApps = profile.selectedActivity.applicationTokens

// Allow Mode: 屏蔽所有，除了这些
store.shield.applicationCategories = .all(except: allowedApps)

// ⚠️ 注意: Allow Mode 下系统会展开类别
// 可能导致超出 50 个 App 的限制
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 严格模式",
                            description: "防止用户通过卸载 App 绕过屏蔽",
                            code: """
// 开启严格模式
store.application.denyAppRemoval = true

// 用户尝试删除 App 时会被阻止
// 需要先解除屏蔽才能卸载

// 解除时记得关闭
store.application.denyAppRemoval = false
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景4: 完全清除",
                            description: "会话结束时清除所有限制",
                            code: """
func deactivateRestrictions() {
    // 清除所有屏蔽设置
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    store.shield.webDomainCategories = nil
    
    // 解除卸载限制
    store.application.denyAppRemoval = false
    
    // 清除网页过滤
    store.webContent.blockedByFilter = nil
    
    // 重置所有设置
    store.clearAllSettings()
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("AppBlockerUtil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
            addLog("ManagedSettingsStore: zbAppRestrictions", type: .info)
        }
    }
    
    // MARK: - Actions
    private func simulateActivate() {
        addLog("🔒 模拟激活屏蔽...", type: .info)
        addLog("   → store.shield.applications = [tokens]", type: .info)
        addLog("   → store.shield.applicationCategories = .specific([...])", type: .info)
        addLog("   → store.shield.webDomains = [tokens]", type: .info)
        addLog("   → store.application.denyAppRemoval = true", type: .info)
        isRestrictionActive = true
        addLog("✅ 屏蔽已激活", type: .success)
    }
    
    private func simulateDeactivate() {
        addLog("🔓 模拟解除屏蔽...", type: .info)
        addLog("   → store.shield.applications = nil", type: .info)
        addLog("   → store.shield.applicationCategories = nil", type: .info)
        addLog("   → store.application.denyAppRemoval = false", type: .info)
        addLog("   → store.clearAllSettings()", type: .info)
        isRestrictionActive = false
        addLog("✅ 屏蔽已解除", type: .success)
    }
    
    private func explainModes() {
        addLog("📋 Block Mode vs Allow Mode:", type: .info)
        addLog("", type: .info)
        addLog("【Block Mode】", type: .warning)
        addLog("   屏蔽: 用户选择的 App/类别", type: .info)
        addLog("   允许: 其他所有 App", type: .info)
        addLog("   代码: .specific(tokens)", type: .info)
        addLog("", type: .info)
        addLog("【Allow Mode】", type: .success)
        addLog("   屏蔽: 所有 App", type: .info)
        addLog("   允许: 用户选择的 App", type: .info)
        addLog("   代码: .all(except: tokens)", type: .info)
        addLog("", type: .info)
        addLog("⚠️ Allow Mode 注意:", type: .error)
        addLog("   类别会被展开为具体 App", type: .info)
        addLog("   可能超出 50 App 限制", type: .info)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 25 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct APIMapRowView: View {
    let api: String
    let description: String
    let type: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(api)
                .font(.caption.monospaced())
                .foregroundColor(.accentColor)
            HStack {
                Text(description)
                    .font(.caption)
                Spacer()
                Text(type)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        AppBlockerUtilDemoView()
    }
}
