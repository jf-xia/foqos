//
//  DeviceActivityMonitorExtension.swift
//  FoqosDeviceMonitor
//
//  Created by Ali Waseem on 2025-05-27.
//

import DeviceActivity
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
// - 协调计时活动（TimerActivityUtil）与 AppBlockerUtil；
// - 不直接访问 SwiftData，仅通过 App Group 快照（SharedData）进行轻量状态传递（如需）。
//
// 约束：
// - 运行时内存/时间受扩展限制，避免复杂计算与长耗时 IO；
// - 所有副作用应幂等（interval 事件可能重复抵达）。
//
// 与主 App 的契约：
// - 主 App 统一通过“状态同步网关”刷写 SharedData 快照、刷新 Widget/Live Activity；
// - 扩展仅消费快照与触发最低限度计时动作，不做业务决策。

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  private let appBlocker = AppBlockerUtil()

  override init() {
    super.init()
  }

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    log.info("intervalDidStart for activity: \(activity.rawValue)")
    TimerActivityUtil.startTimerActivity(for: activity)
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)

    log.info("intervalDidEnd for activity: \(activity.rawValue)")
    TimerActivityUtil.stopTimerActivity(for: activity)
  }
}
