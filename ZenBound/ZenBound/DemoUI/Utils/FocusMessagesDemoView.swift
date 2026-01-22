import SwiftUI

/// FocusMessages Demo - 展示专注提示语集合
struct FocusMessagesDemoView: View {
    @State private var logMessages: [LogMessage] = []
    @State private var currentMessage = ""
    @State private var messageHistory: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FocusMessages 提供一组激励性的专注提示语。")
                        
                        Text("**结构：**")
                        BulletPointView(text: "messages - 静态数组，包含 100 条提示语")
                        BulletPointView(text: "getRandomMessage() - 随机获取一条提示")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "屏蔽界面显示")
                        BulletPointView(text: "Widget 展示")
                        BulletPointView(text: "通知内容")
                        BulletPointView(text: "Live Activity 文案")
                    }
                }
                
                // MARK: - 当前消息展示
                DemoSectionView(title: "💬 当前消息", icon: "quote.bubble") {
                    VStack(spacing: 16) {
                        Text(currentMessage.isEmpty ? "点击下方按钮获取" : currentMessage)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                        
                        Button {
                            getRandomMessage()
                        } label: {
                            Label("获取随机消息", systemImage: "shuffle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // MARK: - 消息统计
                DemoSectionView(title: "📊 消息统计", icon: "chart.bar") {
                    VStack(alignment: .leading, spacing: 12) {
                        StatRowView(label: "总消息数", value: "\(FocusMessages.messages.count)")
                        StatRowView(label: "平均长度", value: "\(calculateAverageLength()) 字符")
                        StatRowView(label: "最短消息", value: "\(findShortestMessage().count) 字符")
                        StatRowView(label: "最长消息", value: "\(findLongestMessage().count) 字符")
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            generateMultiple(count: 5)
                        } label: {
                            Label("生成 5 条消息", systemImage: "list.bullet")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            showAllMessages()
                        } label: {
                            Label("显示所有消息 (\(FocusMessages.messages.count))", systemImage: "text.alignleft")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            searchKeyword("focus")
                        } label: {
                            Label("搜索包含 'focus'", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 历史记录
                if !messageHistory.isEmpty {
                    DemoSectionView(title: "📜 历史记录", icon: "clock") {
                        ForEach(Array(messageHistory.enumerated()), id: \.offset) { index, message in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                Text(message)
                                    .font(.caption)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: Shield 界面",
                            description: "App 被屏蔽时显示激励文案",
                            code: """
struct ShieldView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.shield")
            Text("App Blocked")
            Text(FocusMessages.getRandomMessage())
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: Widget",
                            description: "桌面小组件显示专注提示",
                            code: """
struct FocusWidget: Widget {
    func getTimeline(...) {
        let entry = FocusEntry(
            message: FocusMessages.getRandomMessage(),
            date: Date()
        )
        // 每小时更新一次消息
        let timeline = Timeline(
            entries: [entry],
            policy: .after(Date().addingTimeInterval(3600))
        )
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 通知提醒",
                            description: "会话结束后的激励通知",
                            code: """
func sendCompletionNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Great Focus Session!"
    content.body = FocusMessages.getRandomMessage()
    content.sound = .default
    
    let request = UNNotificationRequest(
        identifier: "focus-complete",
        content: content,
        trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("FocusMessages")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentMessage = FocusMessages.getRandomMessage()
            addLog("页面加载，消息总数: \(FocusMessages.messages.count)", type: .info)
        }
    }
    
    // MARK: - Actions
    private func getRandomMessage() {
        currentMessage = FocusMessages.getRandomMessage()
        messageHistory.insert(currentMessage, at: 0)
        if messageHistory.count > 10 {
            messageHistory.removeLast()
        }
        addLog("💬 \(currentMessage)", type: .info)
    }
    
    private func generateMultiple(count: Int) {
        addLog("📋 生成 \(count) 条随机消息:", type: .info)
        for i in 1...count {
            let message = FocusMessages.getRandomMessage()
            addLog("   \(i). \(message)", type: .info)
        }
    }
    
    private func showAllMessages() {
        addLog("📋 所有消息 (前 20 条):", type: .info)
        for (index, message) in FocusMessages.messages.prefix(20).enumerated() {
            addLog("   [\(index + 1)] \(message)", type: .info)
        }
        addLog("   ... 还有 \(FocusMessages.messages.count - 20) 条", type: .info)
    }
    
    private func searchKeyword(_ keyword: String) {
        let matches = FocusMessages.messages.filter { 
            $0.lowercased().contains(keyword.lowercased()) 
        }
        addLog("🔍 搜索 '\(keyword)': 找到 \(matches.count) 条", type: .info)
        for message in matches.prefix(10) {
            addLog("   • \(message)", type: .success)
        }
        if matches.count > 10 {
            addLog("   ... 还有 \(matches.count - 10) 条", type: .info)
        }
    }
    
    private func calculateAverageLength() -> Int {
        let total = FocusMessages.messages.reduce(0) { $0 + $1.count }
        return total / FocusMessages.messages.count
    }
    
    private func findShortestMessage() -> String {
        FocusMessages.messages.min(by: { $0.count < $1.count }) ?? ""
    }
    
    private func findLongestMessage() -> String {
        FocusMessages.messages.max(by: { $0.count < $1.count }) ?? ""
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 30 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct StatRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        FocusMessagesDemoView()
    }
}
