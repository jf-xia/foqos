# DeviceActivityEvent

## 1) Class summary
`DeviceActivityEvent` 定义了“在某个 device activity 的 interval 内，针对应用/分类/域名的累计使用达到阈值（threshold）时触发回调”的事件。它与 `DeviceActivityCenter.startMonitoring(..., events:)` 和 `DeviceActivityMonitor.eventDidReachThreshold` 配套使用。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- iOS SDK 形态证据（DeviceActivity.framework）：
  - `.../DeviceActivity.framework/.../arm64-apple-ios-simulator.swiftinterface`
    - `public struct DeviceActivityEvent : Equatable`（示例：grep 结果显示在该 interface 的早期行）
    - `startMonitoring(..., events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:])`
    - `DeviceActivityMonitor.eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName)`
- 项目目前只使用 `startMonitoring(activity, during: schedule)`（不传 events）（Confirmed）：
  - `Foqos/Utils/DeviceActivityCenterUtil.swift` 的 `startMonitoring` 调用没有传 `events:` 参数。

### Unconfirmed
- 项目是否需要“阈值事件”来实现更精细的提醒/限制（例如：每天刷某个 app 达到 30 分钟就强制限制）。

### How to confirm
- 仓库内搜：
  - `DeviceActivityEvent`
  - `eventDidReachThreshold`
  - `startMonitoring(` 是否带 `events:` 参数

## 3) Entry points

### UI entry（views/screens）
- 当前项目 UI 只会触发 schedule/break/strategy timer 的 startMonitoring，不涉及事件阈值（Confirmed）。

### Non-UI entry
- 若使用阈值事件：
  - App 侧：调用 `DeviceActivityCenter.startMonitoring(..., events:)` 配置 events。
  - Extension 侧：覆写 `DeviceActivityMonitor.eventDidReachThreshold` 处理事件（当前项目未实现）。

## 4) Data flow

### State owners
- App 侧拥有“事件配置”（哪些 apps/categories/webDomains + threshold）。
- System 在 interval 内累计活动并在达阈值时回调 extension。
- Extension 侧消费事件并执行动作（例如调用 `ManagedSettingsStore`）。

### Persistence
- Unconfirmed：事件配置是否需要持久化（如果做“用户可配置阈值”，通常需要存储）。
- How to confirm：看你要把阈值放到 profile 的哪个字段，并是否要共享给 extension（App Group）。

### Network calls
- 无。

## 5) Key Apple frameworks/APIs
- `DeviceActivityEvent` / `DeviceActivityEvent.Name`（DeviceActivity.framework）。
- `FamilyControls` tokens：`ApplicationToken` / `ActivityCategoryToken` / `WebDomainToken`（事件的入参集合类型来自 FamilyControls/ManagedSettings 生态，项目已使用这些 token 进行 shield）。

## 6) Edge cases & pitfalls
- 阈值累计的时间语义（Confirmed, SDK 注释片段）：
  - 通常是“前台使用累计”；跨时区/跨 interval 的累计规则需要仔细验证。
- 如果 interval 正在进行中才开始监控（Confirmed, SDK 注释片段）：系统可能只从“开始监控的那一刻”才开始累计（iOS 17.4+ 还有 `includesPastActivity` 相关 API 变化）。
- Extension 能力限制（Unconfirmed）：某些 report extension 明确禁止网络；monitor extension 也应避免网络/重计算。

## 7) How to validate

### Manual steps
1. 选一个 profile，构造一个 event：例如对 `profile.selectedActivity.applicationTokens` 设定 `threshold = 0h30m`。
2. 调用 `startMonitoring(..., events: [eventName: event])`。
3. 在 monitor extension 里实现/记录 `eventDidReachThreshold`。
4. 在真机上打开对应 app 累计到阈值，确认回调发生。

### Suggested tests
- Unit：对“event 配置构造函数”做数据结构测试。
- Integration：仅能在真机手动验证为主。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
本项目当前未使用 `DeviceActivityEvent`，可以作为一个受控练习。

Step-by-step（最小可用）：
1. 新增一个 Debug-only helper（建议放在 `Foqos/Utils/DeviceActivityCenterUtil.swift` 或新 util）：
   - 创建 `DeviceActivityEvent`，阈值设为 `DateComponents(minute: 15)`（注意 SDK 最小 interval/阈值限制）。
   - 在 `startMonitoring` 时传入 `events:`。
2. 在 `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift` 里覆写：
   - `eventDidReachThreshold(_:activity:)`，先只写 `Logger` 输出。
3. 真机验证：打开被选 app 直到阈值，确认日志出现。

最小可用边界：
- 只做日志回调，不改 shield 行为。

验收标准：
- 能稳定触发 `eventDidReachThreshold` 回调且 activity/event 名称正确。

## 9) What to learn next
- 读 `DeviceActivityCenter`：events 参数如何与 schedule 组合。
- 读 `ManagedSettingsStore` / `AppBlockerUtil`：一旦阈值到达，如何切换限制。
