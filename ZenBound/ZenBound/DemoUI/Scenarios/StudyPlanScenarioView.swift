import SwiftUI
import SwiftData

/// 场景2: 学习计划模式
/// 设置每周学习日程，自动启动屏蔽，追踪学习统计
struct StudyPlanScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var endHour = 17
    @State private var endMinute = 0
    @State private var isScheduleActive = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**学习计划模式**适用于需要规律学习时间的学生和终身学习者。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "学生固定时段学习，自动屏蔽游戏和社交")
                        BulletPointView(text: "备考期间集中复习")
                        BulletPointView(text: "在线课程学习时保持专注")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "按周设置学习日程")
                        BulletPointView(text: "到点自动启动/停止")
                        BulletPointView(text: "累计学习时长统计")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "BlockedProfileSchedule",
                            path: "ZenBound/Models/Schedule.swift",
                            description: "日程配置 - 定义周几和时间段"
                        )
                        DependencyRowView(
                            name: "ScheduleTimerActivity",
                            path: "ZenBound/Models/Timers/ScheduleTimerActivity.swift",
                            description: "日程计时器 - 管理自动启停"
                        )
                        DependencyRowView(
                            name: "DeviceActivityCenterUtil",
                            path: "ZenBound/Utils/DeviceActivityCenterUtil.swift",
                            description: "活动调度 - 系统级定时器"
                        )
                        DependencyRowView(
                            name: "ProfileInsightsUtil",
                            path: "ZenBound/Utils/ProfileInsightsUtil.swift",
                            description: "学习统计 - 时长和趋势分析"
                        )
                        DependencyRowView(
                            name: "Weekday",
                            path: "ZenBound/Models/Schedule.swift",
                            description: "星期枚举 - 周日到周六"
                        )
                    }
                }
                
                // MARK: - 日程配置演示
                DemoSectionView(title: "📅 日程配置", icon: "calendar") {
                    VStack(spacing: 16) {
                        // 选择日期
                        VStack(alignment: .leading, spacing: 8) {
                            Text("学习日:")
                                .font(.subheadline.bold())
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    Button {
                                        toggleDay(day)
                                    } label: {
                                        Text(day.shortLabel)
                                            .font(.caption.bold())
                                            .frame(width: 36, height: 36)
                                            .background(selectedDays.contains(day) ? Color.accentColor : Color(.systemGray5))
                                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                            .cornerRadius(18)
                                    }
                                }
                            }
                        }
                        
                        // 时间段
                        HStack {
                            VStack(alignment: .leading) {
                                Text("开始时间")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Picker("时", selection: $startHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text("\(hour)").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                    
                                    Text(":")
                                    
                                    Picker("分", selection: $startMinute) {
                                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                                            Text(String(format: "%02d", minute)).tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("结束时间")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Picker("时", selection: $endHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text("\(hour)").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                    
                                    Text(":")
                                    
                                    Picker("分", selection: $endMinute) {
                                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                                            Text(String(format: "%02d", minute)).tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                }
                            }
                        }
                        
                        // 日程摘要
                        if !selectedDays.isEmpty {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text(scheduleSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 操作按钮
                        Button {
                            toggleSchedule()
                        } label: {
                            Label(
                                isScheduleActive ? "停用日程" : "启用日程",
                                systemImage: isScheduleActive ? "calendar.badge.minus" : "calendar.badge.plus"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isScheduleActive ? .red : .accentColor)
                    }
                }
                
                // MARK: - 学习统计预览
                DemoSectionView(title: "📊 学习统计预览", icon: "chart.bar") {
                    VStack(spacing: 16) {
                        // 统计卡片
                        HStack(spacing: 12) {
                            InfoCardView(
                                icon: "clock.fill",
                                title: "本周学习",
                                value: "12.5h",
                                color: .blue
                            )
                            InfoCardView(
                                icon: "flame.fill",
                                title: "连续天数",
                                value: "7",
                                color: .orange
                            )
                        }
                        
                        HStack(spacing: 12) {
                            InfoCardView(
                                icon: "target",
                                title: "完成率",
                                value: "85%",
                                color: .green
                            )
                            InfoCardView(
                                icon: "calendar.badge.checkmark",
                                title: "总会话",
                                value: "42",
                                color: .purple
                            )
                        }
                        
                        Text("使用 ProfileInsightsUtil 获取详细统计")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 创建学习日程",
                            description: "使用 BlockedProfileSchedule 定义时间段",
                            code: """
// 创建周一至周五的学习日程
let schedule = BlockedProfileSchedule(
    days: [.monday, .tuesday, .wednesday, .thursday, .friday],
    startHour: 9, startMinute: 0,
    endHour: 17, endMinute: 0,
    updatedAt: Date()
)

// 日程属性
schedule.isActive          // 当前是否在日程时间内
schedule.summaryText       // "周一,周二... 09:00-17:00"
schedule.totalDurationInSeconds  // 每日总时长
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 绑定到配置",
                            description: "将日程关联到屏蔽配置",
                            code: """
// 更新配置的日程
let _ = BlockedProfiles.updateProfile(
    profile, in: context,
    schedule: schedule
)

// 启动日程监控
DeviceActivityCenterUtil.scheduleTimerActivity(for: profile)

// 系统会在日程时间自动触发 intervalDidStart/intervalDidEnd
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 查看学习统计",
                            description: "使用 ProfileInsightsUtil 分析学习数据",
                            code: """
let insights = ProfileInsightsUtil(profile: profile)

// 获取统计指标
insights.metrics.totalFocusTime        // 总学习时长
insights.metrics.averageSessionDuration // 平均每次时长
insights.currentStreakDays()           // 当前连续天数

// 获取每日汇总
let dailyData = insights.dailyAggregates(days: 7, endingOn: Date())
// dailyData: [{date, sessionsCount, focusDuration}, ...]
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
                            title: "添加日程提前提醒",
                            description: "日程开始前5分钟发送通知，让用户做好准备",
                            relatedFiles: ["TimersUtil.swift", "Schedule.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "支持多日程配置",
                            description: "允许同一配置设置多个时间段，如上午和下午分开",
                            relatedFiles: ["Schedule.swift", "BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "添加学习目标设置",
                            description: "设置每周学习时长目标，显示完成进度",
                            relatedFiles: ["ProfileInsightsUtil.swift", "BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "生成学习报告",
                            description: "每周生成学习报告，可分享到社交媒体",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("学习计划模式")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Computed Properties
    
    private var scheduleSummary: String {
        let days = selectedDays.sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortLabel }
            .joined(separator: ", ")
        let start = String(format: "%02d:%02d", startHour, startMinute)
        let end = String(format: "%02d:%02d", endHour, endMinute)
        return "\(days) \(start) - \(end)"
    }
    
    // MARK: - Private Methods
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
            addLog("📅 移除: \(day.name)", type: .info)
        } else {
            selectedDays.insert(day)
            addLog("📅 添加: \(day.name)", type: .info)
        }
    }
    
    private func toggleSchedule() {
        isScheduleActive.toggle()
        
        if isScheduleActive {
            addLog("📅 创建日程配置", type: .info)
            addLog("⏰ \(scheduleSummary)", type: .info)
            addLog("🔄 DeviceActivityCenterUtil.scheduleTimerActivity()", type: .success)
            addLog("✅ 学习日程已启用", type: .success)
        } else {
            addLog("📅 停用日程", type: .info)
            addLog("🔄 DeviceActivityCenterUtil.removeScheduleTimerActivities()", type: .success)
            addLog("✅ 学习日程已停用", type: .warning)
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

#Preview {
    NavigationStack {
        StudyPlanScenarioView()
    }
}
