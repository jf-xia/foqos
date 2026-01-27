import SwiftUI
import SwiftData
import Charts
import FamilyControls

/// 场景8: 会话数据分析
/// 统计专注会话数据，展示趋势和洞察
/// 完整流程：权限检查 → 配置选择 → 数据加载 → 图表分析 → 洞察生成
struct SessionAnalyticsScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    @EnvironmentObject private var strategyManager: StrategyManager
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedProfile: BlockedProfiles?
    @State private var selectedTimeRange: TimeRange = .week
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case profileSelection = 1
        case dataLoading = 2
        case chartAnalysis = 3
        case insights = 4
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .profileSelection: return "选择配置"
            case .dataLoading: return "加载数据"
            case .chartAnalysis: return "图表分析"
            case .insights: return "洞察生成"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "checkmark.shield"
            case .profileSelection: return "folder"
            case .dataLoading: return "arrow.down.circle"
            case .chartAnalysis: return "chart.bar"
            case .insights: return "lightbulb"
            }
        }
    }
    
    @State private var currentStep: ConfigurationStep = .authorization
    
    // MARK: - 权限状态
    @State private var authorizationChecked = false
    @State private var isAuthorized = false
    
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
    @State private var isDataLoaded = false
    @State private var isLoadingData = false
    
    // 目标设置
    @State private var dailyGoalMinutes = 120
    @State private var weeklyGoalHours = 10
    @State private var showGoalSettings = false
    
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
                // MARK: - 流程步骤指示器
                StepProgressView(
                    steps: ConfigurationStep.allCases.map { ($0.icon, $0.title) },
                    currentStep: currentStep.rawValue
                )
                .padding(.horizontal)
                
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**会话数据分析**帮助你了解专注习惯，发现改进机会。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "查看每日/每周专注时长")
                        BulletPointView(text: "分析专注高峰时段")
                        BulletPointView(text: "追踪连续专注天数")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "✅ 权限检查 - 确保数据访问")
                        BulletPointView(text: "✅ 配置选择 - 按配置分析数据")
                        BulletPointView(text: "✅ 多维度数据统计")
                        BulletPointView(text: "✅ 可视化图表展示")
                        BulletPointView(text: "✅ 智能洞察和目标追踪")
                        
                        // 当前状态卡片
                        HStack(spacing: 12) {
                            StatusCardView(
                                icon: isAuthorized ? "checkmark.shield.fill" : "shield.slash",
                                title: "权限",
                                value: isAuthorized ? "已授权" : "未授权",
                                color: isAuthorized ? .green : .red
                            )
                            
                            StatusCardView(
                                icon: "folder.fill",
                                title: "配置数",
                                value: "\(profiles.count)个",
                                color: .blue
                            )
                            
                            StatusCardView(
                                icon: isDataLoaded ? "checkmark.circle.fill" : "circle.dashed",
                                title: "数据",
                                value: isDataLoaded ? "已加载" : "未加载",
                                color: isDataLoaded ? .green : .gray
                            )
                        }
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
                
                // MARK: - Step 1: 权限检查
                DemoSectionView(title: "🔐 Step 1: 权限检查", icon: "checkmark.shield") {
                    AuthorizationCheckSectionView(
                        isAuthorized: isAuthorized,
                        authorizationChecked: authorizationChecked,
                        onCheckAuthorization: checkAuthorization,
                        onRequestAuthorization: requestAuthorization,
                        logMessages: logMessages
                    )
                }
                
                // MARK: - Step 2: 配置选择
                DemoSectionView(title: "📁 Step 2: 选择配置", icon: "folder") {
                    VStack(spacing: 12) {
                        if profiles.isEmpty {
                            EmptyStateView(
                                icon: "folder.badge.questionmark",
                                title: "暂无配置",
                                message: "请先创建一个屏蔽配置来收集专注数据",
                                action: nil,
                                actionTitle: nil
                            )
                        } else {
                            ForEach(profiles) { profile in
                                ProfileSelectionRow(
                                    profile: profile,
                                    isSelected: selectedProfile?.id == profile.id,
                                    onSelect: {
                                        selectedProfile = profile
                                        addLog("📁 已选择配置: \(profile.name)", type: .success)
                                        currentStep = .dataLoading
                                    }
                                )
                            }
                        }
                        
                        // 模拟配置（用于测试）
                        if profiles.isEmpty {
                            Button {
                                addLog("📁 使用模拟数据进行演示", type: .info)
                                currentStep = .dataLoading
                            } label: {
                                Label("使用模拟数据", systemImage: "wand.and.stars")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // MARK: - Step 3: 数据加载与时间范围
                DemoSectionView(title: "📅 Step 3: 时间范围", icon: "calendar") {
                    VStack(spacing: 12) {
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
                        
                        Button {
                            loadDataWithAnimation()
                        } label: {
                            HStack {
                                if isLoadingData {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(isLoadingData ? "加载中..." : "刷新数据")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoadingData)
                        
                        if isDataLoaded {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("数据已加载，共 \(dailyData.count) 天记录")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // MARK: - Step 4: 核心指标
                DemoSectionView(title: "📊 Step 4: 核心指标", icon: "chart.pie") {
                    VStack(spacing: 12) {
                        // 目标进度
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("今日目标进度")
                                    .font(.subheadline.bold())
                                Spacer()
                                Button {
                                    showGoalSettings.toggle()
                                } label: {
                                    Image(systemName: "gearshape")
                                        .font(.caption)
                                }
                            }
                            
                            let todayMinutes = dailyData.first?.focusMinutes ?? 0
                            let progress = min(1.0, Double(todayMinutes) / Double(dailyGoalMinutes))
                            
                            VStack(spacing: 4) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color(.systemGray5))
                                            .frame(height: 12)
                                        
                                        Rectangle()
                                            .fill(progress >= 1.0 ? Color.green : Color.blue)
                                            .frame(width: geometry.size.width * progress, height: 12)
                                            .animation(.easeInOut, value: progress)
                                    }
                                    .cornerRadius(6)
                                }
                                .frame(height: 12)
                                
                                HStack {
                                    Text("\(todayMinutes)分钟 / \(dailyGoalMinutes)分钟")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.caption.bold())
                                        .foregroundColor(progress >= 1.0 ? .green : .blue)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        HStack(spacing: 12) {
                            MetricCardView(
                                title: "总专注时长",
                                value: totalFocusTimeFormatted,
                                icon: "clock.fill",
                                color: .blue,
                                trend: "+12%"
                            )
                            MetricCardView(
                                title: "完成会话",
                                value: "\(totalSessionsCount)",
                                icon: "checkmark.circle.fill",
                                color: .green,
                                trend: "+8"
                            )
                        }
                        
                        HStack(spacing: 12) {
                            MetricCardView(
                                title: "平均时长",
                                value: averageSessionDuration,
                                icon: "timer",
                                color: .orange,
                                trend: "+5min"
                            )
                            MetricCardView(
                                title: "连续天数",
                                value: "\(currentStreakDays)",
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
                                .foregroundStyle(
                                    item.focusMinutes >= dailyGoalMinutes 
                                        ? Color.green.gradient 
                                        : Color.blue.gradient
                                )
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisValueLabel {
                                        if let minutes = value.as(Int.self) {
                                            Text("\(minutes)m")
                                        }
                                    }
                                }
                            }
                            
                            // 图例
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)
                                    Text("未达目标")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("已达目标")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("目标: \(dailyGoalMinutes)分钟/天")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        } else {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("点击「刷新数据」加载图表")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
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
                
                // MARK: - Step 5: 智能洞察
                DemoSectionView(title: "💡 Step 5: 智能洞察", icon: "lightbulb") {
                    VStack(spacing: 12) {
                        InsightCardView(
                            type: .positive,
                            title: "专注时长增长",
                            message: "本周比上周专注时长增长了 12%，继续保持！",
                            icon: "arrow.up.right"
                        )
                        
                        InsightCardView(
                            type: .suggestion,
                            title: "最佳专注时段",
                            message: "你在上午 9-11 点专注效率最高，建议安排重要任务在此时段",
                            icon: "clock.arrow.circlepath"
                        )
                        
                        InsightCardView(
                            type: .warning,
                            title: "周末专注不足",
                            message: "周末平均专注时间只有工作日的 40%，可以尝试设定周末目标",
                            icon: "calendar.badge.exclamationmark"
                        )
                        
                        InsightCardView(
                            type: .achievement,
                            title: "连续专注记录",
                            message: "恭喜！你已经连续 \(currentStreakDays) 天保持专注习惯 🎉",
                            icon: "flame.fill"
                        )
                    }
                }
                
                // MARK: - 测试用例
                DemoSectionView(title: "🧪 测试用例", icon: "checkmark.circle") {
                    SessionAnalyticsTestCasesView()
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 改进建议
                DemoSectionView(title: "🔮 改进建议", icon: "wand.and.stars") {
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
        .sheet(isPresented: $showGoalSettings) {
            GoalSettingsSheet(
                dailyGoalMinutes: $dailyGoalMinutes,
                weeklyGoalHours: $weeklyGoalHours
            )
        }
        .onAppear {
            addLog("📊 会话数据分析场景已加载", type: .info)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalFocusTimeFormatted: String {
        let totalMinutes = dailyData.reduce(0) { $0 + $1.focusMinutes }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private var totalSessionsCount: Int {
        dailyData.reduce(0) { $0 + $1.sessionsCount }
    }
    
    private var averageSessionDuration: String {
        guard totalSessionsCount > 0 else { return "0min" }
        let totalMinutes = dailyData.reduce(0) { $0 + $1.focusMinutes }
        let average = totalMinutes / totalSessionsCount
        return "\(average)min"
    }
    
    private var currentStreakDays: Int {
        var streak = 0
        for data in dailyData {
            if data.focusMinutes > 0 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorization() {
        addLog("🔍 检查权限...", type: .info)
        authorizationChecked = true
        
        Task {
            let status = AuthorizationCenter.shared.authorizationStatus
            await MainActor.run {
                isAuthorized = (status == .approved)
                if isAuthorized {
                    addLog("✅ 权限已授权", type: .success)
                    currentStep = .profileSelection
                } else {
                    addLog("⚠️ 权限未授权", type: .warning)
                }
            }
        }
    }
    
    private func requestAuthorization() {
        addLog("📝 请求权限...", type: .info)
        
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    isAuthorized = true
                    addLog("✅ 权限请求成功", type: .success)
                    currentStep = .profileSelection
                }
            } catch {
                await MainActor.run {
                    addLog("❌ 权限请求失败: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }
    
    private func loadDataWithAnimation() {
        isLoadingData = true
        addLog("📊 开始加载数据...", type: .info)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadMockData()
            isLoadingData = false
            isDataLoaded = true
            currentStep = .chartAnalysis
            addLog("✅ 数据加载完成", type: .success)
        }
    }
    
    private func loadMockData() {
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

// MARK: - Profile Selection Row
struct ProfileSelectionRow: View {
    let profile: BlockedProfiles
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text("\(profile.sessions.count) 个会话记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Insight Card View
struct InsightCardView: View {
    enum InsightType {
        case positive, warning, suggestion, achievement
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .suggestion: return .blue
            case .achievement: return .purple
            }
        }
    }
    
    let type: InsightType
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Goal Settings Sheet
struct GoalSettingsSheet: View {
    @Binding var dailyGoalMinutes: Int
    @Binding var weeklyGoalHours: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("每日目标") {
                    Stepper("每日专注: \(dailyGoalMinutes) 分钟",
                            value: $dailyGoalMinutes, in: 30...480, step: 30)
                }
                
                Section("每周目标") {
                    Stepper("每周专注: \(weeklyGoalHours) 小时",
                            value: $weeklyGoalHours, in: 5...60, step: 5)
                }
                
                Section {
                    Text("设置合理的目标可以帮助你保持专注习惯，建议从较低的目标开始逐步提高。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("目标设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Session Analytics Test Cases View
struct SessionAnalyticsTestCasesView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("查看测试用例")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    TestCaseRowView(
                        id: "TC-A001",
                        name: "权限检查",
                        status: .ready,
                        description: "验证权限状态检测和请求流程"
                    )
                    TestCaseRowView(
                        id: "TC-A002",
                        name: "配置选择",
                        status: .ready,
                        description: "验证配置列表显示和选择功能"
                    )
                    TestCaseRowView(
                        id: "TC-A003",
                        name: "数据加载",
                        status: .ready,
                        description: "验证不同时间范围数据加载"
                    )
                    TestCaseRowView(
                        id: "TC-A004",
                        name: "图表渲染",
                        status: .ready,
                        description: "验证每日趋势和时段分布图表显示"
                    )
                    TestCaseRowView(
                        id: "TC-A005",
                        name: "目标进度",
                        status: .ready,
                        description: "验证目标设置和进度计算"
                    )
                    TestCaseRowView(
                        id: "TC-A006",
                        name: "智能洞察",
                        status: .ready,
                        description: "验证洞察卡片显示和内容准确性"
                    )
                    TestCaseRowView(
                        id: "TC-A007",
                        name: "连续天数",
                        status: .ready,
                        description: "验证连续专注天数计算正确"
                    )
                }
            }
        }
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
            .environmentObject(StrategyManager.shared)
    }
}
