# DeviceActivitySchedule

## 1) Class summary
`DeviceActivitySchedule` 描述一个“基于日历组件（DateComponents）”的监控区间：系统用 `intervalStart/intervalEnd/repeats/warningTime` 计算下一次（或当前正在进行的）interval，并驱动 `DeviceActivityMonitor` extension 回调。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- 创建 schedule 并用于 `startMonitoring`：
  - `Foqos/Utils/DeviceActivityCenterUtil.swift`
    - schedule timer：用 profile 的 `BlockedProfileSchedule.startHour/startMinute/endHour/endMinute` 生成 `DateComponents`，并 `repeats: true`。
    - break/strategy timer：`intervalStart = 00:00`，`intervalEnd = now + minutes`（封顶 23:59），并 `repeats: false`。
- 把 schedule interval 计算逻辑封装成方法（Confirmed）：
  - `Foqos/Models/Timers/ScheduleTimerActivity.swift`: `getScheduleInterval(from:)`。
  - `Foqos/Utils/DeviceActivityCenterUtil.swift`: `getTimeIntervalStartAndEnd(from:)`。

### Unconfirmed
- `warningTime` 未在项目里使用。

### How to confirm
- 搜 `DeviceActivitySchedule(`。
- 看：`Foqos/Utils/DeviceActivityCenterUtil.swift`。

## 3) Entry points

### UI entry
- 用户更新 profile schedule 后，UI 触发重新安排（Confirmed）：`DeviceActivityCenterUtil.scheduleTimerActivity(for:)`。

### Non-UI entry
- monitor extension 的回调只依赖 schedule（Confirmed），不依赖 UI。

## 4) Data flow

### State owners
- schedule 定义由 app 侧创建并下发给系统（Confirmed）。
- system 计算 `nextInterval` 并在 interval 相关事件发生时驱动 extension 回调（SDK 注释）。

### Persistence
- schedule 本身是否持久化在本地（Unconfirmed，取决于 `BlockedProfiles`/`BlockedProfileSchedule` 的存储方式）。
- How to confirm：查看 `Foqos/Models/BlockedProfiles.swift` / `Foqos/Models/Schedule.swift` 是否用 `SwiftData/CoreData/UserDefaults`。

### Network calls
- 无。

## 5) Key Apple frameworks/APIs
- `DeviceActivitySchedule`（Confirmed）：项目直接调用其 init。
- `Foundation.DateComponents/Calendar`（Confirmed）：用于构造 interval。
- iOS SDK 证据：
  - `.../DeviceActivity.framework/.../arm64-apple-ios-simulator.swiftinterface` 中含 `public struct DeviceActivitySchedule`。

## 6) Edge cases & pitfalls
- 最短 interval 15 分钟（Confirmed, SDK 注释）：
  - break/strategy timer 的 minutes 如果 < 15，`startMonitoring` 可能抛 `intervalTooShort`。
- “跨午夜/结束时间早于开始时间”处理（Unconfirmed）：
  - `ScheduleTimerActivity.getScheduleInterval` 直接把 start/end 填进 `DateComponents`；如果用户设定跨天区间（例如 23:00-07:00），系统行为取决于 DeviceActivity 的 interval 计算规则。
  - How to confirm：在真机设置跨天 schedule 观察 `nextInterval` 与回调。
- break/strategy 的 intervalStart 固定 `00:00`（Confirmed）：
  - 这等价于“从今天零点开始监控到 now+minutes”，并不是真正的“从现在开始持续 N 分钟”。
  - 这可能是刻意利用“当前已在 interval 内即可触发 intervalDidStart”这一特性（Unconfirmed）。
  - How to confirm：把 intervalStart 改成当前 hour/minute 与固定 00:00 的行为对比（仅练习，不建议直接改生产）。

## 7) How to validate

### Manual steps
- schedule timer：
  1. 创建一个从当前时间稍后开始、稍后结束的 schedule。
  2. 观察是否在 interval 进入/退出时分别触发限制启停。
- break timer：
  1. 开始一个 schedule session。
  2. 触发 break（项目内由 `DeviceActivityCenterUtil.startBreakTimerActivity` 创建一个 one-shot monitoring）。
  3. 观察 break 开始时解除限制、结束时重新限制。

### Suggested tests
- Unit：
  - `DeviceActivityCenterUtil.getTimeIntervalStartAndEnd(from:)`：分钟累加、封顶 23:59 的边界。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
- 本项目已存在 `DeviceActivitySchedule` 的使用，因此本节不适用。

## 9) What to learn next
- 读 `ScheduleTimerActivity` / `BreakTimerActivity`：理解 schedule 与 break/strategy 的差异化 interval 构造。
- 如果需要“预警回调”（`intervalWillStartWarning` 等），再研究 `warningTime` 并在 monitor extension 覆写对应方法（当前项目未使用）。
