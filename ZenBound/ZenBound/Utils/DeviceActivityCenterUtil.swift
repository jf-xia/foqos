import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

/**
 设备活动监控中心工具类 (DeviceActivityCenter Wrapper)
 
 ## 1. 作用
 本工具类封装了 `DeviceActivity` 框架中的 `DeviceActivityCenter`，负责管理和调度所有的“设备活动监控”任务。
 它是 App 主程序与 `DeviceActivityMonitorExtension` 之间的桥梁：
 - **注册监控**：在此处定义时间表（Schedule），告诉系统何时“唤醒”Extension。
 - **触发回调**：当设定的时间到达时，系统会在后台启动 Extension 并回调 `intervalDidStart` / `intervalDidEnd`，从而实现屏蔽逻辑的自动开关。
 
 核心功能包括：
 - **定时屏蔽计划 (Schedule)**：处理按天重复的自动屏蔽（如“每晚 10 点到早 6 点”）。
 - **一次性倒计时 (One-shot Timer)**：处理“休息 5 分钟”或“专注 25 分钟”等临时策略。
 
 ## 2. 项目内使用方式
 主要在以下场景调用：
 - **配置屏蔽方案时**：用户在“屏蔽配置页”保存或更新 Schedule 时，调用此工具重新注册监控。
 - **开启专注策略时**：当用户使用 NFC/扫码/快捷指令/倒计时 开启一次性专注会话时，注册监控来控制结束时间。
 - **进入/结束休息时**：在策略执行期间，如果用户申请临时休息，会注册一个短期的监控任务。
 
 ## 3. 项目内代码示例
 
 ### 场景 1：保存屏蔽计划 (BlockedProfileView)
 当用户在界面上编辑并保存了一个重复性的屏蔽计划：
 ```swift
 func saveProfile(_ profile: BlockedProfiles) {
     if let schedule = profile.schedule, schedule.isActive {
         // 注册每日重复的监控任务
         DeviceActivityCenterUtil.scheduleTimerActivity(for: profile)
     } else {
         // 如果关闭了计划，移除监控
         DeviceActivityCenterUtil.removeScheduleTimerActivities(for: profile)
     }
 }
 ```
 
 ### 场景 2：开启一次性专注会话 (StrategyManager)
 当用户开始一个 25 分钟的番茄钟或 NFC 专注：
 ```swift
 func startFocusSession(for profile: BlockedProfiles) {
     // 内部解析 profile.strategyData 获取时长，并注册一次性监控
     // 监控开始 -> EXTENSION 收到 intervalDidStart -> 开启屏蔽
     // 监控结束 -> EXTENSION 收到 intervalDidEnd -> 关闭屏蔽
     DeviceActivityCenterUtil.startStrategyTimerActivity(for: profile)
 }
 ```
 
 ### 场景 3：临时休息 (StrategyManager)
 用户在专注过程中点击“休息 5 分钟”：
 ```swift
 func startBreak(for profile: BlockedProfiles) {
     // 注册一个 5 分钟后触发 intervalDidEnd 的一次性监控
     DeviceActivityCenterUtil.startBreakTimerActivity(for: profile)
 }
 ```
 
 **注意**：本项目 (ZenBound) 采用了类似“Manager 封装”的模式，但在 `DeviceActivityCenterUtil` 中使用了静态方法而非单例，并且针对 `BlockedProfile` 动态生成了 UUID 相关的 Activity Name，这是为了支持用户创建无限多个自定义的屏蔽配置，比单纯的静态枚举更灵活。
 */
class DeviceActivityCenterUtil {
  // MARK: - Schedule (daily repeating)
  static func scheduleTimerActivity(for profile: BlockedProfiles) {
    // Only schedule if the schedule is active
    guard let schedule = profile.schedule else { return }

    let center = DeviceActivityCenter()
    let scheduleTimerActivity = ScheduleTimerActivity()
    let deviceActivityName = scheduleTimerActivity.getDeviceActivityName(
      from: profile.id.uuidString)

    // If the schedule is not active, remove any existing schedule
    if !schedule.isActive {
      stopActivities(for: [deviceActivityName], with: center)
      return
    }

    // Build repeating schedule from BlockedProfileSchedule
    let (intervalStart, intervalEnd) = scheduleTimerActivity.getScheduleInterval(from: schedule)
    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true,
    )

    do {
      // Remove any existing schedule and create a new one
      stopActivities(for: [deviceActivityName], with: center)
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled restrictions from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start monitoring: \(error.localizedDescription)")
    }
  }

  // MARK: - Break timer (one-shot)
  static func startBreakTimerActivity(for profile: BlockedProfiles) {
    let center = DeviceActivityCenter()
    let breakTimerActivity = BreakTimerActivity()
    let deviceActivityName = breakTimerActivity.getDeviceActivityName(from: profile.id.uuidString)

    let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
      from: profile.breakTimeInMinutes)
    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false,
    )

    do {
      // Remove any existing schedule and create a new one
      stopActivities(for: [deviceActivityName], with: center)
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled break timer activity from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start break timer activity: \(error.localizedDescription)")
    }
  }

  // MARK: - Strategy timer (one-shot, duration from strategyData)
  static func startStrategyTimerActivity(for profile: BlockedProfiles) {
    guard let strategyData = profile.strategyData else {
      print("No strategy data found for profile: \(profile.id.uuidString)")
      return
    }
    let timerData = StrategyTimerData.toStrategyTimerData(from: strategyData)

    let center = DeviceActivityCenter()
    let strategyTimerActivity = StrategyTimerActivity()
    let deviceActivityName = strategyTimerActivity.getDeviceActivityName(
      from: profile.id.uuidString)

    let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
      from: timerData.durationInMinutes)

    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false,
    )

    do {
      // Remove any existing activity and create a new one
      stopActivities(for: [deviceActivityName], with: center)
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled strategy timer activity from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start strategy timer activity: \(error.localizedDescription)")
    }
  }

  static func removeScheduleTimerActivities(for profile: BlockedProfiles) {
    let scheduleTimerActivity = ScheduleTimerActivity()
    let deviceActivityName = scheduleTimerActivity.getDeviceActivityName(
      from: profile.id.uuidString)
    stopActivities(for: [deviceActivityName])
  }

  static func removeScheduleTimerActivities(for activity: DeviceActivityName) {
    stopActivities(for: [activity])
  }

  static func removeAllBreakTimerActivities() {
    let center = DeviceActivityCenter()
    let activities = center.activities
    let breakTimerActivity = BreakTimerActivity()
    let breakTimerActivities = breakTimerActivity.getAllBreakTimerActivities(from: activities)
    stopActivities(for: breakTimerActivities, with: center)
  }

  static func removeBreakTimerActivity(for profile: BlockedProfiles) {
    let breakTimerActivity = BreakTimerActivity()
    let deviceActivityName = breakTimerActivity.getDeviceActivityName(from: profile.id.uuidString)
    stopActivities(for: [deviceActivityName])
  }

  static func removeAllStrategyTimerActivities() {
    let center = DeviceActivityCenter()
    let activities = center.activities
    let strategyTimerActivity = StrategyTimerActivity()
    let strategyTimerActivities = strategyTimerActivity.getAllStrategyTimerActivities(
      from: activities)
    stopActivities(for: strategyTimerActivities, with: center)
  }

  static func getActiveScheduleTimerActivity(for profile: BlockedProfiles) -> DeviceActivityName? {
    let center = DeviceActivityCenter()
    let scheduleTimerActivity = ScheduleTimerActivity()
    let activities = center.activities

    return activities.first(where: {
      $0 == scheduleTimerActivity.getDeviceActivityName(from: profile.id.uuidString)
    })
  }

  static func getDeviceActivities() -> [DeviceActivityName] {
    let center = DeviceActivityCenter()
    return center.activities
  }

  private static func stopActivities(
    for activities: [DeviceActivityName], with center: DeviceActivityCenter? = nil
  ) {
    let center = center ?? DeviceActivityCenter()

    if activities.isEmpty {
      // No activities to stop
      print("No activities to stop")
      return
    }

    center.stopMonitoring(activities)
  }

  private static func getTimeIntervalStartAndEnd(from minutes: Int) -> (
    intervalStart: DateComponents, intervalEnd: DateComponents
  ) {
    let intervalStart = DateComponents(hour: 0, minute: 0)

    // Get current time
    let now = Date()
    let currentComponents = Calendar.current.dateComponents([.hour, .minute], from: now)
    let currentHour = currentComponents.hour ?? 0
    let currentMinute = currentComponents.minute ?? 0

    // Calculate end time by adding minutes to current time
    let totalMinutes = currentMinute + minutes
    var endHour = currentHour + (totalMinutes / 60)
    var endMinute = totalMinutes % 60

    // Cap at 23:59 if it would roll over past midnight
    if endHour >= 24 || (endHour == 23 && endMinute >= 59) {
      endHour = 23
      endMinute = 59
    }

    let intervalEnd = DateComponents(hour: endHour, minute: endMinute)
    return (intervalStart: intervalStart, intervalEnd: intervalEnd)
  }

  // MARK: - Entertainment Group Hourly Limit Monitoring
  
  /// 生成每小时活动名称
  static func entertainmentActivityName(forHour hour: Int) -> DeviceActivityName {
    return DeviceActivityName("entertainment_hour_\(hour)")
  }
  
  /// 生成每小时阈值事件名称
  static func entertainmentThresholdEventName(forHour hour: Int) -> DeviceActivityEvent.Name {
    return DeviceActivityEvent.Name("entertainment_threshold_hour_\(hour)")
  }
  
  /// 生成每小时警告事件名称
  static func entertainmentWarningEventName(forHour hour: Int) -> DeviceActivityEvent.Name {
    return DeviceActivityEvent.Name("entertainment_warning_hour_\(hour)")
  }
  
  /// 获取所有娱乐组活动名称（24小时）
  static var allEntertainmentActivityNames: [DeviceActivityName] {
    return (0..<24).map { entertainmentActivityName(forHour: $0) }
  }
  
  /// 启动娱乐组每小时限制监控
  /// 创建 24 个独立的监控区间（每小时一个），每个区间都有独立的阈值
  /// - Parameters:
  ///   - selection: 选择的App/Categories
  ///   - hourlyLimitMinutes: 每小时限制（分钟），默认15分钟
  static func startEntertainmentHourlyMonitoring(
    selection: FamilyActivitySelection,
    hourlyLimitMinutes: Int = 15
  ) {
    let center = DeviceActivityCenter()
    
    // 停止任何现有的娱乐组监控
    stopEntertainmentMonitoring()
    
    var successCount = 0
    var failCount = 0
    
    // 为每个小时创建独立的监控
    // 每个小时 (hour:00 到 hour:59) 都有独立的 15 分钟阈值
    for hour in 0..<24 {
      let intervalStart = DateComponents(hour: hour, minute: 0, second: 0)
      let intervalEnd = DateComponents(hour: hour, minute: 59, second: 59)
      
      let schedule = DeviceActivitySchedule(
        intervalStart: intervalStart,
        intervalEnd: intervalEnd,
        repeats: true  // 每天重复
      )
      
      // 阈值事件 - 当该小时使用达到限制时触发
      let thresholdEvent = DeviceActivityEvent(
        applications: selection.applicationTokens,
        categories: selection.categoryTokens,
        webDomains: selection.webDomainTokens,
        threshold: DateComponents(minute: hourlyLimitMinutes)
      )
      
      var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
        entertainmentThresholdEventName(forHour: hour): thresholdEvent
      ]
      
      // 警告事件（如果限制大于5分钟）
      if hourlyLimitMinutes > 5 {
        let warningEvent = DeviceActivityEvent(
          applications: selection.applicationTokens,
          categories: selection.categoryTokens,
          webDomains: selection.webDomainTokens,
          threshold: DateComponents(minute: hourlyLimitMinutes - 5)
        )
        events[entertainmentWarningEventName(forHour: hour)] = warningEvent
      }
      
      do {
        try center.startMonitoring(
          entertainmentActivityName(forHour: hour),
          during: schedule,
          events: events
        )
        successCount += 1
      } catch {
        print("❌ Failed to start monitoring for hour \(hour): \(error.localizedDescription)")
        failCount += 1
      }
    }
    
    print("✅ Entertainment hourly monitoring started: \(hourlyLimitMinutes) min/hour limit")
    print("   - Successful hours: \(successCount)/24")
    if failCount > 0 {
      print("   - Failed hours: \(failCount)")
    }
    print("   - Apps: \(selection.applicationTokens.count)")
    print("   - Categories: \(selection.categoryTokens.count)")
    print("   - Websites: \(selection.webDomainTokens.count)")
  }
  
  /// 停止娱乐组监控（停止所有24个小时的监控）
  static func stopEntertainmentMonitoring() {
    let center = DeviceActivityCenter()
    center.stopMonitoring(allEntertainmentActivityNames)
    print("🛑 Entertainment monitoring stopped for all 24 hours")
  }
  
  /// 检查娱乐组监控是否活跃（至少有一个小时的监控在运行）
  static func isEntertainmentMonitoringActive() -> Bool {
    let center = DeviceActivityCenter()
    return allEntertainmentActivityNames.contains { center.activities.contains($0) }
  }
}
