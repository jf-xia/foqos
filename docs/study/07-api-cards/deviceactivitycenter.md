# DeviceActivityCenter

## 1) Class summary
`DeviceActivityCenter` 是 `DeviceActivity` 框架里用于“开始/停止监控某个 device activity（按日历时间段）”的核心入口。项目中用它把「日程限制 / 休息计时 / 策略计时」映射成多个 `DeviceActivityName`，并通过 monitor extension 的回调来触发开关限制。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- 直接使用 `DeviceActivityCenter.startMonitoring(_:during:events:)`：
  - `Foqos/Utils/DeviceActivityCenterUtil.swift`：
    - `scheduleTimerActivity(for:)`：基于 profile 的 `schedule` 设置 repeats = `true` 的监控。
    - `startBreakTimerActivity(for:)` / `startStrategyTimerActivity(for:)`：创建 repeats = `false` 的“倒计时”型监控。
    - `stopMonitoring`：在每次 `startMonitoring` 前先停掉同名 activity，确保覆盖旧 schedule。
  - 读取 `DeviceActivityCenter.activities`：`DeviceActivityCenterUtil.getDeviceActivities()`。
- 监控回调承接点（能证明 `startMonitoring` 的输出被消费）：
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`：`intervalDidStart/intervalDidEnd` 回调里把 `DeviceActivityName` 交给 `TimerActivityUtil`。

### Unconfirmed
- 使用 `DeviceActivityCenter.events(for:)` / `DeviceActivityCenter.schedule(for:)` 做调试或同步 UI。
  - 目前只看到读取 `activities`，没有看到 events/schedule 的读取。

### How to confirm
- 仓库内搜：
  - `DeviceActivityCenter(`
  - `startMonitoring(` / `stopMonitoring(`
  - `events(for:` / `schedule(for:`
- 关键文件：
  - `Foqos/Utils/DeviceActivityCenterUtil.swift`
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`

## 3) Entry points

### UI entry（views/screens）
- 保存/克隆/更新 profile 后触发重新安排 schedule（Confirmed）：
  - `Foqos/Views/BlockedProfileView.swift` 里多处调用 `DeviceActivityCenterUtil.scheduleTimerActivity(for:)`（见符号搜索结果）。
- Debug 页面读取当前 activities（Confirmed）：
  - `Foqos/Views/DebugView.swift` 调用 `DeviceActivityCenterUtil.getDeviceActivities()`。

### Non-UI entry（App Intent、extension、widget、background、通知、Live Activity 等）
- Device Activity Monitor extension（Confirmed）：
  - extension point：`com.apple.deviceactivity.monitor-extension`
  - principal class：`$(PRODUCT_MODULE_NAME).DeviceActivityMonitorExtension`
  - 文件：`FoqosDeviceMonitor/Info.plist`

## 4) Data flow

### State owners（谁持有状态、谁触发更新）
- “监控配置（startMonitoring）”由主 app 触发（Confirmed）：`DeviceActivityCenterUtil.*`。
- “回调消费（intervalDidStart/End）”由 extension 持有（Confirmed）：`DeviceActivityMonitorExtension`。
- 计时/策略分发由 `TimerActivityUtil` 根据 `DeviceActivityName.rawValue` 解析（Confirmed）：`Foqos/Models/Timers/TimerActivityUtil.swift`。

### Persistence（UserDefaults/文件/CoreData/Keychain/App Group 等）
- extension 通过 App Group 的 `UserDefaults(suiteName: ...)` 读取 profile snapshot / session（Confirmed）：
  - `Foqos/Models/Shared.swift`：`suiteName: "group.dev.ambitionsoftware.foqos"`
  - `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`：包含 `com.apple.security.application-groups` 同一 group。

### Network calls
- Unconfirmed：DeviceActivity monitor / shield 相关 extension 通常不应做网络。
- How to confirm：搜 `URLSession` / `Alamofire` / `.dataTask` 在 `FoqosDeviceMonitor/`、`FoqosShieldConfig/`。

## 5) Key Apple frameworks/APIs
- `DeviceActivity`（Confirmed）：
  - `DeviceActivityCenter.startMonitoring` / `stopMonitoring`：见 `DeviceActivityCenterUtil`。
  - `DeviceActivityName`：activity 的命名/编码，决定 extension 里如何路由。
  - iOS SDK 证据：
    - `.../DeviceActivity.framework/Modules/DeviceActivity.swiftmodule/arm64-apple-ios-simulator.swiftinterface`（含 `public struct DeviceActivityCenter`）。
- `FamilyControls`（Confirmed）：
  - 授权：`AuthorizationCenter.shared.requestAuthorization(for: .individual)`（`Foqos/Utils/RequestAuthorizer.swift`）。
- `ManagedSettings`（Confirmed）：
  - 真正的“限制/屏蔽”落在 `ManagedSettingsStore`：`Foqos/Utils/AppBlockerUtil.swift`。

## 6) Edge cases & pitfalls
- 监控数量上限（Confirmed, iOS SDK 注释）：一次最多 20 个活动；否则 `DeviceActivityCenter.MonitoringError.excessiveActivities`。
- 时间段限制（Confirmed, iOS SDK 注释）：
  - interval 最短 15 分钟；太短会 `.intervalTooShort`。
  - interval 最长 1 周；太长会 `.intervalTooLong`。
  - 项目里 break/strategy 的分钟数如果 < 15，`startMonitoring` 可能抛错（与 `SharedData.ProfileSnapshot.breakTimeInMinutes` 默认 15 相呼应）。
- 时区变化（Confirmed, iOS SDK 注释）：事件累计按 `nextInterval.start` 的时区计算；跨时区可能出现“累计在旧时区”行为。
- “当前已在 interval 内”的立即回调（Confirmed, iOS SDK 注释）：如果当前时间落在 intervalStart/End 内，系统可能很快就开始给 extension 回调。

## 7) How to validate

### Manual steps
- 在真机（或具备 Screen Time 能力的环境）执行：
  1. 在 app 内通过 `RequestAuthorizer` 完成 `FamilyControls` 授权。
  2. 创建/编辑一个 profile，打开 schedule，并保存。
  3. 打开 Debug 页面确认 `DeviceActivityCenter.activities` 出现对应的 `DeviceActivityName`。
  4. 等到 schedule 进入/退出区间，观察限制是否自动开启/关闭（由 `DeviceActivityMonitorExtension` 触发）。

### Suggested tests
- Unit（可行但需要抽象）：
  - 纯函数层：`TimerActivityUtil.getTimerParts(from:)` 的解析与兼容逻辑。
- Integration（更接近真实）：
  - 抽象 `DeviceActivityCenter` 包装层（例如 protocol + mock），验证 “startMonitoring 前先 stopMonitoring” 的行为。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
- 本项目已存在 `DeviceActivityCenter` 的使用，因此本节不适用。

## 9) What to learn next
- 建议先读：
  - `DeviceActivityMonitor` 卡片（如何消费回调、如何把 activity 路由成业务动作）。
  - `ManagedSettingsStore`（项目里对应 `AppBlockerUtil`）。
- Unconfirmed：如果你想要“阈值事件”（`eventDidReachThreshold`），需要引入 `DeviceActivityEvent` 并在 `startMonitoring(..., events:)` 传入 events。
  - How to confirm：查看 iOS SDK interface 中 `startMonitoring(_:during:events:)` 的参数与 `DeviceActivityMonitor.eventDidReachThreshold`。
