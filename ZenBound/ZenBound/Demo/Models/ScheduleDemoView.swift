import SwiftUI

/// Schedule Demo - 展示日程安排功能
struct ScheduleDemoView: View {
    @State private var logMessages: [LogMessage] = []
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var endHour = 18
    @State private var endMinute = 0
    
    private var currentSchedule: BlockedProfileSchedule {
        BlockedProfileSchedule(
            days: Array(selectedDays),
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schedule 模块定义了自动屏蔽的日程安排。")
                        
                        Text("**Weekday 枚举：**")
                        BulletPointView(text: "rawValue - 1(周日)到7(周六)")
                        BulletPointView(text: "name - 完整名称 (Monday)")
                        BulletPointView(text: "shortLabel - 短标签 (Mo)")
                        
                        Text("**BlockedProfileSchedule 结构：**")
                        BulletPointView(text: "days - 启用的星期几")
                        BulletPointView(text: "startHour/startMinute - 开始时间")
                        BulletPointView(text: "endHour/endMinute - 结束时间")
                        BulletPointView(text: "isActive - 是否有效")
                        BulletPointView(text: "summaryText - 摘要文本")
                    }
                }
                
                // MARK: - 日期选择器
                DemoSectionView(title: "📅 日期选择", icon: "calendar") {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach(Weekday.allCases, id: \.self) { day in
                                WeekdayButton(
                                    day: day,
                                    isSelected: selectedDays.contains(day),
                                    onTap: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                        logScheduleChange()
                                    }
                                )
                            }
                        }
                        
                        HStack {
                            Text("已选: \(selectedDays.count) 天")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("全选") {
                                selectedDays = Set(Weekday.allCases)
                                logScheduleChange()
                            }
                            .font(.caption)
                            Button("工作日") {
                                selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                                logScheduleChange()
                            }
                            .font(.caption)
                            Button("清空") {
                                selectedDays = []
                                logScheduleChange()
                            }
                            .font(.caption)
                        }
                    }
                }
                
                // MARK: - 时间选择
                DemoSectionView(title: "⏰ 时间范围", icon: "clock") {
                    VStack(spacing: 16) {
                        HStack {
                            Text("开始")
                            Spacer()
                            Picker("小时", selection: $startHour) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            Text(":")
                            Picker("分钟", selection: $startMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("结束")
                            Spacer()
                            Picker("小时", selection: $endHour) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            Text(":")
                            Picker("分钟", selection: $endMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Text("总时长: \(formatDuration(currentSchedule.totalDurationInSeconds))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onChange(of: startHour) { _, _ in logScheduleChange() }
                    .onChange(of: startMinute) { _, _ in logScheduleChange() }
                    .onChange(of: endHour) { _, _ in logScheduleChange() }
                    .onChange(of: endMinute) { _, _ in logScheduleChange() }
                }
                
                // MARK: - 计算结果展示
                DemoSectionView(title: "📊 计算结果", icon: "function") {
                    VStack(alignment: .leading, spacing: 12) {
                        ResultRowView(label: "summaryText", value: currentSchedule.summaryText)
                        ResultRowView(label: "isActive", value: String(currentSchedule.isActive))
                        ResultRowView(label: "isTodayScheduled()", value: String(currentSchedule.isTodayScheduled()))
                        ResultRowView(label: "totalDurationInSeconds", value: "\(currentSchedule.totalDurationInSeconds)")
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            testIsTodayScheduled()
                        } label: {
                            Label("检查今日是否启用", systemImage: "calendar.badge.checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            testOlderThan15Minutes()
                        } label: {
                            Label("检查是否更新超过15分钟", systemImage: "clock.badge.exclamationmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            generateAllWeekdayInfo()
                        } label: {
                            Label("输出所有 Weekday 信息", systemImage: "list.bullet")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 工作日自动屏蔽",
                            description: "周一至周五 9:00-18:00 自动启用屏蔽",
                            code: """
let schedule = BlockedProfileSchedule(
    days: [.monday, .tuesday, .wednesday, 
           .thursday, .friday],
    startHour: 9, startMinute: 0,
    endHour: 18, endMinute: 0
)
// schedule.summaryText → "Mo Tu We Th Fr · 9:00 AM - 6:00 PM"
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 检查当前是否在日程内",
                            description: "DeviceActivityMonitor 回调时检查",
                            code: """
if schedule.isTodayScheduled() {
    // 今天在日程内，开始监控
    appBlocker.activateRestrictions(for: profile)
} else {
    // 今天不在日程内，跳过
    print("Today is not scheduled")
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 防止频繁更新",
                            description: "Schedule 更新后需等待15分钟才生效",
                            code: """
// 防止用户频繁修改日程导致系统误触发
if schedule.olderThan15Minutes() {
    // 可以安全启动
    startScheduledBlocking()
} else {
    // 日程刚更新，等待
    print("Schedule too new, waiting...")
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载，当前日程: \(currentSchedule.summaryText)", type: .info)
        }
    }
    
    // MARK: - Actions
    private func logScheduleChange() {
        addLog("📅 日程已更新: \(currentSchedule.summaryText)", type: .info)
    }
    
    private func testIsTodayScheduled() {
        let today = Calendar.current.component(.weekday, from: Date())
        let todayName = Weekday(rawValue: today)?.name ?? "Unknown"
        
        if currentSchedule.isTodayScheduled() {
            addLog("✅ 今天 (\(todayName)) 在日程内", type: .success)
        } else {
            addLog("❌ 今天 (\(todayName)) 不在日程内", type: .warning)
        }
    }
    
    private func testOlderThan15Minutes() {
        if currentSchedule.olderThan15Minutes() {
            addLog("✅ 日程更新已超过15分钟，可以生效", type: .success)
        } else {
            let elapsed = Date().timeIntervalSince(currentSchedule.updatedAt)
            addLog("⏳ 日程刚更新 \(Int(elapsed))秒，需等待15分钟", type: .warning)
        }
    }
    
    private func generateAllWeekdayInfo() {
        addLog("📋 Weekday 枚举信息:", type: .info)
        for day in Weekday.allCases {
            addLog("   \(day.rawValue): \(day.name) (\(day.shortLabel))", type: .info)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct WeekdayButton: View {
    let day: Weekday
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            Text(day.shortLabel)
                .font(.caption.bold())
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
    }
}

struct ResultRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospaced())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        ScheduleDemoView()
    }
}
