# ManagedSettings.ManagedSettingsStore — API 学习卡

## 1) Class summary
`ManagedSettingsStore` 是 `ManagedSettings` 框架的“设置写入入口”，用于对当前设备/用户应用系统级限制（例如 Shield 应用/网站、Web 内容过滤、禁止卸载等）。本项目通过一个具名 store（`"foqosAppRestrictions"`）集中写入限制，并在 App 与 `DeviceActivityMonitor` 扩展内复用同一份写入逻辑。

**Apple SDK 形态证据（iOS Simulator SDK）**
- 见 [docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md](docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md)
  - `ManagedSettingsStore` 类型：`L386`
  - `ManagedSettingsStore.shield`：`L423`
  - `ManagedSettingsStore.webContent`：`L427`
  - `ManagedSettingsStore.application`：`L407`
  - `ManagedSettingsStore.clearAllSettings()`：`L430`

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- 限制写入边界（唯一集中处）：`Foqos/Utils/AppBlockerUtil.swift`
  - `let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("foqosAppRestrictions"))`
  - 写入 `store.shield.*` / `store.webContent.blockedByFilter` / `store.application.denyAppRemoval`
  - 清理：`store.clearAllSettings()`
- App 内启动/停止限制（手动策略示例）：`Foqos/Models/Strategies/ManualBlockingStrategy.swift`
  - `startBlocking` 调 `AppBlockerUtil.activateRestrictions(...)`
  - `stopBlocking` 调 `AppBlockerUtil.deactivateRestrictions()`
- 后台定时触发链路（扩展侧）：
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`：`intervalDidStart/intervalDidEnd` 调 `TimerActivityUtil.startTimerActivity/stopTimerActivity`
  - `Foqos/Models/Timers/TimerActivityUtil.swift`：从 `DeviceActivityName` 解析 profileId，读取 `SharedData.snapshot(for:)`，再调用各 `TimerActivity.start/stop`
  - `Foqos/Models/Timers/ScheduleTimerActivity.swift` / `BreakTimerActivity.swift` / `StrategyTimerActivity.swift`：在 start/stop 中调用 `AppBlockerUtil.activateRestrictions/deactivateRestrictions`
- 构建与框架链接：`foqos.xcodeproj/project.pbxproj`
  - 包含 `ManagedSettings.framework` 与 `ManagedSettingsUI.framework`（用于 Shield UI）
- 能力与共享容器：
  - `Foqos/foqos.entitlements`：`com.apple.developer.family-controls`、App Groups `group.dev.ambitionsoftware.foqos`
  - `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`：`com.apple.developer.family-controls` + App Groups
  - `Foqos/Models/Shared.swift`：`UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos")` 持久化 snapshot（供扩展读取）

### Unconfirmed
- 系统对“多 store 名称”并存时的仲裁行为（本项目使用单一命名 store，但 OS 可能还有其他来源的配置）。
- `clearAllSettings()` 与逐字段置 `nil` 在不同系统版本上的差异（项目里两者都调用了：先置空字段，再 `clearAllSettings()`）。

### How to confirm
- 在仓库搜索：
  - `ManagedSettingsStore(`、`store.shield`、`store.webContent`、`denyAppRemoval`、`clearAllSettings()`
  - `AppBlockerUtil()` / `activateRestrictions(` / `deactivateRestrictions()`
- 在 Apple SDK 侧核对：
  - 运行 `python3 scripts/extract_managedsettings_sdk_evidence.py` 并查看证据文件中的行号。

## 3) Entry points
### UI entry（views/screens）
- `Foqos/Views/HomeView.swift`
  - `strategyManager.toggleBlocking(context:activeProfile:)` 触发开始/结束 session（进而触发 `AppBlockerUtil` 写入/清理）
  - `strategyManager.toggleBreak(context:)` 触发 Break（进而临时 `deactivateRestrictions`）
- `Foqos/foqosApp.swift`
  - 注入 `StrategyManager.shared` 为环境对象；并在 `init` 注册后台任务（与定时/通知相关）

### Non-UI entry（App Intent、extension、widget、background…）
- DeviceActivity monitor extension：`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
  - 系统回调 `intervalDidStart/intervalDidEnd` → `TimerActivityUtil` → `AppBlockerUtil`（最终写入 `ManagedSettingsStore`）
- App Intents：
  - `Foqos/Intents/StartProfileIntent.swift`：后台启动 profile session（内部进一步调用策略/限制写入）
  - `Foqos/Intents/StopProfileIntent.swift`：后台停止 session（内部进一步清理限制）
  - 具体写入点仍落在 `AppBlockerUtil`（Confirmed：从策略链路可见）

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- Profile 持久态：`Foqos/Models/BlockedProfiles.swift`（SwiftData `@Model`）
- “跨进程可读”的 snapshot：`Foqos/Models/Shared.swift`（App Group UserDefaults）
- “把 snapshot 映射为系统限制”的边界：`Foqos/Utils/AppBlockerUtil.swift`（持有 `ManagedSettingsStore`）
- 触发者：
  - 前台：`HomeView` → `StrategyManager` → `BlockingStrategy` → `AppBlockerUtil`
  - 后台：`DeviceActivityMonitorExtension` → `TimerActivityUtil` → `TimerActivity` → `AppBlockerUtil`

### Persistence（UserDefaults/文件/CoreData/Keychain/App Group 等）
- SwiftData：`BlockedProfiles.selectedActivity` 等字段
- App Group UserDefaults：`SharedData.profileSnapshots`、`SharedData.activeSharedSession` 等

### Network calls
- Confirmed：上述限制写入/清理链路中未见网络请求。

## 5) Key Apple frameworks/APIs
- `ManagedSettings.ManagedSettingsStore`
  - 为什么：系统限制的唯一写入入口（shield/web content/app settings）
  - 项目调用点：`Foqos/Utils/AppBlockerUtil.swift`
- `ManagedSettings.ShieldSettings` / `ManagedSettings.WebContentSettings`
  - 为什么：分别覆盖“App/网站的 Shield UI”与“Safari/WebKit 级别的域名过滤”
  - 项目调用点：同上
- `DeviceActivity`
  - 为什么：后台定时触发 start/stop，驱动同一套限制写入逻辑
  - 项目调用点：`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`、`Foqos/Models/Timers/*`

## 6) Edge cases & pitfalls
- 授权与能力：必须具备 `com.apple.developer.family-controls`，且授权流程成功后才能生效（项目入口：`RequestAuthorizer.requestAuthorization()`）。
- 数量限制：Shield token 集合在系统层有上限（项目实现涉及 `.applications`、`.webDomains`、`.applicationCategories` 等集合）。
- 清理策略：如果只置空部分字段可能残留；项目采取“字段置空 + `clearAllSettings()`”的双保险。
- App vs Extension：
  - 监控扩展通过 App Group 读取 snapshot；suiteName 必须一致，否则扩展拿不到 profile selection。

## 7) How to validate
### Manual steps
1. 在 App 内完成授权（触发 `RequestAuthorizer.requestAuthorization()`）。
2. 创建/编辑 profile，选取 apps/categories/domains（`FamilyActivitySelection`）。
3. 在 `HomeView` 点击策略按钮触发 `toggleBlocking`。
4. 观察被 Shield 的 App/网站是否出现自定义 Shield UI（来自 `FoqosShieldConfig` 扩展）。
5. 开启 schedule 并退出 App，等待 `DeviceActivityMonitor` 在后台触发 interval start/end（可结合 Debug 卡片查看活动）。

### Suggested tests
- Integration（建议）：为 `AppBlockerUtil.activateRestrictions` 添加可注入的 store（或 wrapper）后做映射单测（目前代码结构偏直接调用系统 API，未提供测试 seam）。
- UI/Manual：用 `DeviceActivitiesDebugCard` 验证活动命名与解析规则（legacy vs 新格式）。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
**本项目已存在实现**（`AppBlockerUtil` + 扩展侧复用 + UI 触发）。

可练习的最小任务（不扩展 UI）：
1. 为 `AppBlockerUtil` 增加结构化日志（OSLog）记录每次写入的 token 数量与模式（Block vs Allow）。
2. 在 `TimerActivityUtil.getTimerActivity` 未识别的 `deviceActivityId` 时记录告警日志（便于排查版本/命名兼容问题）。

## 9) What to learn next
- 推荐继续看：
  - `Foqos/Utils/AppBlockerUtil.swift`（selection → store 映射）
  - `FoqosShieldConfig/ShieldConfigurationExtension.swift`（Shield UI）
  - `Foqos/Models/Timers/TimerActivityUtil.swift`（后台回调如何路由到限制写入）
- Unconfirmed：若要处理用户在 Shield 上点按钮的行为，需要 `ShieldActionDelegate` 扩展（本仓库当前未实现）。
  - How to confirm：搜索 `ShieldActionDelegate`（当前为 0 matches）。
