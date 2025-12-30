# FamilyControls.AuthorizationCenter — API 学习卡

## 1) Class summary
`AuthorizationCenter` 是 FamilyControls 框架中用于“请求/撤销家长控制授权”的中心对象，并通过 `authorizationStatus` 暴露当前授权状态（可用 Combine/SwiftUI 观察）。在本项目中，它被封装在 `RequestAuthorizer` 中，用于在 App 首次使用时触发 `.individual` 授权请求。

**Apple SDK 形态证据（iOS Simulator SDK）**
- `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/FamilyControls.framework/Modules/FamilyControls.swiftmodule/arm64-apple-ios-simulator.swiftinterface`
  - 可 grep 锚点：`public class AuthorizationCenter`（本地 grep 显示在该文件第 242 行附近）

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- 授权封装：`Foqos/Utils/RequestAuthorizer.swift`
  - 调用：`AuthorizationCenter.shared.requestAuthorization(for: .individual)`
  - 读取：`AuthorizationCenter.shared.authorizationStatus`
- UI 入口（触发授权）：`Foqos/Views/HomeView.swift`
  - 通过 `VersionFooter(... onAuthorizationHandler: { requestAuthorizer.requestAuthorization() })` 触发授权
  - 通过 `.fullScreenCover` 展示 `IntroView`，其完成回调也会触发 `requestAuthorizer.requestAuthorization()`
- UI 状态展示：`Foqos/Components/Dashboard/VersionFooter.swift`
  - `authorizationStatus == .approved` 显示绿色 “All systems functional”
  - 未授权时显示红色按钮 “Authorization required. Tap to authorize.”
- capability / entitlement（Family Controls）：
  - 主 App：`Foqos/foqos.entitlements` 包含 `com.apple.developer.family-controls = true`
  - 监控扩展：`FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements` 包含 `com.apple.developer.family-controls = true`

### Unconfirmed
- 项目是否在“App 首次启动时总是请求授权”：代码中存在多个触发点（Intro + Footer），但是否在冷启动时无条件触发，需结合 Intro 展示条件确认。

### How to confirm
- 在仓库内搜索：
  - `AuthorizationCenter.shared.requestAuthorization`、`getAuthorizationStatus()`
  - `showIntroScreen` 与 `IntroView { requestAuthorizer.requestAuthorization() }`
- 检查 entitlements：
  - 打开 `Foqos/foqos.entitlements`、`FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`
- 验证 SDK 形态：
  - `grep -n "public class AuthorizationCenter" /Applications/Xcode.app/.../FamilyControls...swiftinterface`

## 3) Entry points
### UI entry（views/screens）
- `Foqos/Views/HomeView.swift`
  - `VersionFooter` 提供“未授权 -> 点击授权”的 UI
  - `IntroView`（通过 `fullScreenCover`）在引导流程中也会触发授权请求
- `Foqos/Components/Dashboard/VersionFooter.swift`
  - 读取并展示授权状态（由上层注入 `AuthorizationStatus`）

### Non-UI entry（App Intent、extension、widget、background…）
- Confirmed：未在扩展/Intent/Widget 代码中找到 `AuthorizationCenter` 调用。
- Unconfirmed：是否存在某个 AppIntent 在后台触发授权流程（通常系统 UI 限制较多）。
- How to confirm：全仓库搜索 `AuthorizationCenter` / `requestAuthorization(`。

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- `RequestAuthorizer`（`ObservableObject`）持有：`@Published var isAuthorized`（项目自定义状态）
- `AuthorizationCenter.shared.authorizationStatus`（Apple 状态源）被 `RequestAuthorizer.getAuthorizationStatus()` 同步读取，并由 `HomeView` 传递给 `VersionFooter`
- `HomeView` 监听 `requestAuthorizer.isAuthorized` 变化，更新 `@AppStorage("showIntroScreen")`

### Persistence（UserDefaults/文件/CoreData/Keychain/App Group 等）
- Confirmed：`HomeView` 使用 `@AppStorage("showIntroScreen")` 持久化“是否展示引导页”。
- Unconfirmed：Apple 的授权状态是否会被系统持久化、以及本项目是否依赖这种持久化语义。
- How to confirm：
  - Apple 部分：查 `FamilyControls.AuthorizationCenter` 文档（或 `.swiftinterface` 注释）
  - 项目部分：检查是否有本地存储 `AuthorizationStatus` 的代码（搜索 `AuthorizationStatus` 写入 UserDefaults/SwiftData）。

### Network calls
- Confirmed：在 `RequestAuthorizer` 相关路径未发现网络请求。
- How to confirm：全仓库搜索 `URLSession` / `Alamofire` / `fetch`。

## 5) Key Apple frameworks/APIs
- `FamilyControls.AuthorizationCenter`
  - 用途：请求 `.individual` 授权、读取 `authorizationStatus`
  - 调用点：`Foqos/Utils/RequestAuthorizer.swift`
- `FamilyControls.AuthorizationStatus`
  - 用途：向 UI 展示“已授权/未授权”
  - 调用点：`Foqos/Components/Dashboard/VersionFooter.swift`
- 并发相关：`Task { try await ... }` + `MainActor.run`
  - 用途：在异步授权结束后更新 `isAuthorized`
  - 调用点：`Foqos/Utils/RequestAuthorizer.swift`

## 6) Edge cases & pitfalls
- Capability/Entitlement 必须开启（否则系统会失败/报错）
  - Confirmed：本项目主 App 与 Device Monitor extension 的 entitlements 已包含 `com.apple.developer.family-controls`。
- 平台可用性
  - Confirmed（SDK 注解）：`AuthorizationCenter` 标注了 macOS/tvOS/watchOS/visionOS 不可用（见 `.swiftinterface`）。
  - 项目侧信号：VS Code 静态检查报告 `AuthorizationCenter` 在 macOS unavailable（见 `Foqos/Utils/RequestAuthorizer.swift` 的诊断）。
- 授权请求的系统 UI 限制
  - Unconfirmed：是否只能在前台/特定时机弹出。
  - How to confirm：Apple 文档 + 真机验证。
- 观察 `authorizationStatus`
  - Confirmed：项目当前通过同步 getter 读取状态；未发现使用 `$authorizationStatus` 的 Combine 订阅。
  - Pitfall：如果授权状态变化来自外部事件（系统设置变更等），同步读取可能不够及时。

## 7) How to validate
### Manual steps
1. 真机（或支持的模拟器环境）安装运行 App。
2. 首次进入时，观察是否出现 `IntroView`（取决于 `@AppStorage("showIntroScreen")`）。
3. 在 `HomeView` 底部 `VersionFooter`：
   - 未授权应显示红色提示，并可点击触发授权。
   - 完成授权后应显示绿色 “All systems functional”。
4. 反复启动 App，观察授权状态展示是否稳定。

### Suggested tests
- Unit：为 `RequestAuthorizer` 抽象出协议/注入点（Practice task 可做），用 fake `AuthorizationCenter` 测试成功/失败路径对 `isAuthorized` 的更新。
- UI：验证 `VersionFooter` 在 `.approved` / `.denied` 状态下的呈现（SwiftUI snapshot / UI 测试）。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
**本项目已存在实现**（见 `RequestAuthorizer` + `HomeView` + `VersionFooter`）。

仍可作为练习的“最小增强”任务（不扩展 UX 范围）：
1. 让 `HomeView` 直接观察 `AuthorizationCenter.shared.authorizationStatus` 变化（例如通过 `@StateObject`/`@ObservedObject` 持有 center），减少“手动 getter 读取”的滞后。
2. 验证：在系统设置中撤销授权后，App UI 是否能实时反映。

## 9) What to learn next
- Confirmed：该授权流程是 Screen Time / FamilyControls 能力链路的前置步骤；后续限制执行在 `ManagedSettings`/`DeviceActivity`。
- 建议继续阅读（模块级）：
  - `Foqos/Utils/AppBlockerUtil.swift`（如何将 selection 转成 shield/webContent 规则）
  - `Foqos/Utils/DeviceActivityCenterUtil.swift` + `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`（定时/后台触发）
  - `Foqos/Models/Shared.swift`（App Group snapshots 给扩展读取）
- Unconfirmed：是否需要单独的 `ManagedSettingsStore` 命名/多 store 管理策略。
- How to confirm：搜索 `ManagedSettingsStore(` 和 `store.shield` 的全部调用点。
