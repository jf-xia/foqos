# FamilyControls.FamilyActivitySelection — API 学习卡

## 1) Class summary
`FamilyActivitySelection` 是一个可编码（`Codable`）的选择容器，保存用户在 `FamilyActivityPicker` 中选中的 apps/categories/web domains（以 token/opaque 形式表示，保护隐私）。本项目把它作为“Profile 的阻止/允许目标集合”，并同时存入 SwiftData 与 App Group UserDefaults（供 Widget/扩展读取）。

**Apple SDK 形态证据（iOS Simulator SDK）**
- `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/FamilyControls.framework/Modules/FamilyControls.swiftmodule/arm64-apple-ios-simulator.swiftinterface`
  - 可 grep 锚点：`public struct FamilyActivitySelection : Codable, Equatable`（本地 grep 显示在该文件第 142 行附近）

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- SwiftData 模型字段：`Foqos/Models/BlockedProfiles.swift`
  - `var selectedActivity: FamilyActivitySelection`
  - `createProfile` / `updateProfile` 写入该字段
- App Group snapshots：`Foqos/Models/Shared.swift` + `BlockedProfiles.updateSnapshot(for:)`
  - `SharedData.ProfileSnapshot.selectedActivity: FamilyActivitySelection`
  - 使用 `UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos")`
- UI state：`Foqos/Views/BlockedProfileView.swift`
  - `@State private var selectedActivity = FamilyActivitySelection()`，并在 init 从 profile 读取
- selection -> restrictions：`Foqos/Utils/AppBlockerUtil.swift`
  - 读取：`selection.applicationTokens` / `selection.categoryTokens` / `selection.webDomainTokens`
  - 写入：`ManagedSettingsStore().shield.*` 以及 `store.webContent.blockedByFilter`
- Widget 展示：`FoqosWidget/Views/ProfileWidgetEntryView.swift`
  - 统计 `profile.selectedActivity.categories/applications/webDomains` count
- Debug：`Foqos/Components/Debug/SelectedActivityDebugCard.swift`、`Foqos/Views/DebugView.swift`

### Unconfirmed
- “token 失效语义”（当授权被撤销时 token 是否失效）
  - `.swiftinterface` 注释中提到“授权撤销会使 tokens voided”（这是 Apple API 的语义），但本项目是否有对该场景的显式处理尚未看到。

### How to confirm
- 在仓库搜索：
  - `selectedActivity:` / `FamilyActivitySelection()` / `.applicationTokens` / `.categoryTokens` / `.webDomainTokens`
- 验证 SDK 形态：
  - `grep -n "public struct FamilyActivitySelection" /Applications/Xcode.app/.../FamilyControls...swiftinterface`
- 验证 token 失效处理：
  - 搜索 `FamilyControlsError` / `authorizationStatus` 变化后的清理逻辑
  - 真机撤销授权后，观察限制是否被移除、以及 selection 是否需要重选

## 3) Entry points
### UI entry（views/screens）
- `Foqos/Views/BlockedProfileView.swift`：Profile 编辑/创建时持有并保存 selection
- `Foqos/Components/BlockedProfileView/AppPicker.swift`：通过 `FamilyActivityPicker` 修改 selection
- `Foqos/Components/BlockedProfileView/BlockedProfileAppSelector.swift`：展示 selection 的计数与 warning

### Non-UI entry（App Intent、extension、widget、background…）
- Widget：`FoqosWidget/Views/ProfileWidgetEntryView.swift` 读取 `SharedData.ProfileSnapshot.selectedActivity` 用于展示
- 监控扩展：`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift` 目前未直接读取 selection，但其触发的限制链路依赖 `AppBlockerUtil`（需结合 `TimerActivityUtil` 进一步确认）
  - Unconfirmed：`TimerActivityUtil` 是否在扩展侧读取 snapshot 并调用 `AppBlockerUtil.activateRestrictions`。
  - How to confirm：打开 `TimerActivityUtil` 并搜索 `SharedData` / `AppBlockerUtil.activateRestrictions`。

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- 交互编辑：`BlockedProfileView.@State selectedActivity`（UI state owner）
- 持久化模型：`BlockedProfiles.selectedActivity`（SwiftData owner）
- 共享快照：`SharedData.profileSnapshots[profileID].selectedActivity`（App Group UserDefaults owner）

### Persistence（UserDefaults/文件/CoreData/Keychain/App Group 等）
- SwiftData：`BlockedProfiles` 是 `@Model`，字段 `selectedActivity` 直接存储 selection
- App Group UserDefaults：`SharedData` 将 `ProfileSnapshot`（含 selection）编码成 JSON 写入 suite `group.dev.ambitionsoftware.foqos`
- Entitlements 证据：
  - App Groups：`Foqos/foqos.entitlements`、`FoqosWidget/FoqosWidgetExtension.entitlements`、`FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`

### Network calls
- Confirmed：selection 的保存与应用逻辑路径未发现网络调用。

## 5) Key Apple frameworks/APIs
- `FamilyControls.FamilyActivitySelection`
  - 用途：承载用户选择的 apps/categories/domains（token/opaque values）
  - 调用点：`BlockedProfiles`、`SharedData.ProfileSnapshot`、`AppPicker`、Widget
- `ManagedSettings.ManagedSettingsStore`
  - 用途：把 selection 转为系统屏蔽策略（shield/web content）
  - 调用点：`Foqos/Utils/AppBlockerUtil.swift`
- `SwiftData`（`@Model`）
  - 用途：本地持久化 profile（含 selection）
  - 调用点：`Foqos/Models/BlockedProfiles.swift`

## 6) Edge cases & pitfalls
- 授权撤销导致 tokens 失效
  - Unconfirmed（项目层面）：是否会在授权撤销后提示用户重新选择/自动清空 selection。
  - How to confirm：模拟撤销授权 + 使用旧 selection 触发 `AppBlockerUtil.activateRestrictions`，观察系统行为/错误。
- Allow mode vs Block mode 的计数与语义
  - Confirmed（项目实现）：`FamilyActivityUtil` 的注释与 `AppPicker` 文案强调 Allow mode 下 categories 可能“展开为单个 apps”并触发“50 限制”。
  - Unconfirmed：该语义是否与系统完全一致。
- 扩展读取共享数据
  - Pitfall：App Group suiteName 必须一致且 entitlements 配置正确。
  - Confirmed：suiteName `group.dev.ambitionsoftware.foqos` 在 `SharedData` 中硬编码。

## 7) How to validate
### Manual steps
1. 创建一个 Profile，打开 app picker 选择若干 apps/categories/domains。
2. 保存 Profile。
3. 重新进入编辑页，确认 selection 回显（计数不为 0）。
4. 启动一次 blocking session（取决于策略），确认实际 shield 生效。
5. 打开 Widget（如果配置了 profile），确认 widget 的 blocked count 与 selection 数量一致。

### Suggested tests
- Unit：
  - `SharedData.profileSnapshots` 编码/解码回归（确保 selection 的 `Codable` 持久化在 suite 中可逆）
  - `AppBlockerUtil.getWebDomains(from:)` 对 domains 的映射
- Integration/UI：
  - “编辑 selection -> 保存 -> 重新打开 -> 再应用限制”的端到端流程

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
**本项目已存在实现**（SwiftData + App Group snapshots + ManagedSettings 应用）。

可作为练习的“最小补强”任务：
1. 在 `AppBlockerUtil.activateRestrictions` 捕获并记录（OSLog）selection 的规模（apps/categories/domains count），便于排查超限/失效 token。
2. 在授权变为 `.denied` 时（可从 `HomeView`/`RequestAuthorizer` 入口），提示用户需要重新授权并避免继续应用旧 selection（不增加新页面的前提下，可只做日志/现有 UI 文案）。

## 9) What to learn next
- Confirmed：selection 的应用最终落在 `ManagedSettingsStore`（shield/webContent）与 `DeviceActivity`（定时监控）。
- 建议继续读：
  - `Foqos/Utils/AppBlockerUtil.swift`（selection -> shield/webContent）
  - `Foqos/Utils/DeviceActivityCenterUtil.swift`（定时活动）
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`（后台回调）
- Unconfirmed：扩展侧是否在 interval start/end 时应用/撤销 selection 对应的限制（需要结合 `TimerActivityUtil`）。
- How to confirm：打开并搜索 `TimerActivityUtil` / `startTimerActivity` / `stopTimerActivity`。
