import SwiftUI

/// SharedData Demo - 展示 App Group 数据共享
struct SharedDataDemoView: View {
    @State private var logMessages: [LogMessage] = []
    @State private var currentSnapshot: SharedData.ProfileSnapshot?
    @State private var currentSession: SharedData.SessionSnapshot?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SharedData 是 App Group 跨进程数据共享的核心模块。")
                        
                        Text("**数据结构：**")
                        BulletPointView(text: "ProfileSnapshot - 配置文件的轻量级快照")
                        BulletPointView(text: "SessionSnapshot - 会话的轻量级快照")
                        
                        Text("**存储位置：**")
                        BulletPointView(text: "UserDefaults(suiteName: \"group.com.zenbound.data\")")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "主App → Extension: 传递配置和会话")
                        BulletPointView(text: "Extension → 主App: 同步会话状态变更")
                        BulletPointView(text: "Widget: 读取当前会话状态")
                    }
                }
                
                // MARK: - 当前状态
                DemoSectionView(title: "📊 当前共享状态", icon: "square.and.arrow.up.on.square") {
                    VStack(spacing: 12) {
                        // Profile Snapshots
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profile Snapshots")
                                .font(.headline)
                            let snapshots = SharedData.profileSnapshots
                            if snapshots.isEmpty {
                                Text("暂无配置快照")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(Array(snapshots.keys), id: \.self) { key in
                                    if let snapshot = snapshots[key] {
                                        HStack {
                                            Text(snapshot.name)
                                            Spacer()
                                            Text("ID: \(key.prefix(8))...")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Active Session
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active Session")
                                .font(.headline)
                            if let session = SharedData.getActiveSharedSession() {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ID: \(session.id.prefix(8))...")
                                    Text("Profile: \(session.blockedProfileId.uuidString.prefix(8))...")
                                    Text("Started: \(formatTime(session.startTime))")
                                    if let breakStart = session.breakStartTime {
                                        Text("Break: \(formatTime(breakStart))")
                                    }
                                }
                                .font(.caption)
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)
                            } else {
                                Text("无活动会话")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            createMockSnapshot()
                        } label: {
                            Label("创建模拟 Profile 快照", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            createMockSession()
                        } label: {
                            Label("创建模拟会话", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        HStack(spacing: 12) {
                            Button {
                                setBreakStart()
                            } label: {
                                Label("开始休息", systemImage: "cup.and.saucer")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                setBreakEnd()
                            } label: {
                                Label("结束休息", systemImage: "arrow.right.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button {
                            endActiveSession()
                        } label: {
                            Label("结束活动会话", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        
                        Divider()
                        
                        Button {
                            readAllData()
                        } label: {
                            Label("读取所有共享数据", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            clearAllData()
                        } label: {
                            Label("清空所有共享数据", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 主App保存配置快照",
                            description: "更新配置后同步到 Extension",
                            code: """
// 保存快照供 Extension 读取
let snapshot = BlockedProfiles.getSnapshot(for: profile)
SharedData.setSnapshot(snapshot, for: profile.id.uuidString)

// Extension 中读取
if let snapshot = SharedData.snapshot(for: profileId) {
    appBlocker.activateRestrictions(for: snapshot)
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: Extension 更新会话状态",
                            description: "DeviceActivityMonitor 在后台更新会话",
                            code: """
// Extension: intervalDidStart 回调
SharedData.createSessionForSchedular(for: profileId)

// Extension: intervalDidEnd 回调
SharedData.endActiveSharedSession()

// 主App: 同步回 SwiftData
if let snapshot = SharedData.getActiveSharedSession() {
    BlockedProfileSession.upsertSessionFromSnapshot(
        in: context, withSnapshot: snapshot
    )
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: Widget 读取状态",
                            description: "Widget 显示当前会话信息",
                            code: """
// Widget Timeline Provider
func getTimeline(...) {
    if let session = SharedData.getActiveSharedSession() {
        // 显示活动会话
        let entry = FocusEntry(
            isActive: true,
            startTime: session.startTime
        )
    } else {
        // 显示空闲状态
        let entry = FocusEntry(isActive: false)
    }
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("SharedData")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
            readAllData()
        }
    }
    
    // MARK: - Actions
    private func createMockSnapshot() {
        let mockId = UUID()
        let snapshot = SharedData.ProfileSnapshot(
            id: mockId,
            name: "Demo Profile \(Int.random(in: 100...999))",
            selectedActivity: .init(),
            createdAt: Date(),
            updatedAt: Date(),
            blockingStrategyId: "ManualBlockingStrategy",
            strategyData: nil,
            order: 0,
            enableLiveActivity: false,
            reminderTimeInSeconds: nil,
            customReminderMessage: nil,
            enableBreaks: true,
            breakTimeInMinutes: 15,
            enableStrictMode: false,
            enableAllowMode: false,
            enableAllowModeDomains: false,
            enableSafariBlocking: true,
            domains: nil,
            physicalUnblockNFCTagId: nil,
            physicalUnblockQRCodeId: nil,
            schedule: nil,
            disableBackgroundStops: false
        )
        
        SharedData.setSnapshot(snapshot, for: mockId.uuidString)
        addLog("✅ 创建 Profile 快照: \(snapshot.name)", type: .success)
        addLog("   ID: \(mockId.uuidString.prefix(8))...", type: .info)
    }
    
    private func createMockSession() {
        let profiles = SharedData.profileSnapshots
        guard let firstProfile = profiles.values.first else {
            addLog("❌ 请先创建 Profile 快照", type: .error)
            return
        }
        
        SharedData.createSessionForSchedular(for: firstProfile.id)
        addLog("✅ 创建会话", type: .success)
        addLog("   Profile: \(firstProfile.name)", type: .info)
    }
    
    private func setBreakStart() {
        guard SharedData.getActiveSharedSession() != nil else {
            addLog("❌ 无活动会话", type: .error)
            return
        }
        SharedData.setBreakStartTime(date: Date())
        addLog("☕ 休息开始: \(formatTime(Date()))", type: .warning)
    }
    
    private func setBreakEnd() {
        guard SharedData.getActiveSharedSession() != nil else {
            addLog("❌ 无活动会话", type: .error)
            return
        }
        SharedData.setBreakEndTime(date: Date())
        addLog("✅ 休息结束: \(formatTime(Date()))", type: .success)
    }
    
    private func endActiveSession() {
        guard SharedData.getActiveSharedSession() != nil else {
            addLog("❌ 无活动会话", type: .error)
            return
        }
        SharedData.endActiveSharedSession()
        addLog("🏁 会话已结束", type: .success)
    }
    
    private func readAllData() {
        let profiles = SharedData.profileSnapshots
        let session = SharedData.getActiveSharedSession()
        let completed = SharedData.getCompletedSessionsForSchedular()
        
        addLog("📊 共享数据统计:", type: .info)
        addLog("   Profile 快照: \(profiles.count) 个", type: .info)
        addLog("   活动会话: \(session != nil ? "是" : "否")", type: .info)
        addLog("   已完成会话: \(completed.count) 个", type: .info)
    }
    
    private func clearAllData() {
        // Clear profile snapshots
        for key in SharedData.profileSnapshots.keys {
            SharedData.removeSnapshot(for: key)
        }
        
        // Clear session
        SharedData.flushActiveSession()
        SharedData.flushCompletedSessionsForSchedular()
        
        addLog("🗑️ 已清空所有共享数据", type: .warning)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
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
        SharedDataDemoView()
    }
}
