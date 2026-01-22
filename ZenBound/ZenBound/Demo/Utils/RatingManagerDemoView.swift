import SwiftUI

/// RatingManager Demo - 展示评分请求管理
struct RatingManagerDemoView: View {
    @State private var logMessages: [LogMessage] = []
    @State private var simulatedLaunchCount = 0
    @State private var simulatedVersion = "1.0.0"
    @State private var lastPromptedVersion: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RatingManager 管理 App Store 评分请求的时机和频率。")
                        
                        Text("**核心逻辑：**")
                        BulletPointView(text: "追踪启动/交互次数")
                        BulletPointView(text: "达到阈值(3次)时请求评分")
                        BulletPointView(text: "每个版本只请求一次")
                        BulletPointView(text: "使用 SKStoreReviewController")
                        
                        Text("**存储：**")
                        BulletPointView(text: "@AppStorage(\"launchCount\") - 启动次数")
                        BulletPointView(text: "@AppStorage(\"lastVersionPromptedForReview\") - 上次版本")
                    }
                }
                
                // MARK: - 模拟状态
                DemoSectionView(title: "📊 模拟状态", icon: "chart.bar") {
                    VStack(spacing: 16) {
                        HStack {
                            Text("启动次数")
                            Spacer()
                            Stepper("\(simulatedLaunchCount)", value: $simulatedLaunchCount, in: 0...20)
                        }
                        
                        HStack {
                            Text("当前版本")
                            Spacer()
                            Picker("版本", selection: $simulatedVersion) {
                                Text("1.0.0").tag("1.0.0")
                                Text("1.1.0").tag("1.1.0")
                                Text("2.0.0").tag("2.0.0")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        
                        HStack {
                            Text("上次提示版本")
                            Spacer()
                            Text(lastPromptedVersion ?? "无")
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        // 状态判断
                        let shouldPrompt = checkShouldPrompt()
                        HStack {
                            Image(systemName: shouldPrompt ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(shouldPrompt ? .green : .red)
                            Text(shouldPrompt ? "符合评分条件" : "不符合评分条件")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(shouldPrompt ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            incrementLaunchCount()
                        } label: {
                            Label("模拟启动 +1", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            checkAndRequestReview()
                        } label: {
                            Label("检查并请求评分", systemImage: "star.bubble")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            simulateVersionUpgrade()
                        } label: {
                            Label("模拟版本升级", systemImage: "arrow.up.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            resetSimulation()
                        } label: {
                            Label("重置模拟", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 在关键操作后增加计数",
                            description: "用户完成重要操作时增加启动计数",
                            code: """
struct HomeView: View {
    @EnvironmentObject var ratingManager: RatingManager
    
    func onSessionComplete() {
        // 用户完成一次专注会话
        saveSession()
        
        // 增加计数，可能触发评分请求
        ratingManager.incrementLaunchCount()
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 版本感知评分",
                            description: "每个版本只请求一次评分",
                            code: """
private func checkIfShouldRequestReview() {
    let currentVersion = Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String ?? ""
    
    // 条件：版本不同 且 启动次数 >= 3
    guard lastVersionPromptedForReview != currentVersion,
          launchCount >= 3 else { return }
    
    lastVersionPromptedForReview = currentVersion
    requestReview()
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 实际请求评分",
                            description: "使用 StoreKit 请求系统评分弹窗",
                            code: """
private func requestReview() {
    guard let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) 
        as? UIWindowScene else { return }
    
    SKStoreReviewController.requestReview(in: scene)
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("RatingManager")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
            addLog("ℹ️ 这是模拟演示，不会触发真实评分弹窗", type: .warning)
        }
    }
    
    // MARK: - Actions
    private func checkShouldPrompt() -> Bool {
        return lastPromptedVersion != simulatedVersion && simulatedLaunchCount >= 3
    }
    
    private func incrementLaunchCount() {
        simulatedLaunchCount += 1
        addLog("📈 启动次数: \(simulatedLaunchCount)", type: .info)
        
        if checkShouldPrompt() {
            addLog("✅ 达到评分条件！", type: .success)
        } else if simulatedLaunchCount < 3 {
            addLog("   还需 \(3 - simulatedLaunchCount) 次达到阈值", type: .info)
        } else if lastPromptedVersion == simulatedVersion {
            addLog("   当前版本已请求过", type: .warning)
        }
    }
    
    private func checkAndRequestReview() {
        addLog("🔍 检查评分条件...", type: .info)
        addLog("   启动次数: \(simulatedLaunchCount) (阈值: 3)", type: .info)
        addLog("   当前版本: \(simulatedVersion)", type: .info)
        addLog("   上次提示: \(lastPromptedVersion ?? "无")", type: .info)
        
        if checkShouldPrompt() {
            lastPromptedVersion = simulatedVersion
            addLog("⭐ 请求评分!", type: .success)
            addLog("   → SKStoreReviewController.requestReview(in: scene)", type: .info)
            addLog("   → 记录版本: \(simulatedVersion)", type: .info)
        } else if simulatedLaunchCount < 3 {
            addLog("❌ 启动次数不足", type: .error)
        } else {
            addLog("❌ 当前版本已请求过", type: .error)
        }
    }
    
    private func simulateVersionUpgrade() {
        let versions = ["1.0.0", "1.1.0", "2.0.0"]
        if let currentIndex = versions.firstIndex(of: simulatedVersion),
           currentIndex < versions.count - 1 {
            simulatedVersion = versions[currentIndex + 1]
            addLog("⬆️ 版本升级: \(simulatedVersion)", type: .success)
            addLog("   现在可以再次请求评分", type: .info)
        } else {
            addLog("⚠️ 已是最新版本", type: .warning)
        }
    }
    
    private func resetSimulation() {
        simulatedLaunchCount = 0
        simulatedVersion = "1.0.0"
        lastPromptedVersion = nil
        addLog("🔄 重置模拟状态", type: .warning)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }
}

#Preview {
    NavigationStack {
        RatingManagerDemoView()
    }
}
