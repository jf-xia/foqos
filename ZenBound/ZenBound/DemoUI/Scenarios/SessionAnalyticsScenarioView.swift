import SwiftUI
import SwiftData
import Charts

/// 场景8: 会话数据分析
/// 统计专注会话数据，展示趋势和洞察
struct SessionAnalyticsScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedProfile: BlockedProfiles?
    @State private var selectedTimeRange: TimeRange = .week
    @State private var insights: ProfileInsightsUtil?
    
    enum TimeRange: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case quarter = "近3月"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    // 模拟数据
    @State private var dailyData: [DailyFocusData] = []
    @State private var hourlyData: [HourlyFocusData] = []
    
    struct DailyFocusData: Identifiable {
        let id = UUID()
        let date: Date
        let focusMinutes: Int
        let sessionsCount: Int
    }
    
    struct HourlyFocusData: Identifiable {
        let id = UUID()
        let hour: Int
        let sessionsStarted: Int
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**会话数据分析**帮助你了解专注习惯，发现改进机会。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "查看每日/每周专注时长")
                        BulletPointView(text: "分析专注高峰时段")
                        BulletPointView(text: "追踪连续专注天数")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "多维度数据统计")
                        BulletPointView(text: "可视化图表展示")
                        BulletPointView(text: "趋势和洞察分析")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "ProfileInsightsUtil",
                            path: "ZenBound/Utils/ProfileInsightsUtil.swift",
                            description: "统计工具 - 核心分析逻辑"
                        )
                        DependencyRowView(
                            name: "ProfileInsightsMetrics",
                            path: "ZenBound/Utils/ProfileInsightsUtil.swift",
                            description: "指标结构 - 统计数据容器"
                        )
                        DependencyRowView(
                            name: "BlockedProfileSession",
                            path: "ZenBound/Models/BlockedProfileSessions.swift",
                            description: "会话记录 - 原始数据来源"
                        )
                        DependencyRowView(
                            name: "dailyAggregates()",
                            path: "ZenBound/Utils/ProfileInsightsUtil.swift",
                            description: "每日汇总 - 按天统计"
                        )
                        DependencyRowView(
                            name: "hourlyAggregates()",
                            path: "ZenBound/Utils/ProfileInsightsUtil.swift",
                            description: "每小时汇总 - 时段分析"
                        )
                    }
                }
                
                // MARK: - 时间范围选择
                DemoSectionView(title: "📅 时间范围", icon: "calendar") {
                    Picker("时间范围", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTimeRange) { _, _ in
                        loadMockData()
                        addLog("📅 切换时间范围: \(selectedTimeRange.rawValue)", type: .info)
                    }
                }
                
                // MARK: - 核心指标
                DemoSectionView(title: "📊 核心指标", icon: "chart.pie") {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            MetricCardView(
                                title: "总专注时长",
                                value: "42.5h",
                                icon: "clock.fill",
                                color: .blue,
                                trend: "+12%"
                            )
                            MetricCardView(
                                title: "完成会话",
                                value: "68",
                                icon: "checkmark.circle.fill",
                                color: .green,
                                trend: "+8"
                            )
                        }
                        
                        HStack(spacing: 12) {
                            MetricCardView(
                                title: "平均时长",
                                value: "37min",
                                icon: "timer",
                                color: .orange,
                                trend: "+5min"
                            )
                            MetricCardView(
                                title: "连续天数",
                                value: "12",
                                icon: "flame.fill",
                                color: .red,
                                trend: "🔥"
                            )
                        }
                    }
                }
                
                // MARK: - 每日专注趋势
                DemoSectionView(title: "📈 每日专注趋势", icon: "chart.xyaxis.line") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !dailyData.isEmpty {
                            Chart(dailyData) { item in
                                BarMark(
                                    x: .value("日期", item.date, unit: .day),
                                    y: .value("分钟", item.focusMinutes)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                        } else {
                            Text("加载中...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                        
                        Text("使用 ProfileInsightsUtil.dailyAggregates() 获取数据")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // MARK: - 时段分布
                DemoSectionView(title: "⏰ 专注时段分布", icon: "chart.bar") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !hourlyData.isEmpty {
                            Chart(hourlyData) { item in
                                BarMark(
                                    x: .value("小时", "\(item.hour):00"),
                                    y: .value("次数", item.sessionsStarted)
                                )
                                .foregroundStyle(Color.purple.gradient)
                            }
                            .frame(height: 150)
                        }
                        
                        HStack {
                            Image(systemName: "sunrise")
                                .foregroundColor(.orange)
                            Text("上午 9-11 点是你的专注高峰期")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        
                        Text("使用 ProfileInsightsUtil.hourlyAggregates() 获取数据")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // MARK: - 休息统计
                DemoSectionView(title: "☕️ 休息统计", icon: "cup.and.saucer") {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            InfoCardView(
                                icon: "cup.and.saucer.fill",
                                title: "总休息次数",
                                value: "45",
                                color: .brown
                            )
                            InfoCardView(
                                icon: "clock.badge.checkmark.fill",
                                title: "平均休息时长",
                                value: "8min",
                                color: .teal
                            )
                        }
                        
                        HStack(spacing: 12) {
                            InfoCardView(
                                icon: "hand.thumbsup.fill",
                                title: "带休息会话",
                                value: "32",
                                color: .green
                            )
                            InfoCardView(
                                icon: "bolt.fill",
                                title: "无休息会话",
                                value: "36",
                                color: .yellow
                            )
                        }
                        
                        Text("使用 breakDailyAggregates() 和 breakHourlyAggregates() 获取数据")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 初始化统计工具",
                            description: "创建 ProfileInsightsUtil 实例",
                            code: """
// 创建统计工具
let insights = ProfileInsightsUtil(profile: profile)

// 设置日期范围 (可选)
insights.setDateRange(
    start: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
    end: Date()
)

// 刷新数据
insights.refresh()
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 获取核心指标",
                            description: "ProfileInsightsMetrics 包含所有统计数据",
                            code: """
let metrics = insights.metrics

// 会话统计
metrics.totalCompletedSessions    // 总完成会话数
metrics.totalFocusTime           // 总专注时长 (秒)
metrics.averageSessionDuration   // 平均会话时长
metrics.longestSessionDuration   // 最长会话
metrics.shortestSessionDuration  // 最短会话

// 休息统计
metrics.totalBreaksTaken         // 总休息次数
metrics.averageBreakDuration     // 平均休息时长
metrics.sessionsWithBreaks       // 带休息的会话数
metrics.sessionsWithoutBreaks    // 无休息的会话数
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 获取每日汇总",
                            description: "用于绘制趋势图表",
                            code: """
// 获取最近7天的每日汇总
let daily = insights.dailyAggregates(days: 7, endingOn: Date())

// 返回: [DayAggregate]
// 每个元素包含:
// - date: Date           // 日期
// - sessionsCount: Int   // 会话数
// - focusDuration: TimeInterval  // 专注时长

// 用于 SwiftUI Charts
Chart(daily) { item in
    BarMark(
        x: .value("日期", item.date, unit: .day),
        y: .value("时长", item.focusDuration / 60)
    )
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 连续天数统计",
                            description: "追踪专注习惯养成",
                            code: """
// 当前连续专注天数
let currentStreak = insights.currentStreakDays()
// 返回: 连续每天都有专注记录的天数

// 历史最长连续天数
let longestStreak = insights.longestStreakDays(lookbackDays: 30)
// 在过去30天内查找最长连续天数

// 格式化时长显示
let formatted = insights.formattedDuration(metrics.totalFocusTime)
// 返回: "2小时35分钟"
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
                            title: "添加目标设置",
                            description: "设置每日/每周专注目标，显示完成进度",
                            relatedFiles: ["ProfileInsightsUtil.swift", "BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "对比分析功能",
                            description: "与上周/上月数据对比，显示进步或退步",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "智能洞察生成",
                            description: "基于数据自动生成改进建议和趋势解读",
                            relatedFiles: ["新建 InsightsGenerator.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "数据导出功能",
                            description: "支持导出CSV或生成PDF报告",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "社交分享",
                            description: "生成精美的统计卡片用于社交分享",
                            relatedFiles: ["新建 ShareCardGenerator.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("会话数据分析")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMockData()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadMockData() {
        addLog("📊 加载统计数据", type: .info)
        addLog("🔄 ProfileInsightsUtil.dailyAggregates()", type: .success)
        addLog("🔄 ProfileInsightsUtil.hourlyAggregates()", type: .success)
        
        // 生成模拟的每日数据
        let calendar = Calendar.current
        dailyData = (0..<selectedTimeRange.days).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            return DailyFocusData(
                date: date,
                focusMinutes: Int.random(in: 30...180),
                sessionsCount: Int.random(in: 1...6)
            )
        }.reversed()
        
        // 生成模拟的小时数据
        hourlyData = (6...22).map { hour in
            HourlyFocusData(
                hour: hour,
                sessionsStarted: hour >= 9 && hour <= 11 ? Int.random(in: 5...10) : Int.random(in: 0...4)
            )
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Metric Card View
struct MetricCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        SessionAnalyticsScenarioView()
    }
}
