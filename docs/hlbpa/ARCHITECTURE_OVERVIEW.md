# Foqos 架构总览（HLBPA）

## Context

本总览基于以下仓库证据（非穷尽）：

- Xcode 工程与构建配置：`foqos.xcodeproj/project.pbxproj`
- App 与 Extension 的 `Info.plist` / entitlement：
  - `Foqos/Info.plist`、`Foqos/foqos.entitlements`
  - `FoqosDeviceMonitor/Info.plist`、`FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`
  - `FoqosShieldConfig/Info.plist`、`FoqosShieldConfig/FoqosShieldConfig.entitlements`
  - `FoqosWidget/Info.plist`、`FoqosWidget/FoqosWidgetExtension.entitlements`
- 关键入口与编排：
  - `Foqos/foqosApp.swift`
  - `Foqos/Utils/StrategyManager.swift`
  - `Foqos/Utils/AppBlockerUtil.swift`、`Foqos/Utils/DeviceActivityCenterUtil.swift`
  - `Foqos/Utils/NFCScannerUtil.swift`、`Foqos/Models/BlockedProfiles.swift`
  - `Foqos/Utils/TimersUtil.swift`、`Foqos/Utils/LiveActivityManager.swift`
- Extension 入口：
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
  - `FoqosShieldConfig/ShieldConfigurationExtension.swift`
  - `FoqosWidget/FoqosWidgetBundle.swift`
- 对外说明（功能与意图）：`README.md`

## Confirmed

```mermaid src="./diagrams/system_context.mmd" alt="System context: app, extensions, and Apple platform services"```

### 系统“对外接口面”（Interfaces In / Out）

- **用户触发入口（In）**
  - App 内手动 Start/Stop（由 `StrategyManager`/各 Strategy 触发）。
  - NFC 扫描与写入：通过 CoreNFC（`NFCScannerUtil` / `NFCWriter`）。
  - QR 扫描：通过 SPM 依赖 CodeScanner（`QRCodeBlockingStrategy`）。
  - Universal Links：`foqosApp` 监听 `.onOpenURL` 与 `NSUserActivityTypeBrowsingWeb`，并交给 `NavigationManager.handleLink`。
  - App Intents（Shortcuts/Automation）：`StartProfileIntent`、`StopProfileIntent`、`CheckSessionActiveIntent`、`CheckProfileStatusIntent`。

- **系统层输出（Out）**
  - App/Website 的屏蔽与允许列表：通过 `ManagedSettingsStore`（`AppBlockerUtil`）。
  - 计时/日程触发：通过 `DeviceActivityCenter.startMonitoring` + `DeviceActivityMonitor` Extension。
  - Shield UI：通过 `ManagedSettingsUI` 的 ShieldConfiguration Extension。
  - Live Activity：通过 ActivityKit（`LiveActivityManager`）。
  - Widget：通过 WidgetKit（`FoqosWidgetBundle`）。
  - 通知与后台任务：通过 UserNotifications + BackgroundTasks（`TimersUtil`；`BGTaskSchedulerPermittedIdentifiers` 在 `Foqos/Info.plist`）。

### Targets 与 Extension 角色

工程包含以下 targets（`project.pbxproj`）：

- **App**：`foqos`（productType: application）
- **Extensions**：
  - `FoqosDeviceMonitor`（DeviceActivity Monitor Extension）
  - `FoqosShieldConfig`（ManagedSettingsUI shield-configuration-service）
  - `FoqosWidgetExtension`（WidgetKit Extension；包含 Live Activity Widget）
- **Tests**：`foqosTests`、`foqosUITests`

### 依赖与系统框架

- **Swift Package（SPM）**：
  - `twostraws/CodeScanner`（minimumVersion: 2.5.2；`project.pbxproj`）
- **关键 Apple Frameworks（从导入与工程引用可见）**
  - FamilyControls / ManagedSettings / DeviceActivity：用于“屏蔽/允许 + 计时/日程触发”。
  - ManagedSettingsUI：用于系统 Shield 外观定制（Shield extension）。
  - CoreNFC：用于 NFC tag 扫描/写入。
  - BackgroundTasks + UserNotifications：用于后台/通知类计时提醒。
  - SwiftData：本地持久化 Profile 与 Session（`foqosApp.swift` 创建 `ModelContainer`）。
  - WidgetKit + ActivityKit：Widget 与 Live Activity。

### 数据边界与持久化策略（Data In / Out）

- **SwiftData（App 内主数据）**
  - `foqosApp.swift` 初始化 `ModelContainer(for: BlockedProfileSession.self, BlockedProfiles.self)`，并用 `.modelContainer(container)` 注入。
  - AppIntents 通过 `@Dependency(key: "ModelContainer")` 获取同一容器的 `mainContext`。

- **App Group UserDefaults（跨进程共享）**
  - `SharedData` 使用 suite：`group.dev.ambitionsoftware.foqos`（在多 target 的 entitlements 中出现）。
  - `SharedData.ProfileSnapshot`：序列化的 Profile（无 Session 对象），用于给 Extension/后台计时拿到“足够执行限制”的信息。
  - `SharedData.SessionSnapshot`：序列化的 session 状态，用于 schedule/break/timer 这类“系统触发但 App 可能不在前台”的场景。

### 关键业务流（Major Flows）

#### 1) 手动 / NFC / QR：启动或停止一个屏蔽会话

- `StrategyManager` 统一维护当前 `activeSession` 与计时（`timer`），并通过不同 `BlockingStrategy`（Manual/NFC/QR/混合/Timer）触发创建或结束会话。
- `AppBlockerUtil.activateRestrictions()` 使用 `ManagedSettingsStore` 设置：
  - App shielding（按 app tokens / category tokens）
  - WebDomain shielding + Web content filter（按 domain 列表/选择）
  - 严格模式：`denyAppRemoval`
- NFC/QR 策略包含“物理解锁”与“必须扫描原 tag/code”校验（`NFCBlockingStrategy` / `QRCodeBlockingStrategy`）。

```mermaid src="./diagrams/session_start_sequence.mmd" alt="Start/stop session end-to-end sequence"```

#### 2) 日程/计时：系统触发的开始/结束（App 不一定在前台）

- App 侧：`DeviceActivityCenterUtil.scheduleTimerActivity` 创建 `DeviceActivitySchedule` 并 `startMonitoring(...)`。
- 系统侧：到达 interval 边界时唤起 `FoqosDeviceMonitor` 的 `DeviceActivityMonitorExtension.intervalDidStart/End`。
- Extension 侧：调用 `TimerActivityUtil.start/stopTimerActivity`：
  - 从 `DeviceActivityName` 解析出 timer 类型与 profileId
  - 从 `SharedData.snapshot(profileId)` 取出 ProfileSnapshot
  - 分派给 `ScheduleTimerActivity` / `BreakTimerActivity` / `StrategyTimerActivity`
  - 最终通过 `AppBlockerUtil` 启用/关闭 `ManagedSettings` 限制，并更新 `SharedData` 里的 session 快照

```mermaid src="./diagrams/scheduled_monitoring_flow.mmd" alt="Scheduled monitoring and extension-driven enforcement flow"```

#### 3) Universal Link / NFC NDEF URL：通过 URL 触发 profile 切换

- `BlockedProfiles.getProfileDeepLink` 生成 `https://foqos.app/profile/<UUID>`。
- `NFCScannerUtil` 读取 NDEF URL payload 时只接受 `https://foqos.app/...`，并把 URL 作为 tag.url。
- `NavigationManager.handleLink` 解析 path：
  - `/profile/<id>`：设置 `profileId`（供 UI/逻辑消费）
  - `/navigate/<id>`：设置 `navigateToProfileId`

### 能力/隐私声明（Capabilities & Privacy Strings）

- App Groups：`group.dev.ambitionsoftware.foqos`（多 target entitlements）。
- Family Controls：`com.apple.developer.family-controls = true`（App 与 DeviceMonitor entitlements）。
- NFC：`com.apple.developer.nfc.readersession.formats = [TAG]`（App entitlements）。
- Associated Domains：`applinks:foqos.app`（App entitlements）。
- Info.plist 注入的隐私字符串（`project.pbxproj` build settings）：
  - `INFOPLIST_KEY_NFCReaderUsageDescription = ...`
  - `INFOPLIST_KEY_NSCameraUsageDescription = ...`
- Background tasks：
  - `BGTaskSchedulerPermittedIdentifiers` 包含 `com.foqos.backgroundprocessing`（`Foqos/Info.plist`）
  - `UIBackgroundModes` 含 `fetch` / `processing`（`Foqos/Info.plist`）

### 主要失败模式（Failure Modes at Boundaries）

- **Screen Time / FamilyControls 授权失败**：`RequestAuthorizer.requestAuthorization()` 捕获异常并把 `isAuthorized` 置为 false；外部可观察信号是“无法生效的屏蔽”。
- **DeviceActivity 监控启动失败**：`DeviceActivityCenterUtil` 在 `startMonitoring` 的 `catch` 打印错误；外部信号是“到点不触发”。
- **NFC 不可用**：`NFCScannerUtil.scan` 与 `NFCWriter.writeURL` 在 `NFCReaderSession.readingAvailable == false` 时走 onError/errorMessage。
- **物理解锁校验失败**：NFC/QR stop 流会拒绝解除并回传错误信息（策略层 onErrorMessage）。
- **Live Activities 不支持或被禁用**：`LiveActivityManager.isSupported` 检查 `areActivitiesEnabled`；不支持时只打印，不会崩溃。
- **后台任务提交失败**：`TimersUtil.scheduleBackgroundProcessing` submit 失败时打印错误；外部信号是“提醒/回调不可靠”。

## Unconfirmed

- **Widget 与主 App 如何共享/驱动 profile 选择与启动**：已确认存在 `FoqosWidgetBundle` 与 Widget target，但尚未逐文件确认 Widget 的 Intent/Provider 具体如何调用 `StartProfileIntent` 或深链。
- **“调度型会话”与 SwiftData `BlockedProfileSession` 的一致性策略**：Extension 侧用 `SharedData.SessionSnapshot` 维护 active session；App 侧用 SwiftData session。两者是否总能双向同步、以及冲突策略（例如 App 前台时 schedule 触发）尚未完整核验。
- **生产环境观测**：目前看到 `OSLog` 与 `print`，未确认是否有统一的日志/遥测上报。

## How to confirm

- Widget 触发链路：
  - 检查 `FoqosWidget/**` 下 `Widgets/`、`Providers/`、`ProfileSelectionIntent.swift` 是否调用 AppIntents 或 deep link。
- SwiftData 与 SharedData 的同步：
  - 搜索 `SharedData.createActiveSharedSession` / `SharedData.getActiveSharedSession` / `flushActiveSession` 的调用点。
  - 搜索 `StrategyManager.loadActiveSession` 内部是否“合并” shared session（当前只看到了调用入口，尚未向下追到实现末端）。
- 日志策略：
  - 搜索 `Logger(subsystem:` 与 `OSLog` 的使用范围。

## Key takeaways

- Foqos 的核心是“把用户选择的 app/web domain 转成 ManagedSettings 限制”，并通过多种触发器（手动/NFC/QR/深链/AppIntent/日程/计时）统一落到同一套 Session/Profile 模型。
- 跨进程执行（DeviceActivityMonitor / Shield / Widget）依赖 App Group 的 `SharedData` 快照来避免“Extension 访问 SwiftData”的复杂度。
- 可靠性关键点在：授权状态、DeviceActivity 监控是否成功启动、以及 Extension 触发时 ProfileSnapshot 是否存在且新鲜。

---
<small>Generated with GitHub Copilot as directed by jack</small>
