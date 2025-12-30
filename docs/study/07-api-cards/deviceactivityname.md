# DeviceActivityName

## 1) Class summary
`DeviceActivityName` 是一个轻量的标识符（`RawRepresentable` with `String` rawValue），用来把某个 Device Activity 与你应用自己的业务数据关联起来。项目把它当作“路由键”：通过 `rawValue` 同时编码 timer 类型与 profileId，并在 extension 回调中解析执行对应动作。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- 用 `DeviceActivityName(rawValue:)` 编码业务含义：
  - `Foqos/Models/Timers/BreakTimerActivity.swift`：`"BreakScheduleActivity:<profileId>"`
  - `Foqos/Models/Timers/StrategyTimerActivity.swift`：`"StrategyTimerActivity:<profileId>"`
  - `Foqos/Models/Timers/ScheduleTimerActivity.swift`：为了兼容旧版本，直接用 `profileId` 作为 rawValue（不带前缀）。
- 在 extension 回调里解析 `DeviceActivityName.rawValue`（Confirmed）：
  - `Foqos/Models/Timers/TimerActivityUtil.swift`：
    - 新格式：`type:profileId`（components.count == 2）
    - 旧格式：`profileId`（components.count != 2，默认当作 schedule timer）
- Debug UI 展示/分类 device activities（Confirmed）：
  - `Foqos/Views/DebugView.swift`、`Foqos/Components/Debug/DeviceActivitiesDebugCard.swift`：根据 rawValue 判断 activity 类型与 profile 归属。

### Unconfirmed
- 使用 `DeviceActivityName` 进行“多 profile 并行监控”时的冲突策略（例如同一 profile 多个 timers 同时存在）。

### How to confirm
- 搜：`DeviceActivityName(rawValue:`、`.rawValue.split`、`split(separator: ":")`。
- 看：
  - `Foqos/Models/Timers/*TimerActivity.swift`
  - `Foqos/Models/Timers/TimerActivityUtil.swift`

## 3) Entry points

### UI entry
- UI 侧创建/更新 profile 会触发创建多个 `DeviceActivityName`（Confirmed）：`DeviceActivityCenterUtil`。

### Non-UI entry
- extension 回调把 `DeviceActivityName` 作为参数输入（Confirmed）：`DeviceActivityMonitorExtension.intervalDidStart/End`。

## 4) Data flow

### State owners
- `DeviceActivityName` 的设计由 app 定义（Confirmed）：三类 timer activity + 兼容旧格式。
- extension 依赖这个约定来路由（Confirmed）：`TimerActivityUtil.getTimerParts(from:)`。

### Persistence
- `DeviceActivityName` 本身不持久化，但其 rawValue 包含 profileId（Confirmed）。profile snapshot 存在 App Group UserDefaults（Confirmed）：`SharedData`。

### Network calls
- 无。

## 5) Key Apple frameworks/APIs
- `DeviceActivityName`（Confirmed）：项目直接 init，并在 monitor 回调中消费。
- iOS SDK 证据：
  - `.../DeviceActivity.framework/.../arm64-apple-ios-simulator.swiftinterface` 中含 `public struct DeviceActivityName : RawRepresentable`。

## 6) Edge cases & pitfalls
- 向后兼容（Confirmed）：旧版本 rawValue 只有 profileId；新版本 rawValue 是 `type:profileId`。
  - 风险：如果未来再增加层级（例如 `type:subtype:profileId`），当前解析逻辑会失效。
- 分隔符冲突（Unconfirmed）：profileId 当前是 UUID，不含 `:`；但如果未来 rawValue 放入其他字符串，需避免 `:`。

## 7) How to validate

### Manual steps
1. 在 Debug 页面查看 activities 列表，确认 rawValue 格式符合预期（schedule 为 UUID；break/strategy 带前缀）。
2. 触发 interval start/end，观察对应 profile 的限制是否正确开关。

### Suggested tests
- Unit：
  - 覆盖 `TimerActivityUtil.getTimerParts(from:)`：
    - `"ScheduleTimerActivity.id:UUID"` → 正确解析
    - `"UUID"` → 走旧格式回退
    - `"Unknown:UUID"` → 返回 nil

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
- 本项目已存在 `DeviceActivityName` 的使用，因此本节不适用。

## 9) What to learn next
- 读 `DeviceActivityCenterUtil`：它是生成这些 name 的单一来源。
- 读 `TimerActivity` 三个实现：它们定义了每种 name 对应的业务动作。
