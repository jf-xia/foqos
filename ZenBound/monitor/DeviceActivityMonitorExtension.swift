//
//  DeviceActivityMonitorExtension.swift
//  ZenBoundDeviceMonitor
//
//  Created by Ali Waseem on 2025-05-27.
//

import DeviceActivity
import FamilyControls
import ManagedSettings
import OSLog

private let log = Logger(
  subsystem: "com.lxt.ZenBound.monitor",
  category: "DeviceActivity"
)

// MARK: - Contract & Notes
//
// 职责：
// - 响应系统的 DeviceActivity 区间开始/结束事件；
// - 处理娱乐组每小时限制的阈值事件；
// - 协调计时活动（TimerActivityUtil）与 AppBlockerUtil；
// - 不直接访问 SwiftData，仅通过 App Group 快照（SharedData）进行轻量状态传递（如需）。
//
// 约束：
// - 运行时内存/时间受扩展限制，避免复杂计算与长耗时 IO；
// - 所有副作用应幂等（interval 事件可能重复抵达）。
//
// 与主 App 的契约：
// - 主 App 统一通过"状态同步网关"刷写 SharedData 快照、刷新 Widget/Live Activity；
// - 扩展仅消费快照与触发最低限度计时动作，不做业务决策。

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  // 娱乐组专用 ManagedSettingsStore
  private let entertainmentStore = ManagedSettingsStore(
    named: ManagedSettingsStore.Name("EntertainmentGroupRestrictions")
  )
  
  // 通用 Store
  private let store = ManagedSettingsStore()
  
  // 娱乐组活动名称前缀
  private let entertainmentActivityPrefix = "entertainment_hour_"
  private let entertainmentThresholdPrefix = "entertainment_threshold_hour_"
  private let entertainmentWarningPrefix = "entertainment_warning_hour_"
  
  /// 检查活动是否是娱乐组活动
  private func isEntertainmentActivity(_ activity: DeviceActivityName) -> Bool {
    return activity.rawValue.hasPrefix(entertainmentActivityPrefix)
  }
  
  /// 从活动名称中提取小时数
  private func extractHour(from activity: DeviceActivityName) -> Int? {
    let raw = activity.rawValue
    guard raw.hasPrefix(entertainmentActivityPrefix) else { return nil }
    let hourString = raw.dropFirst(entertainmentActivityPrefix.count)
    return Int(hourString)
  }
  
  /// 检查事件是否是娱乐组阈值事件
  private func isEntertainmentThresholdEvent(_ event: DeviceActivityEvent.Name) -> Bool {
    return event.rawValue.hasPrefix(entertainmentThresholdPrefix)
  }
  
  /// 检查事件是否是娱乐组警告事件
  private func isEntertainmentWarningEvent(_ event: DeviceActivityEvent.Name) -> Bool {
    return event.rawValue.hasPrefix(entertainmentWarningPrefix)
  }

  override init() {
    super.init()
  }

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    log.info("intervalDidStart for activity: \(activity.rawValue)")
    
    // 如果是娱乐组活动（新小时开始），清除上一个小时的 shield
    if isEntertainmentActivity(activity) {
      if let hour = extractHour(from: activity) {
        log.info("🎮 Entertainment hour \(hour):00 started - clearing any previous shields")
      }
      clearEntertainmentShields()
    }
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    log.info("intervalDidEnd for activity: \(activity.rawValue)")
    
    // 如果是娱乐组活动（小时结束），清除该小时的 shield
    // 下一个小时的 intervalDidStart 会处理新的监控周期
    if isEntertainmentActivity(activity) {
      if let hour = extractHour(from: activity) {
        log.info("🎮 Entertainment hour \(hour):59 ended - shields will be cleared for new hour")
      }
      clearEntertainmentShields()
    }
  }
  
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    log.info("⏰ eventDidReachThreshold: \(event.rawValue) for activity: \(activity.rawValue)")
    
    // 处理娱乐组阈值事件
    if isEntertainmentActivity(activity) && isEntertainmentThresholdEvent(event) {
      if let hour = extractHour(from: activity) {
        log.info("🚫 Entertainment limit reached for hour \(hour)! Activating shields...")
      }
      activateEntertainmentShields()
    }
  }
  
  override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    log.info("⚠️ eventWillReachThresholdWarning: \(event.rawValue) for activity: \(activity.rawValue)")
    
    // 处理娱乐组警告事件
    if isEntertainmentActivity(activity) && isEntertainmentWarningEvent(event) {
      if let hour = extractHour(from: activity) {
        log.info("⚠️ Entertainment warning for hour \(hour): 5 minutes remaining!")
      }
      // 可以在这里发送本地通知提醒用户
    }
  }
  
  // MARK: - Entertainment Shield Management
  
  /// 激活娱乐组屏蔽 - 当达到每小时限制时调用
  private func activateEntertainmentShields() {
    // 从 SharedData 获取娱乐组配置
    guard let config = getEntertainmentConfig(), config.isActive else {
      log.error("❌ Entertainment config not found or inactive")
      return
    }
    
    let selection = config.selectedActivity
    
    // 设置屏蔽
    entertainmentStore.shield.applications = selection.applicationTokens
    entertainmentStore.shield.applicationCategories = .specific(selection.categoryTokens)
    entertainmentStore.shield.webDomains = selection.webDomainTokens
    
    log.info("✅ Entertainment shields activated for \(selection.applicationTokens.count) apps")
  }
  
  /// 清除娱乐组屏蔽
  private func clearEntertainmentShields() {
    entertainmentStore.shield.applications = nil
    entertainmentStore.shield.applicationCategories = nil
    entertainmentStore.shield.webDomains = nil
    entertainmentStore.shield.webDomainCategories = nil
    entertainmentStore.clearAllSettings()
    
    log.info("✅ Entertainment shields cleared")
  }
  
  /// 从 App Group UserDefaults 获取娱乐组配置
  private func getEntertainmentConfig() -> EntertainmentConfig? {
    guard let suite = UserDefaults(suiteName: "group.com.zenbound.data"),
          let data = suite.data(forKey: "entertainmentConfig") else {
      return nil
    }
    return try? JSONDecoder().decode(EntertainmentConfig.self, from: data)
  }
}

// MARK: - Entertainment Config (Mirror of SharedData.EntertainmentConfig for Extension)

/// 娱乐组配置结构 - 用于 Extension 访问
private struct EntertainmentConfig: Codable {
  var isActive: Bool = false
  var selectedActivity: FamilyActivitySelection
  var hourlyLimitMinutes: Int = 15
  var dailyLimitMinutes: Int = 120
  var restDurationMinutes: Int = 45
  var enableHourlyLimit: Bool = true
  var currentHourUsageMinutes: Int = 0
  var lastResetHour: Int = -1
  var todayTotalUsageMinutes: Int = 0
  var lastResetDate: Date?
  var shieldMessage: String = "Enjoy your time!"
  var enableWeekends: Bool = true
}
