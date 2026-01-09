import Foundation
import SwiftUI

/**
 专注会话数据的统计分析与洞察工具类
 
 # 作用概述
 `ProfileInsightsUtil` 是一个基于 SwiftData 数据模型（`BlockedProfiles`）的分析计算类，用于：
 - **输入**：接收一个 `BlockedProfiles` 实例及可选的日期范围（`startDate`/`endDate`）
 - **输出**：生成会话聚合数据（`ProfileInsightsMetrics`）、每日/每小时趋势数组、连续专注天数等指标
 
 例如，给定某个阻止配置（profile）：
 ```swift
 let profile: BlockedProfiles = ... // 包含多个 BlockedProfileSession
 let util = ProfileInsightsUtil(profile: profile)
 let totalSessions = util.metrics.totalCompletedSessions  // → 15 次
 let avgDuration = util.metrics.averageSessionDuration    // → 3600 秒 (1 小时)
 ```
 
 ---
 
 # 项目内使用场景
 
 ## 1. 作为统计页面的 ViewModel
 
 **目的**：为 `ProfileInsightsView`（专注数据统计页面）提供响应式的指标计算与聚合数据
 
 **相关 UI 流程**：用户在主列表点击某个阻止配置卡片 → 跳转到统计详情页 → 页面通过 `@StateObject` 初始化 `ProfileInsightsUtil` → 自动计算并展示：
 - 专注习惯卡片（连续天数、最长连续）
 - 会话统计卡片（总时长、平均/最长/最短时长、总次数）
 - 休息行为卡片（休息次数、平均休息时长、有/无休息的会话数）
 - 每日趋势图表（会话数/专注时长的折线/柱状图）
 - 每小时热力图（会话开始/结束/休息开始/结束的时段分布）
 
 **代码示例**（从 `ProfileInsightsView.swift` 简化）：
 ```swift
 struct <StatisticsView>: View {
     @StateObject private var viewModel: ProfileInsightsUtil
 
     init(profile: <ProfileModel>) {
         _viewModel = StateObject(wrappedValue: ProfileInsightsUtil(profile: profile))
     }
 
     var body: some View {
         ScrollView {
             // 连续天数卡片
             Text("当前连续: \(viewModel.currentStreakDays()) 天")
             Text("最长连续: \(viewModel.longestStreakDays()) 天")
 
             // 会话指标卡片
             Text("总专注时间: \(viewModel.formattedDuration(viewModel.metrics.totalFocusTime))")
             Text("平均时长: \(viewModel.formattedDuration(viewModel.metrics.averageSessionDuration))")
 
             // 每日趋势图表
             Chart(viewModel.dailyAggregates(days: 14)) { item in
                 BarMark(x: .value("日期", item.date), y: .value("会话数", item.sessionsCount))
             }
 
             // 每小时热力图
             Chart(viewModel.hourlyAggregates(days: 14)) { item in
                 BarMark(x: .value("小时", item.hour), y: .value("会话数", item.sessionsStarted))
             }
         }
     }
 }
 ```
 
 ---
 
 # GitHub 公开仓库常见用法
 
 ## 1. 作为 MVVM 中的 ViewModel（ObservableObject）
 
 **模式描述**：在 SwiftUI 项目中，此类作为"数据 → 视图"的桥梁，负责：
 - 聚合原始数据模型（类似 SwiftData/Core Data 的实体）
 - 通过 `@Published` 属性实时更新 UI
 - 提供格式化方法（如时长转字符串、百分比）供视图直接使用
 
 **示例**（通用化重写自公开仓库模式）：
 ```swift
 class <SessionAnalyticsUtil>: ObservableObject {
     @Published var summaryMetrics: <MetricsStruct>
     private var sessions: [<SessionModel>]
 
     init(sessions: [<SessionModel>]) {
         self.sessions = sessions
         self.summaryMetrics = Self.compute(sessions: sessions)
     }
 
     func refreshWithFilter(from: Date?, to: Date?) {
         let filtered = sessions.filter { /* 日期过滤 */ }
         summaryMetrics = Self.compute(sessions: filtered)
     }
 
     private static func compute(sessions: [<SessionModel>]) -> <MetricsStruct> {
         let total = sessions.reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? 0) }
         let avg = total / Double(sessions.count)
         return <MetricsStruct>(totalTime: total, avgTime: avg, /* ... */)
     }
 }
 ```
 
 ## 2. 时间序列聚合（按天/按小时分组统计）
 
 **模式描述**：在生产力/健康/追踪类应用中，需要将时间戳数据聚合成"每日汇总"或"每小时热力图"，用于图表展示（如 Swift Charts）。核心逻辑：
 - 使用 `Calendar.startOfDay(for:)` 对日期归一化
 - 使用 `component(.hour, from:)` 提取小时（0-23）
 - 通过字典 `[Date: (count, duration)]` 或 `[Int: (count, duration)]` 累加
 - 最后填充缺失的时间槽（保证连续性，无数据则为 0）
 
 **示例**（通用化重写）：
 ```swift
 func dailySummary(days: Int = 14) -> [<DaySummary>] {
     let calendar = Calendar.current
     let endDate = calendar.startOfDay(for: Date())
     let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
 
     var buckets: [Date: (count: Int, duration: TimeInterval)] = [:]
     for session in sessions {
         let day = calendar.startOfDay(for: session.startTime)
         guard day >= startDate && day <= endDate else { continue }
         let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
         buckets[day, default: (0, 0)] = (buckets[day]!.count + 1, buckets[day]!.duration + duration)
     }
 
     // 填充完整日期范围（避免图表出现断点）
     return (0..<days).compactMap { offset in
         let date = calendar.date(byAdding: .day, value: offset, to: startDate)!
         let (count, duration) = buckets[date] ?? (0, 0)
         return <DaySummary>(date: date, sessionsCount: count, totalDuration: duration)
     }
 }
 ```
 
 ## 3. 连续性计算（Streak / Consistency）
 
 **模式描述**：在习惯追踪应用中，"连续天数"是核心激励指标。算法要点：
 - 从今天开始倒序遍历每日聚合数据
 - 若当天有记录（count > 0）则计数 +1，否则中断
 - 对于"最长连续"，需遍历整个历史并记录峰值
 
 **示例**（通用化重写）：
 ```swift
 func currentStreak() -> Int {
     let dailyData = dailySummary(days: 365).sorted { $0.date > $1.date }
     var streak = 0
     var expected = Calendar.current.startOfDay(for: Date())
 
     for item in dailyData where Calendar.current.isDate(item.date, inSameDayAs: expected) {
         if item.sessionsCount > 0 {
             streak += 1
             expected = Calendar.current.date(byAdding: .day, value: -1, to: expected)!
         } else {
             break
         }
     }
     return streak
 }
 
 func longestStreak(lookback: Int = 365) -> Int {
     let dailyData = dailySummary(days: lookback).sorted { $0.date < $1.date }
     var maxStreak = 0, current = 0
 
     for item in dailyData {
         current = item.sessionsCount > 0 ? current + 1 : 0
         maxStreak = max(maxStreak, current)
     }
     return maxStreak
 }
 ```
 
 ## 4. 嵌套聚合（Break/Sub-session 统计）
 
 **模式描述**：在专注/冥想/健身应用中，除了主会话（session）外，还可能有"休息"（break）/间歇/组间休息等子事件。需要：
 - 分别统计主事件和子事件的发生时间、时长
 - 计算"包含子事件的主事件占比"
 - 独立生成子事件的每日/每小时聚合
 
 **示例**（通用化重写）：
 ```swift
 struct <MetricsWithBreaks> {
     let totalSessions: Int
     let sessionsWithBreaks: Int
     let averageBreakDuration: TimeInterval?
 }
 
 func computeBreakMetrics() -> <MetricsWithBreaks> {
     let sessionsWithBreak = sessions.filter { $0.breakStartTime != nil }
     let breakDurations = sessionsWithBreak.compactMap { session -> TimeInterval? in
         guard let start = session.breakStartTime, let end = session.breakEndTime else { return nil }
         return end.timeIntervalSince(start)
     }
 
     let avgBreak = breakDurations.isEmpty ? nil : breakDurations.reduce(0, +) / Double(breakDurations.count)
     return <MetricsWithBreaks>(
         totalSessions: sessions.count,
         sessionsWithBreaks: sessionsWithBreak.count,
         averageBreakDuration: avgBreak
     )
 }
 ```
 
 ---
 
 # 注意事项
 
 - **数据源差异**：此类计算的是 SwiftData 持久化的"已完成会话"数据；若需实时监控"当前进行中会话"，需结合 `StrategyManager` 的运行时状态。
 - **日期过滤**：通过 `setDateRange(start:end:)` 可将统计范围限制在指定时间窗口，适用于"本周/上月"等筛选场景。
 - **性能考量**：对于大量会话数据（如数千条记录），每次调用聚合方法都会重新计算；如需优化，可考虑在 `@Published` 中缓存结果，仅在数据变更时刷新。
 - **时区一致性**：所有日期计算使用 `Calendar.current`，确保用户设备时区与数据记录时区一致。
*/

struct ProfileInsightsMetrics {
  let totalCompletedSessions: Int
  let totalFocusTime: TimeInterval
  let averageSessionDuration: TimeInterval?
  let longestSessionDuration: TimeInterval?
  let shortestSessionDuration: TimeInterval?
  // Break metrics
  let totalBreaksTaken: Int
  let averageBreakDuration: TimeInterval?
  let sessionsWithBreaks: Int
  let sessionsWithoutBreaks: Int
}

class ProfileInsightsUtil: ObservableObject {
  @Published var metrics: ProfileInsightsMetrics

  struct DayAggregate: Identifiable {
    let id = UUID()
    let date: Date
    let sessionsCount: Int
    let focusDuration: TimeInterval
  }

  struct HourAggregate: Identifiable, Hashable {
    let id = UUID()
    let hour: Int  // 0-23
    let sessionsStarted: Int
    let averageSessionDuration: TimeInterval?
    let totalFocus: TimeInterval
  }

  struct BreakDayAggregate: Identifiable {
    let id = UUID()
    let date: Date
    let breaksCount: Int
    let totalBreakDuration: TimeInterval
  }

  struct BreakHourAggregate: Identifiable, Hashable {
    let id = UUID()
    let hour: Int  // 0-23
    let breaksStarted: Int
    let averageBreakDuration: TimeInterval?
  }

  struct SessionEndHourAggregate: Identifiable, Hashable {
    let id = UUID()
    let hour: Int  // 0-23
    let sessionsEnded: Int
  }

  struct BreakStartHourAggregate: Identifiable, Hashable {
    let id = UUID()
    let hour: Int  // 0-23
    let breaksStarted: Int
  }

  struct BreakEndHourAggregate: Identifiable, Hashable {
    let id = UUID()
    let hour: Int  // 0-23
    let breaksEnded: Int
  }

  let profile: BlockedProfiles
  private var startDate: Date? = nil
  private var endDate: Date? = nil

  init(profile: BlockedProfiles) {
    self.profile = profile
    self.metrics = Self.computeMetrics(for: profile)
  }

  func setDateRange(start: Date?, end: Date?) {
    self.startDate = start
    self.endDate = end
    refresh()
  }

  func refresh() {
    metrics = Self.computeMetrics(
      for: profile,
      from: startDate,
      to: endDate
    )
  }

  private static func computeMetrics(
    for profile: BlockedProfiles,
    from startDate: Date? = nil,
    to endDate: Date? = nil
  ) -> ProfileInsightsMetrics {
    let completed = profile.sessions.filter { session in
      guard let end = session.endTime else { return false }
      if let startDate = startDate, session.startTime < startDate { return false }
      if let endDate = endDate, end > endDate { return false }
      return true
    }

    let durations: [TimeInterval] = completed.map { session in
      guard let end = session.endTime else { return 0 }
      return end.timeIntervalSince(session.startTime)
    }

    // Breaks: assuming one optional break per session in current model
    let sessionsWithBreaksArray = completed.filter { $0.breakStartTime != nil }
    let sessionsWithBreaks = sessionsWithBreaksArray.count
    let sessionsWithoutBreaks = completed.count - sessionsWithBreaks

    let breakDurations: [TimeInterval] = sessionsWithBreaksArray.compactMap { session in
      guard let start = session.breakStartTime, let end = session.breakEndTime else { return nil }
      return end.timeIntervalSince(start)
    }

    let total = durations.reduce(0, +)
    let count = durations.count
    let average = count > 0 ? total / Double(count) : nil
    let longest = durations.max()
    let shortest = durations.min()
    let totalBreaksTaken = sessionsWithBreaks
    let avgBreak =
      breakDurations.isEmpty ? nil : (breakDurations.reduce(0, +) / Double(breakDurations.count))

    return ProfileInsightsMetrics(
      totalCompletedSessions: count,
      totalFocusTime: total,
      averageSessionDuration: average,
      longestSessionDuration: longest,
      shortestSessionDuration: shortest,
      totalBreaksTaken: totalBreaksTaken,
      averageBreakDuration: avgBreak,
      sessionsWithBreaks: sessionsWithBreaks,
      sessionsWithoutBreaks: sessionsWithoutBreaks
    )
  }

  func formattedDuration(_ interval: TimeInterval?) -> String {
    guard let interval = interval, interval > 0 else { return "—" }
    let totalSeconds = Int(interval)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    }
    if minutes > 0 {
      return "\(minutes)m"
    }
    return "\(seconds)s"
  }

  func formattedPercent(_ value: Double?) -> String {
    guard let value = value else { return "—" }
    let percent = max(0, min(1, value)) * 100
    return String(format: "%.0f%%", percent)
  }

  // MARK: - Aggregations
  func dailyAggregates(days: Int = 14, endingOn end: Date = Date()) -> [DayAggregate] {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else {
      return []
    }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindow = calendar.startOfDay(for: effectiveEnd)

    let completed = profile.sessions.filter { session in
      guard let sessionEnd = session.endTime else { return false }
      return sessionEnd >= startOfWindow
        && sessionEnd <= calendar.date(byAdding: .day, value: 1, to: endOfWindow)!
    }

    var buckets: [Date: (count: Int, duration: TimeInterval)] = [:]
    for session in completed {
      guard let end = session.endTime else { continue }
      let day = calendar.startOfDay(for: end)
      let duration = end.timeIntervalSince(session.startTime)
      let prior = buckets[day] ?? (0, 0)
      buckets[day] = (prior.count + 1, prior.duration + max(0, duration))
    }

    var results: [DayAggregate] = []
    var current = startOfWindow
    while current <= endOfWindow {
      let values = buckets[current] ?? (0, 0)
      results.append(
        DayAggregate(date: current, sessionsCount: values.count, focusDuration: values.duration))
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }

    return results
  }

  // MARK: - Time of Day Aggregations
  func hourlyAggregates(days: Int = 14, endingOn end: Date = Date()) -> [HourAggregate] {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else { return [] }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindowExclusive = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: effectiveEnd))!

    let completed = profile.sessions.filter { session in
      guard let sessionEnd = session.endTime else { return false }
      return sessionEnd >= startOfWindow && sessionEnd < endOfWindowExclusive
    }

    var countsByHour: [Int: Int] = [:]
    var totalsByHour: [Int: TimeInterval] = [:]
    var numByHour: [Int: Int] = [:]

    for session in completed {
      let hour = calendar.component(.hour, from: session.startTime)
      let duration = (session.endTime ?? Date()).timeIntervalSince(session.startTime)
      countsByHour[hour, default: 0] += 1
      totalsByHour[hour, default: 0] += max(0, duration)
      numByHour[hour, default: 0] += 1
    }

    var results: [HourAggregate] = []
    for hour in 0...23 {
      let sessions = countsByHour[hour] ?? 0
      let total = totalsByHour[hour] ?? 0
      let n = numByHour[hour] ?? 0
      let avg = n > 0 ? total / Double(n) : nil
      results.append(
        HourAggregate(
          hour: hour,
          sessionsStarted: sessions,
          averageSessionDuration: avg,
          totalFocus: total
        )
      )
    }

    return results
  }

  func currentStreakDays() -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let aggs = dailyAggregates(days: 365, endingOn: today).sorted { $0.date > $1.date }
    var streak = 0
    var expected = today
    for agg in aggs {
      if calendar.isDate(agg.date, inSameDayAs: expected) {
        if agg.sessionsCount > 0 { streak += 1 } else { break }
        guard let prev = calendar.date(byAdding: .day, value: -1, to: expected) else { break }
        expected = prev
      } else if agg.date < expected {
        break
      }
    }
    return streak
  }

  // MARK: - Habit & Behavior Metrics
  /// Longest streak of consecutive days with at least one completed session (within last N days)
  func longestStreakDays(lookbackDays: Int = 365) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let aggs = dailyAggregates(days: lookbackDays, endingOn: today).sorted { $0.date < $1.date }

    var longest = 0
    var current = 0
    var previousDate: Date? = nil

    for agg in aggs {
      if agg.sessionsCount > 0 {
        if let prev = previousDate,
          calendar.isDate(agg.date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: prev)!)
        {
          current += 1
        } else {
          current = 1
        }
        longest = max(longest, current)
      } else {
        current = 0
      }
      previousDate = agg.date
    }

    return longest
  }

  // MARK: - Break Aggregations
  func breakDailyAggregates(days: Int = 14, endingOn end: Date = Date()) -> [BreakDayAggregate] {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else {
      return []
    }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindow = calendar.startOfDay(for: effectiveEnd)

    let sessionsWithBreaks = profile.sessions.filter { session in
      guard let breakStart = session.breakStartTime else { return false }
      return breakStart >= startOfWindow
        && breakStart <= calendar.date(byAdding: .day, value: 1, to: endOfWindow)!
    }

    var buckets: [Date: (count: Int, totalDuration: TimeInterval)] = [:]
    for session in sessionsWithBreaks {
      guard let breakStart = session.breakStartTime else { continue }
      let day = calendar.startOfDay(for: breakStart)

      var breakDuration: TimeInterval = 0
      if let breakEnd = session.breakEndTime {
        breakDuration = breakEnd.timeIntervalSince(breakStart)
      }

      let prior = buckets[day] ?? (0, 0)
      buckets[day] = (prior.count + 1, prior.totalDuration + breakDuration)
    }

    var results: [BreakDayAggregate] = []
    var current = startOfWindow
    while current <= endOfWindow {
      let values = buckets[current] ?? (0, 0)
      results.append(
        BreakDayAggregate(
          date: current,
          breaksCount: values.count,
          totalBreakDuration: values.totalDuration
        )
      )
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }

    return results
  }

  func breakHourlyAggregates(days: Int = 14, endingOn end: Date = Date()) -> [BreakHourAggregate] {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else { return [] }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindowExclusive = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: effectiveEnd))!

    let sessionsWithBreaks = profile.sessions.filter { session in
      guard let breakStart = session.breakStartTime else { return false }
      return breakStart >= startOfWindow && breakStart < endOfWindowExclusive
    }

    var countsByHour: [Int: Int] = [:]
    var totalsByHour: [Int: TimeInterval] = [:]

    for session in sessionsWithBreaks {
      guard let breakStart = session.breakStartTime else { continue }
      let hour = calendar.component(.hour, from: breakStart)

      var breakDuration: TimeInterval = 0
      if let breakEnd = session.breakEndTime {
        breakDuration = breakEnd.timeIntervalSince(breakStart)
      }

      countsByHour[hour, default: 0] += 1
      totalsByHour[hour, default: 0] += breakDuration
    }

    var results: [BreakHourAggregate] = []
    for hour in 0...23 {
      let breaks = countsByHour[hour] ?? 0
      let total = totalsByHour[hour] ?? 0
      let avg = breaks > 0 ? total / Double(breaks) : nil
      results.append(
        BreakHourAggregate(
          hour: hour,
          breaksStarted: breaks,
          averageBreakDuration: avg
        )
      )
    }

    return results
  }

  func sessionEndHourlyAggregates(days: Int = 14, endingOn end: Date = Date())
    -> [SessionEndHourAggregate]
  {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else { return [] }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindowExclusive = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: effectiveEnd))!

    let completedSessions = profile.sessions.filter { session in
      guard let sessionEnd = session.endTime else { return false }
      return sessionEnd >= startOfWindow && sessionEnd < endOfWindowExclusive
    }

    var countsByHour: [Int: Int] = [:]

    for session in completedSessions {
      guard let sessionEnd = session.endTime else { continue }
      let hour = calendar.component(.hour, from: sessionEnd)
      countsByHour[hour, default: 0] += 1
    }

    var results: [SessionEndHourAggregate] = []
    for hour in 0...23 {
      let sessions = countsByHour[hour] ?? 0
      results.append(
        SessionEndHourAggregate(
          hour: hour,
          sessionsEnded: sessions
        )
      )
    }

    return results
  }

  func breakStartHourlyAggregates(days: Int = 14, endingOn end: Date = Date())
    -> [BreakStartHourAggregate]
  {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else { return [] }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindowExclusive = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: effectiveEnd))!

    let sessionsWithBreaks = profile.sessions.filter { session in
      guard let breakStart = session.breakStartTime else { return false }
      return breakStart >= startOfWindow && breakStart < endOfWindowExclusive
    }

    var countsByHour: [Int: Int] = [:]

    for session in sessionsWithBreaks {
      guard let breakStart = session.breakStartTime else { continue }
      let hour = calendar.component(.hour, from: breakStart)
      countsByHour[hour, default: 0] += 1
    }

    var results: [BreakStartHourAggregate] = []
    for hour in 0...23 {
      let breaks = countsByHour[hour] ?? 0
      results.append(
        BreakStartHourAggregate(
          hour: hour,
          breaksStarted: breaks
        )
      )
    }

    return results
  }

  func breakEndHourlyAggregates(days: Int = 14, endingOn end: Date = Date())
    -> [BreakEndHourAggregate]
  {
    let calendar = Calendar.current
    let effectiveEnd = min(endDate ?? end, end)
    guard
      let windowStart = calendar.date(
        byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: effectiveEnd))
    else { return [] }

    let effectiveStart = max(startDate ?? windowStart, windowStart)
    let startOfWindow = calendar.startOfDay(for: effectiveStart)
    let endOfWindowExclusive = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: effectiveEnd))!

    let sessionsWithCompletedBreaks = profile.sessions.filter { session in
      guard let breakEnd = session.breakEndTime else { return false }
      return breakEnd >= startOfWindow && breakEnd < endOfWindowExclusive
    }

    var countsByHour: [Int: Int] = [:]

    for session in sessionsWithCompletedBreaks {
      guard let breakEnd = session.breakEndTime else { continue }
      let hour = calendar.component(.hour, from: breakEnd)
      countsByHour[hour, default: 0] += 1
    }

    var results: [BreakEndHourAggregate] = []
    for hour in 0...23 {
      let breaks = countsByHour[hour] ?? 0
      results.append(
        BreakEndHourAggregate(
          hour: hour,
          breaksEnded: breaks
        )
      )
    }

    return results
  }
}
