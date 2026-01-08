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
 
 **注意**：本项目 (Foqos) 采用了类似“Manager 封装”的模式，但在 `DeviceActivityCenterUtil` 中使用了静态方法而非单例，并且针对 `BlockedProfile` 动态生成了 UUID 相关的 Activity Name，这是为了支持用户创建无限多个自定义的屏蔽配置，比单纯的静态枚举更灵活。
 */
class DeviceActivityCenterUtil {
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
}
