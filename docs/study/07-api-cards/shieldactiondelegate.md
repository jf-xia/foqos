# ManagedSettings.ShieldActionDelegate — API 学习卡

## 1) Class summary
`ShieldActionDelegate` 是用于“处理 Shield 上用户操作（按钮点击等）”的扩展入口点。系统在 Shield UI 展示时，用户点击按钮会触发 `handle(action:for:completionHandler:)` 回调，你的扩展通过 `completionHandler` 返回 `ShieldActionResponse`（例如 `.none` / `.close` / `.defer`）。

**Apple SDK 形态证据（iOS Simulator SDK）**
- 见 [docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md](docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md)
  - `ShieldActionDelegate`：`L200`
  - `handle(action:for:completionHandler:)` 三个重载：`L201–L203`
  - `ShieldActionResponse`：`L178`

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- 项目中**未找到** `ShieldActionDelegate` 的实现或引用（仓库搜索结果为 0 matches）。
- 项目已有“自定义 shield 外观”扩展（但不等于 action 处理）：
  - `FoqosShieldConfig/ShieldConfigurationExtension.swift`（`ShieldConfigurationDataSource`）

### Unconfirmed
- 本项目是否计划支持“在 Shield 上点按钮触发某种解锁/跳转/请求”的交互（需要产品定义）。

### How to confirm
- 仓库搜索：`ShieldActionDelegate` / `ShieldActionResponse` / `primaryButtonPressed`。
- 查看 Xcode target 列表与扩展 Info.plist：是否存在 `com.apple.ManagedSettingsUI.shield-action-service`（或类似）扩展点。
  - Unconfirmed：扩展点 identifier 的精确值；需要以 Apple 文档或 SDK 为准。

## 3) Entry points
### UI entry（views/screens）
- 无直接 UI 入口（这是系统 Extension 回调入口）。

### Non-UI entry（App Intent、extension、widget、background…）
- 需要一个“Shield Action”类型的 app extension（本仓库当前没有）。

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- 系统触发：用户在 Shield UI 上点击按钮（`ShieldAction.primaryButtonPressed` / `secondaryButtonPressed`）。
- 扩展响应：在 `handle(...)` 内决定返回 `ShieldActionResponse`。

### Persistence
- Unconfirmed：若要实现“请求临时解锁/延迟解锁”，可能需要与 App Group 数据（`SharedData`）交互；但本仓库目前无此实现。

### Network calls
- Unconfirmed：常见模式是把请求发给家长/服务器并用 `.defer` 等待，但本仓库没有对应网络层证据。

## 5) Key Apple frameworks/APIs
- `ManagedSettings.ShieldActionDelegate`
  - 用途：接收 shield 操作回调
- `ManagedSettings.ShieldActionResponse`
  - 用途：告诉系统如何处理（关闭 app / 不处理 / 延迟）
-（可能需要）App Group + `SharedData`
  - 用途：在扩展与主 App 间共享“是否允许临时解锁”的决策

## 6) Edge cases & pitfalls
- 隐私：回调入参是 token（`ApplicationToken`/`WebDomainToken`/`ActivityCategoryToken`），不是 bundleId/domain 明文。
- 并发：`completionHandler` 必须在合适时机调用；如果做异步（例如网络请求），要保证最终回调。
- UX：如果你返回 `.defer`，系统会重绘 Shield UI，扩展需要能应对多次回调。

## 7) How to validate
### Manual steps
- 前置：实现 ShieldActionDelegate 扩展并让系统加载。
1. 启动一个被 shield 的 App/网站。
2. 点击 Shield 的 primary button。
3. 观察行为：是否关闭被 shield 的 app、是否保持在 shield、是否出现延迟/刷新。

### Suggested tests
- 手工集成测试优先（需要系统 UI + extension 环境）。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
本项目内**不存在** `ShieldActionDelegate` 的实现，可以把它当作练习：

### Step-by-step
1. 在 Xcode 中新增一个 Shield Action 相关的 app extension target（具体模板/扩展点取决于 Xcode 支持与 Apple 文档）。
2. 新增 `ShieldActionExtension.swift`（或类似）
   - `import ManagedSettings`
   - `final class ...: ShieldActionDelegate { override func handle(...) { ... } }`
3. 在 extension 的 Info.plist 配置正确的 `NSExtensionPointIdentifier` 与 `NSExtensionPrincipalClass`。
4. 在 `handle(...)` 中先做最小实现：
   - `completionHandler(.close)`（或 `.none`）
5. 在需要时引入 App Group：
   - 读取 `SharedData`（suiteName 必须与主 App 一致）决定是否允许“临时放行”，否则返回 `.close`。

### “最小可用”边界
- 先只支持 `primaryButtonPressed`，并且只做固定响应（`.close` / `.none`）。
- 不做网络请求、不做家长审批、不做 UI 变更。

### 验收标准
- 真机上点击 Shield 按钮能触发你设定的响应（行为可观察），且不会卡住（`completionHandler` 一定被调用）。

## 9) What to learn next
- 先读本仓库已有的 Shield UI：`FoqosShieldConfig/ShieldConfigurationExtension.swift`。
- 再结合 `AppBlockerUtil` 理解“何时会触发 Shield”。
- Unconfirmed：Apple 对 Shield Action extension 的 Info.plist `NSExtensionPointIdentifier` 值与可用模板。
  - How to confirm：查 Apple 文档/WWDC 示例工程，或在 iOS SDK/`ManagedSettingsUI` 文档中查找对应 extension point identifier。
