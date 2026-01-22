import SwiftUI
import SwiftData

/// ProfileInsightsUtil Demo - 展示会话统计分析
struct ProfileInsightsUtilDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedProfile: BlockedProfiles?
    @State private var insights: ProfileInsightsUtil?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ProfileInsightsUtil 提供会话数据的统计分析与洞察。")
                        
                        Text("**核心指标 (ProfileInsightsMetrics)：**")
                        BulletPointView(text: "totalCompletedSessions - 已完成会话数")
                        BulletPointView(text: "totalFocusTime - 总专注时间")
                        BulletPointView(text: "averageSessionDuration - 平均时长")
                        BulletPointView(text: "longestSessionDuration - 最长会话")
                        BulletPointView(text: "totalBreaksTaken - 休息次数")
                        
                        Text("**聚合方法：**")
                        BulletPointView(text: "dailyAggregates() - 每日统计")
                        BulletPointView(text: "hourlyAggregates() - 每小时统计")
                        BulletPointView(text: "currentStreakDays() - 当前连续天数")
                        BulletPointView(text: "longestStreakDays() - 最长连续天数")
                    }
                }
                
                // MARK: - 选择配置
                DemoSectionView(title: "📋 选择配置", icon: "person.crop.rectangle.stack") {
                    if profiles.isEmpty {
                        Text("请先在 BlockedProfiles Demo 中创建配置")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(profiles) { profile in
                            Button {
                                selectProfile(profile)
                            } label: {
                                HStack {
                                    Text(profile.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(profile.sessions.count) 会话")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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
                
                // MARK: - 统计指标
                if let insights = insights {
                    DemoSectionView(title: "📊 统计指标", icon: "chart.bar.xaxis") {
                        let metrics = insights.metrics
                        VStack(alignment: .leading, spacing: 12) {
                            MetricRowView(
                                label: "已完成会话",
                                value: "\(metrics.totalCompletedSessions)",
                                icon: "checkmark.circle"
                            )
                            MetricRowView(
                                label: "总专注时间",
                                value: insights.formattedDuration(metrics.totalFocusTime),
                                icon: "clock"
                            )
                            MetricRowView(
                                label: "平均时长",
                                value: insights.formattedDuration(metrics.averageSessionDuration),
                                icon: "chart.line.uptrend.xyaxis"
                            )
                            MetricRowView(
                                label: "最长会话",
                                value: insights.formattedDuration(metrics.longestSessionDuration),
                                icon: "arrow.up.right"
                            )
                            MetricRowView(
                                label: "最短会话",
                                value: insights.formattedDuration(metrics.shortestSessionDuration),
                                icon: "arrow.down.right"
                            )
                            
                            Divider()
                            
                            MetricRowView(
                                label: "休息次数",
                                value: "\(metrics.totalBreaksTaken)",
                                icon: "cup.and.saucer"
                            )
                            MetricRowView(
                                label: "平均休息时长",
                                value: insights.formattedDuration(metrics.averageBreakDuration),
                                icon: "clock.badge.checkmark"
                            )
                            MetricRowView(
                                label: "有休息的会话",
                                value: "\(metrics.sessionsWithBreaks)",
                                icon: "checkmark"
                            )
                            MetricRowView(
                                label: "无休息的会话",
                                value: "\(metrics.sessionsWithoutBreaks)",
                                icon: "xmark"
                            )
                        }
                    }
                    
                    // MARK: - 连续天数
                    DemoSectionView(title: "🔥 连续性", icon: "flame") {
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(insights.currentStreakDays())")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.orange)
                                Text("当前连续")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            
                            VStack {
                                Text("\(insights.longestStreakDays())")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.purple)
                                Text("最长连续")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            generateDailyAggregates()
                        } label: {
                            Label("生成每日聚合 (14天)", systemImage: "calendar")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(insights == nil)
                        
                        Button {
                            generateHourlyAggregates()
                        } label: {
                            Label("生成每小时聚合", systemImage: "clock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(insights == nil)
                        
                        Button {
                            generateBreakAggregates()
                        } label: {
                            Label("生成休息统计", systemImage: "cup.and.saucer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(insights == nil)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 统计页面展示",
                            description: "展示用户的专注数据仪表板",
                            code: """
struct StatisticsView: View {
    @StateObject var insights: ProfileInsightsUtil
    
    init(profile: BlockedProfiles) {
        _insights = StateObject(
            wrappedValue: ProfileInsightsUtil(profile: profile)
        )
    }
    
    var body: some View {
        VStack {
            Text("总专注: \\(insights.formattedDuration(insights.metrics.totalFocusTime))")
            Text("连续: \\(insights.currentStreakDays()) 天")
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 每日趋势图表",
                            description: "使用 Swift Charts 展示趋势",
                            code: """
import Charts

struct DailyTrendChart: View {
    let insights: ProfileInsightsUtil
    
    var body: some View {
        Chart(insights.dailyAggregates(days: 14)) { item in
            BarMark(
                x: .value("日期", item.date),
                y: .value("会话数", item.sessionsCount)
            )
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 日期范围过滤",
                            description: "只统计特定时间段的数据",
                            code: """
// 只统计本周
let insights = ProfileInsightsUtil(profile: profile)
let weekStart = Calendar.current.date(
    from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
)!
insights.setDateRange(start: weekStart, end: Date())
insights.refresh()

// 指标现在只反映本周数据
print(insights.metrics.totalCompletedSessions)
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("ProfileInsightsUtil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
            if let first = profiles.first {
                selectProfile(first)
            }
        }
    }
    
    // MARK: - Actions
    private func selectProfile(_ profile: BlockedProfiles) {
        selectedProfile = profile
        insights = ProfileInsightsUtil(profile: profile)
        addLog("✅ 选中配置: \(profile.name)", type: .success)
        addLog("   会话数: \(profile.sessions.count)", type: .info)
        if let metrics = insights?.metrics {
            addLog("   总专注: \(insights?.formattedDuration(metrics.totalFocusTime) ?? "—")", type: .info)
        }
    }
    
    private func generateDailyAggregates() {
        guard let insights = insights else { return }
        let aggregates = insights.dailyAggregates(days: 14)
        addLog("📅 每日聚合 (最近14天):", type: .info)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        
        for agg in aggregates.suffix(7) {
            let duration = insights.formattedDuration(agg.focusDuration)
            addLog("   \(formatter.string(from: agg.date)): \(agg.sessionsCount) 会话, \(duration)", type: .info)
        }
    }
    
    private func generateHourlyAggregates() {
        guard let insights = insights else { return }
        let aggregates = insights.hourlyAggregates(days: 14)
        addLog("⏰ 每小时聚合:", type: .info)
        
        let activeHours = aggregates.filter { $0.sessionsStarted > 0 }
        if activeHours.isEmpty {
            addLog("   暂无数据", type: .warning)
        } else {
            for agg in activeHours {
                addLog("   \(agg.hour):00 - \(agg.sessionsStarted) 会话开始", type: .info)
            }
        }
    }
    
    private func generateBreakAggregates() {
        guard let insights = insights else { return }
        let aggregates = insights.breakDailyAggregates(days: 14)
        addLog("☕ 休息统计 (最近14天):", type: .info)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        
        let withBreaks = aggregates.filter { $0.breaksCount > 0 }
        if withBreaks.isEmpty {
            addLog("   暂无休息数据", type: .warning)
        } else {
            for agg in withBreaks {
                let duration = insights.formattedDuration(agg.totalBreakDuration)
                addLog("   \(formatter.string(from: agg.date)): \(agg.breaksCount) 次休息, \(duration)", type: .info)
            }
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 25 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct MetricRowView: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
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
        ProfileInsightsUtilDemoView()
    }
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}
