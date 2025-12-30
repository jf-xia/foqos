# DeviceActivityAuthorization

## 1) Class summary
`DeviceActivityAuthorization`（iOS 17+）是 `DeviceActivity` 提供的一个授权状态查询入口，面向实现了 `DeviceActivityAuthorizing` 的场景：可以查询当前是否授权、以及某个 bundle identifier 是否在授权列表内。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- iOS SDK 形态证据：
  - `.../DeviceActivity.framework/Modules/DeviceActivity.swiftmodule/arm64-apple-ios-simulator.swiftinterface` 含：
    - `@objc public class DeviceActivityAuthorization : NSObject, DeviceActivityAuthorizing`
    - `public static var isAuthorized: Bool` 与 `public static func isAuthorized(_ bundleIdentifier: String) -> Bool`
- 项目里“授权请求”走的是 `FamilyControls.AuthorizationCenter`（而不是 `DeviceActivityAuthorization`）（Confirmed）：
  - `Foqos/Utils/RequestAuthorizer.swift`：`try await AuthorizationCenter.shared.requestAuthorization(for: .individual)`

### Unconfirmed
- `DeviceActivityAuthorization` 是否在本项目（或其 extension）中有必要使用。
  - 当前项目已通过 `AuthorizationCenter` 请求授权；是否还需要额外用 `DeviceActivityAuthorization` 做“extension 侧自检”，需要真实运行场景验证。

### How to confirm
- 仓库内搜：`DeviceActivityAuthorization`。
- 运行时验证（真机）：在授权前后对比 `DeviceActivityAuthorization.isAuthorized` 的值（若你打算使用此 API）。

## 3) Entry points

### UI entry（views/screens）
- 本项目 UI 侧授权入口是 `RequestAuthorizer.requestAuthorization()`（Confirmed），不是 `DeviceActivityAuthorization`。

### Non-UI entry（App Intent、extension、widget、background、通知、Live Activity 等）
- Unconfirmed：若 extension 需要判断“它自己是否被授权作为 client”，可能会用 `DeviceActivityAuthorization`。
- How to confirm：查看 DeviceActivity / FamilyControls 的官方文档与 sample，或在 extension 侧实验打印 `DeviceActivityAuthorization.authorizedClientIdentifiers`。

## 4) Data flow

### State owners
- 授权状态由系统维护（SDK API）。
- 本项目的授权状态（`@Published isAuthorized`）由 `RequestAuthorizer` 持有并更新（Confirmed）。

### Persistence
- 本项目没有看到把授权状态持久化到本地（Confirmed：`RequestAuthorizer` 只读 `AuthorizationCenter.shared.authorizationStatus`）。

### Network calls
- 无。

## 5) Key Apple frameworks/APIs
- `DeviceActivity.DeviceActivityAuthorization`（SDK 证据已列）。
- `FamilyControls.AuthorizationCenter`（Confirmed，项目实际使用）。

## 6) Edge cases & pitfalls
- 可用性（Confirmed, SDK attributes）：iOS 17.0+ 才有 `DeviceActivityAuthorization`。
- 多 target / extension 授权关系（Unconfirmed）：`authorizedClientIdentifiers` 的含义与哪个 target 算 “client” 需要结合 entitlement 与系统规则确认。

## 7) How to validate

### Manual steps
1. 在真机上安装 app，未授权前记录 `AuthorizationCenter.shared.authorizationStatus`。
2. 触发 `RequestAuthorizer.requestAuthorization()` 完成授权。
3. （练习）如果你在 debug 分支里加入 `DeviceActivityAuthorization.isAuthorized` 的打印，对比授权前后值变化。

### Suggested tests
- Unconfirmed：此类 API 多为系统状态，通常不适合纯单元测试。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
本项目当前没有直接使用 `DeviceActivityAuthorization`（仅使用 `AuthorizationCenter`）。如果你想练习把它加入“extension 自检”，建议最小实现：

Step-by-step（建议只在 Debug/开发分支做）：
1. 在 `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift` 的 `intervalDidStart` 里记录授权状态（仅日志）：
   - 调用 `DeviceActivityAuthorization.isAuthorized`。
2. 若返回 false，在日志中输出 `activity.rawValue` 并 return（避免继续执行 `TimerActivityUtil.startTimerActivity`）。
3. 在真机上分别测试授权前/后回调行为。

最小可用边界：
- 只做日志与短路，不改变任何 UI/业务策略。

验收标准：
- 授权前 extension 会记录“未授权”；授权后记录“已授权”，且原行为不变。

## 9) What to learn next
- 已有卡片：`AuthorizationCenter`（项目真实授权入口）。
- Unconfirmed：DeviceActivity / FamilyControls 在“谁是 authorized client（主 app vs extension）”上的规则。
  - How to confirm：对照 Apple sample 工程 + entitlement 配置，并在多 target 情况下打印 `authorizedClientIdentifiers`。
