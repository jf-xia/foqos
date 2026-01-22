import SwiftUI
import SwiftData

/// BlockedProfileSessions Demo - 展示会话管理操作
struct BlockedProfileSessionsDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    @Query(sort: \BlockedProfileSession.startTime, order: .reverse) 
    private var sessions: [BlockedProfileSession]
    
    @State private var logMessages: [LogMessage] = []
    @State private var activeSession: BlockedProfileSession?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BlockedProfileSession 记录每次专注会话的完整生命周期。")
                        
                        Text("**主要属性：**")
                        BulletPointView(text: "startTime/endTime - 会话开始和结束时间")
                        BulletPointView(text: "breakStartTime/breakEndTime - 休息时间")
                        BulletPointView(text: "forceStarted - 是否强制启动")
                        BulletPointView(text: "isActive - 会话是否进行中")
                        BulletPointView(text: "duration - 计算属性，会话时长")
                        
                        Text("**核心方法：**")
                        BulletPointView(text: "createSession() - 创建新会话")
                        BulletPointView(text: "startBreak()/endBreak() - 休息管理")
                        BulletPointView(text: "endSession() - 结束会话")
                        BulletPointView(text: "toSnapshot() - 转换为可共享快照")
                    }
                }
                
                // MARK: - 活动会话状态
                DemoSectionView(title: "🟢 活动会话", icon: "play.circle.fill") {
                    if let session = activeSession ?? sessions.first(where: { $0.isActive }) {
                        ActiveSessionCardView(session: session)
                    } else {
                        Text("当前无活动会话")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        if profiles.isEmpty {
                            Text("请先在 BlockedProfiles Demo 中创建配置")
                                .foregroundStyle(.secondary)
                        } else {
                            if activeSession == nil {
                                Button {
                                    createSession()
                                } label: {
                                    Label("开始新会话", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            } else {
                                HStack(spacing: 12) {
                                    Button {
                                        toggleBreak()
                                    } label: {
                                        Label(
                                            activeSession?.isBreakActive == true ? "结束休息" : "开始休息",
                                            systemImage: "cup.and.saucer"
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button {
                                        endSession()
                                    } label: {
                                        Label("结束会话", systemImage: "stop.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            fetchRecentSessions()
                        } label: {
                            Label("查询最近会话", systemImage: "clock.arrow.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 历史会话列表
                DemoSectionView(title: "📜 历史会话", icon: "list.bullet.rectangle") {
                    let inactiveSessions = sessions.filter { !$0.isActive }.prefix(5)
                    if inactiveSessions.isEmpty {
                        Text("暂无历史会话")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(Array(inactiveSessions)) { session in
                            SessionRowView(session: session)
                        }
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 开始专注会话",
                            description: "用户点击开始按钮，创建新的专注会话",
                            code: """
let session = BlockedProfileSession.createSession(
    in: context,
    withTag: "ManualBlockingStrategy",
    withProfile: profile
)
// session.isActive == true
// session.startTime == Date()
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 临时休息",
                            description: "专注过程中用户需要暂时离开",
                            code: """
// 开始休息
session.startBreak()
// breakStartTime 被设置
// SharedData 同步更新

// 休息结束
session.endBreak()
// breakEndTime 被设置
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 从快照恢复会话",
                            description: "Extension 通过 SharedData 同步会话状态",
                            code: """
// Extension 中读取快照
let snapshot = SharedData.getActiveSharedSession()

// 主 App 中恢复
BlockedProfileSession.upsertSessionFromSnapshot(
    in: context,
    withSnapshot: snapshot
)
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("BlockedProfileSessions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            activeSession = sessions.first(where: { $0.isActive })
            addLog("页面加载，当前有 \(sessions.count) 个会话", type: .info)
        }
    }
    
    // MARK: - Actions
    private func createSession() {
        guard let profile = profiles.first else {
            addLog("❌ 请先创建一个配置", type: .error)
            return
        }
        
        let session = BlockedProfileSession.createSession(
            in: modelContext,
            withTag: profile.blockingStrategyId ?? "ManualBlockingStrategy",
            withProfile: profile
        )
        
        activeSession = session
        addLog("✅ 会话已开始: \(session.id.prefix(8))...", type: .success)
        addLog("   配置: \(profile.name)", type: .info)
        addLog("   开始时间: \(formatTime(session.startTime))", type: .info)
    }
    
    private func toggleBreak() {
        guard let session = activeSession else { return }
        
        if session.isBreakActive {
            session.endBreak()
            addLog("☕ 休息结束", type: .info)
            if let breakEnd = session.breakEndTime, let breakStart = session.breakStartTime {
                let duration = breakEnd.timeIntervalSince(breakStart)
                addLog("   休息时长: \(formatDuration(duration))", type: .info)
            }
        } else {
            session.startBreak()
            addLog("☕ 开始休息", type: .warning)
            addLog("   休息开始: \(formatTime(session.breakStartTime ?? Date()))", type: .info)
        }
    }
    
    private func endSession() {
        guard let session = activeSession else { return }
        
        session.endSession()
        addLog("🏁 会话已结束", type: .success)
        addLog("   总时长: \(formatDuration(session.duration))", type: .info)
        
        activeSession = nil
        try? modelContext.save()
    }
    
    private func fetchRecentSessions() {
        let recent = BlockedProfileSession.recentInactiveSessions(in: modelContext, limit: 5)
        addLog("📊 最近 \(recent.count) 个已完成会话:", type: .info)
        for session in recent {
            addLog("   - \(formatTime(session.startTime)) | \(formatDuration(session.duration))", type: .info)
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return "\(minutes)分\(seconds)秒"
    }
}

// MARK: - Supporting Views
struct ActiveSessionCardView: View {
    let session: BlockedProfileSession
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(session.isBreakActive ? .orange : .green)
                    .frame(width: 12, height: 12)
                Text(session.isBreakActive ? "休息中" : "专注中")
                    .font(.headline)
                Spacer()
                Text(formatElapsed(elapsedTime))
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
            }
            
            HStack {
                Label(session.blockedProfile.name, systemImage: "person.crop.rectangle")
                Spacer()
                Text("开始: \(formatTime(session.startTime))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onReceive(timer) { _ in
            elapsedTime = Date().timeIntervalSince(session.startTime)
        }
    }
    
    private func formatElapsed(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct SessionRowView: View {
    let session: BlockedProfileSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.blockedProfile.name)
                    .font(.subheadline)
                HStack {
                    Text(formatDate(session.startTime))
                    if session.breakStartTime != nil {
                        Label("含休息", systemImage: "cup.and.saucer")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formatDuration(session.duration))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes)分钟"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)小时\(remainingMinutes)分"
    }
}

#Preview {
    NavigationStack {
        BlockedProfileSessionsDemoView()
    }
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}
