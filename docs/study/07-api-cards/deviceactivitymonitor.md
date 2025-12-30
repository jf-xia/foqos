# DeviceActivityMonitor

## 1) Class summary
`DeviceActivityMonitor` 是 `DeviceActivity` 的 extension 入口基类：系统在 device activity 的 interval 开始/结束（以及可选阈值事件）时回调它的 override 方法。项目用一个 monitor extension 将回调转换成“开启/关闭限制”的业务动作。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- 真实 monitor extension（子类 + override）：
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
    - `class DeviceActivityMonitorExtension: DeviceActivityMonitor`
    - override：`intervalDidStart(for:)`、`intervalDidEnd(for:)`
- extension 配置（principal class + extension point）：
  - `FoqosDeviceMonitor/Info.plist`
    - `NSExtensionPointIdentifier = com.apple.deviceactivity.monitor-extension`
    - `NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).DeviceActivityMonitorExtension`
- 回调后的路由/业务执行（Confirmed）：
  - `Foqos/Models/Timers/TimerActivityUtil.swift`：解析 `DeviceActivityName.rawValue`，找到 profile snapshot，然后调用对应 `TimerActivity.start/stop`。
  - `Foqos/Models/Timers/ScheduleTimerActivity.swift`：在 schedule interval 开始时 `activateRestrictions`，结束时 `deactivateRestrictions`。
  - `Foqos/Models/Timers/BreakTimerActivity.swift` / `StrategyTimerActivity.swift`：用于 break/策略计时。

### Unconfirmed
- `eventDidReachThreshold` / `intervalWillStartWarning` / `intervalWillEndWarning` 等回调在项目中未实现。

### How to confirm
- 搜：`class .*: DeviceActivityMonitor` 或 `intervalDidStart(`。
- 核心文件：
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
  - `FoqosDeviceMonitor/Info.plist`

## 3) Entry points

### UI entry（views/screens）
- UI 不直接调用 `DeviceActivityMonitor`，而是通过 `DeviceActivityCenter.startMonitoring` 间接触发 extension 回调（Confirmed）。

### Non-UI entry
- Extension 入口（Confirmed）：
  - `com.apple.deviceactivity.monitor-extension`
  - principal class：`DeviceActivityMonitorExtension`

## 4) Data flow

### State owners
- 系统：负责在“设备被使用”且落在 interval 内/外时调用 `intervalDidStart/End`（SDK 注释）。
- extension：`DeviceActivityMonitorExtension` 接到回调后把 `activity.rawValue` 交给业务路由（Confirmed）。
- 业务路由：`TimerActivityUtil` 解析后调用 `ScheduleTimerActivity/BreakTimerActivity/StrategyTimerActivity`（Confirmed）。

### Persistence
- extension 通过 App Group UserDefaults 读取 profile snapshot / session（Confirmed）：`SharedData`。

### Network calls
- Unconfirmed：extension 沙盒/系统限制下通常避免网络。
- How to confirm：搜 `URLSession` 仅在 `FoqosDeviceMonitor/`。

## 5) Key Apple frameworks/APIs
- `DeviceActivityMonitor`（Confirmed）：子类 override `intervalDidStart/End`。
- `OSLog`（Confirmed）：extension 用 `Logger` 记录回调。
- iOS SDK 证据：
  - `.../DeviceActivity.framework/Modules/DeviceActivity.swiftmodule/arm64-apple-ios-simulator.swiftinterface` 中含 `@objc open class DeviceActivityMonitor`。

## 6) Edge cases & pitfalls
- 回调触发条件（Confirmed, SDK 注释）：系统“仅在设备处于使用状态”时调用 interval start/end；如果设备闲置，回调可能延迟。
- 业务一致性（Confirmed, 代码）：
  - `ScheduleTimerActivity.start` 会检查 `schedule.isTodayScheduled()`、`schedule.olderThan15Minutes()` 等条件，避免误触发。
  - `ScheduleTimerActivity.stop` 会校验 active session 的 profileId，避免误关闭别的 profile 的限制。
- 日志/隐私：extension 日志里打印了 `activity.rawValue`（包含 profileId）；如果日志上报到外部属于 Unconfirmed 风险。

## 7) How to validate

### Manual steps
1. 确认 extension 已被正确打包：检查 `FoqosDeviceMonitor/Info.plist` 的 principal class。
2. 通过 app 创建一个会触发 monitoring 的 activity（例如 schedule interval 正在进行）。
3. 在 Console 日志里过滤 `subsystem: com.foqos.monitor`，观察 `intervalDidStart/intervalDidEnd`。

### Suggested tests
- Unit：
  - 针对 `TimerActivityUtil.getTimerParts(from:)` 做解析测试（不依赖系统回调）。
- Unconfirmed：Xcode 对 DeviceActivity monitor 的自动化测试支持有限。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
- 本项目已存在 `DeviceActivityMonitor` 的实现，因此本节不适用。

## 9) What to learn next
- 读 `DeviceActivityName` 卡片：理解 `activity.rawValue` 如何编码 timer 类型与 profileId（项目有向后兼容逻辑）。
- 读 `DeviceActivityCenter` 卡片：理解谁创建 monitoring、如何覆盖/移除活动。
