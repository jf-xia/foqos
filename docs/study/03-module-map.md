# 03 — Module Map（UI / State / Data / Side-effects）

## Context

本文件基于以下代码/配置做“可验证”的模块划分与数据流梳理：

- App 入口与依赖注入：`Foqos/foqosApp.swift`
- SwiftData 模型：`Foqos/Models/BlockedProfiles.swift`、`Foqos/Models/BlockedProfileSessions.swift`
- App Group 共享快照：`Foqos/Models/Shared.swift`
- 核心状态/业务编排：`Foqos/Utils/StrategyManager.swift`、`Foqos/Utils/NavigationManager.swift`、`Foqos/Utils/RequestAuthorizer.swift`
- OS 集成与 side-effects：
	- 屏蔽/限制：`Foqos/Utils/AppBlockerUtil.swift`
	- DeviceActivity 计划：`Foqos/Utils/DeviceActivityCenterUtil.swift`
	- DeviceActivity 触发处理：`Foqos/Models/Timers/*`、`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
	- NFC：`Foqos/Utils/NFCWriter.swift`
	- Live Activities：`Foqos/Utils/LiveActivityManager.swift`、`FoqosWidget/FoqosWidgetLiveActivity.swift`
	- StoreKit Tip：`Foqos/Utils/TipManager.swift`
	- BackgroundTasks + 通知：`Foqos/Utils/TimersUtil.swift`
	- App Intents：`Foqos/Intents/*`
	- Widget：`FoqosWidget/*`（尤其是 `Providers/ProfileControlProvider.swift`）
- 能力/权限（entitlements）与后台能力（Info.plist）：
	- `Foqos/foqos.entitlements`、`Foqos/Info.plist`
	- `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`
	- `FoqosShieldConfig/FoqosShieldConfig.entitlements`
	- `FoqosWidget/FoqosWidgetExtension.entitlements`

## Confirmed

### 1) Module list（逻辑模块，不等同 SwiftPM module）

> 说明格式：职责 / 关键文件 / 输入 → 输出

#### A. App Composition（入口、依赖注入、环境对象）

- 职责：
	- 构建 SwiftData `ModelContainer`（`BlockedProfileSession` + `BlockedProfiles`）
	- 注册后台任务
	- 注入全局 `EnvironmentObject`（授权、导航、策略、NFC、评分、主题、Live Activity、Tip）
	- 处理 universal link（`onOpenURL` 与 `onContinueUserActivity`）
- 关键文件：
	- `Foqos/foqosApp.swift`
- 输入 → 输出：
	- 输入：系统启动、Universal Link URL
	- 输出：根视图 `HomeView()`，环境对象树，SwiftData 容器注入（`.modelContainer(container)`），导航事件（转交给 `NavigationManager`）

#### B. UI Root & Screen Orchestration（Home 作为“集成点”）

- 职责：
	- 读取 SwiftData 中的 profiles/sessions 并渲染 dashboard
	- 监听导航 manager 与授权状态变化，触发 session start/stop 与路由
	- 在场景切换（active/background）时加载/卸载 app 状态
	- 以 sheet/fullScreenCover 组织功能页面（Intro/Support/Settings/Emergency/Profile 编辑/Stats/Debug）
- 关键文件：
	- `Foqos/Views/HomeView.swift`
- 输入 → 输出：
	- 输入：`@Query`（profiles、sessions）、`@EnvironmentObject`（`RequestAuthorizer`/`StrategyManager`/`NavigationManager`/`RatingManager`）、scenePhase
	- 输出：UI 更新、对 `StrategyManager` 的调用（例如 break toggle / deep link session 切换）

#### C. Navigation & Deep Links（Universal Link → 业务动作/路由）

- 职责：解析 URL path，将 `profileId` 与动作类型（profile / navigate）发布给 UI
- 关键文件：
	- `Foqos/Utils/NavigationManager.swift`
	- 入口接线：`Foqos/foqosApp.swift`（`handleUniversalLink`）
	- UI 消费：`Foqos/Views/HomeView.swift`（`.onChange(of: navigationManager.profileId / navigateToProfileId)`）
- 输入 → 输出：
	- 输入：`https://foqos.app/profile/<uuid>` 或 `https://foqos.app/navigate/<uuid>`
	- 输出：`NavigationManager.profileId` / `navigateToProfileId` + `link`

#### D. Authorization（FamilyControls 授权门）

- 职责：请求并暴露 FamilyControls 授权状态，驱动 Intro 屏是否出现
- 关键文件：
	- `Foqos/Utils/RequestAuthorizer.swift`
- 输入 → 输出：
	- 输入：用户授权操作（`AuthorizationCenter.shared.requestAuthorization(for: .individual)`）
	- 输出：`isAuthorized`（`@Published`） + `AuthorizationStatus`

#### E. Persistence & Canonical Data（SwiftData + App Group 快照）

- 职责：
	- SwiftData：持久化 profile 与 session（app 内查询、编辑、统计）
	- App Group（UserDefaults suite）：为 Widget / 扩展共享“可序列化快照”，并共享“当前活动 session”（用于跨进程/跨 target 状态观察）
- 关键文件：
	- SwiftData 模型：`Foqos/Models/BlockedProfiles.swift`（`@Model class BlockedProfiles`）、`Foqos/Models/BlockedProfileSessions.swift`（`@Model class BlockedProfileSession`）
	- 共享快照：`Foqos/Models/Shared.swift`（`SharedData` 使用 suite `group.dev.ambitionsoftware.foqos`）
	- 快照同步点：`BlockedProfiles.createProfile/updateProfile/deleteProfile` 调用 `updateSnapshot/deleteSnapshot`
	- session 与共享状态：`BlockedProfileSession.createSession/endSession/startBreak/endBreak` 写入/更新 `SharedData.activeSharedSession`
- 输入 → 输出：
	- 输入：UI 编辑 profile、开始/结束 session、break 状态变更
	- 输出：
		- App 内：SwiftData store 更新，`@Query` 自动刷新
		- 跨 target：`SharedData.profileSnapshots` 与 `SharedData.activeSharedSession` 更新

#### F. Core State / “业务编排器”（StrategyManager）

- 职责：
	- 维护运行中 session（`activeSession`）、计时器、break 状态、错误消息
	- 统一入口：start/stop blocking、break toggle、deep link 切换 session
	- 与 Live Activity 集成（app 前台启动/更新/结束）
- 关键文件：
	- `Foqos/Utils/StrategyManager.swift`
- 输入 → 输出：
	- 输入：ModelContext、profile、deep link 的 profileId
	- 输出：
		- SwiftData：创建/更新 `BlockedProfileSession`
		- SharedData：通过 session 方法维护共享 session 快照（证据见 `BlockedProfileSession`）
		- UI：通过 `@Published` 推送状态（`elapsedTime`, `activeSession`, `errorMessage`, `showCustomStrategyView` 等）

#### G. Blocking / Restrictions（ManagedSettings 应用限制）

- 职责：基于 `SharedData.ProfileSnapshot` 把 FamilyControls 选择/域名/strict/allow 模式映射到 `ManagedSettingsStore`，启用/禁用限制
- 关键文件：
	- `Foqos/Utils/AppBlockerUtil.swift`
- 输入 → 输出：
	- 输入：profile snapshot（selectedActivity、allow/strict、domains 等）
	- 输出：`ManagedSettingsStore`（shield/webContent/denyAppRemoval）状态

#### H. DeviceActivity Scheduling（创建监控计划）

- 职责：为 schedule / break / strategy timer 创建/移除 `DeviceActivityCenter` 监控
- 关键文件：
	- `Foqos/Utils/DeviceActivityCenterUtil.swift`
- 输入 → 输出：
	- 输入：profile（含 schedule 与 strategyData 等）
	- 输出：DeviceActivity monitoring（startMonitoring/stopMonitoring）

#### I. DeviceActivity Handling（监控回调 → 执行限制/结束限制）

- 职责：
	- DeviceMonitor extension 收到 interval start/end
	- 将 `DeviceActivityName` 解析为 timer 类型 + profileId（向后兼容旧格式）
	- 从 `SharedData` 读取 profile snapshot，执行对应 TimerActivity（schedule/break/strategy）
- 关键文件：
	- Extension 入口：`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
	- Timer activity 分发：`Foqos/Models/Timers/TimerActivityUtil.swift`
	- Schedule timer：`Foqos/Models/Timers/ScheduleTimerActivity.swift`
	- TimerActivity 协议：`Foqos/Models/Timers/TimerActivity.swift`
- 输入 → 输出：
	- 输入：`DeviceActivityMonitor.intervalDidStart/intervalDidEnd` 回调
	- 输出：调用 `AppBlockerUtil.activateRestrictions/deactivateRestrictions`，并更新 `SharedData.activeSharedSession`

#### J. Widgets（Timeline + 配置 intent + deep link）

- 职责：
	- 读取 `SharedData.activeSharedSession` 与 `SharedData.profileSnapshots` 生成 widget entry
	- 根据 session 是否活跃生成更密集的 timeline entries（1..60 分钟）
	- 通过 URL 把用户导回 App（`/profile/<id>` 或 `/navigate/<id>`）
- 关键文件：
	- Widget bundle：`FoqosWidget/FoqosWidgetBundle.swift`
	- Provider：`FoqosWidget/Providers/ProfileControlProvider.swift`
	- Widget：`FoqosWidget/Widgets/ProfileControlWidget.swift`
	- 配置 intent：`FoqosWidget/ProfileSelectionIntent.swift`
- 输入 → 输出：
	- 输入：Widget 配置（profile/useProfileURL）、SharedData 快照
	- 输出：Widget timeline entries、deep link URL

#### K. Live Activities（ActivityKit）

- 职责：
	- 为运行中 session 创建/恢复/更新/结束 Live Activity
	- 使用 `@AppStorage("com.foqos.currentActivityId")` 持久化 activityId 以便重启恢复
- 关键文件：
	- App 侧管理：`Foqos/Utils/LiveActivityManager.swift`
	- Widget 侧 UI：`FoqosWidget/FoqosWidgetLiveActivity.swift`
- 输入 → 输出：
	- 输入：`BlockedProfileSession`（start/break state）
	- 输出：ActivityKit activity（request/update/end）

#### L. App Intents（Shortcuts/Automation）

- 职责：
	- 暴露“开始/停止 profile”“查询 profile 是否 active”“查询是否存在 active session”等自动化入口
	- 通过依赖注入拿到 SwiftData `ModelContainer`，在 intent 执行时读取/写入状态
- 关键文件：
	- `Foqos/Intents/StartProfileIntent.swift`
	- `Foqos/Intents/StopProfileIntent.swift`
	- `Foqos/Intents/CheckProfileStatusIntent.swift`
	- `Foqos/Intents/CheckSessionActiveIntent.swift`
	- `Foqos/Intents/BlockedProfileEntity.swift`
	- 依赖注册：`Foqos/foqosApp.swift`（向 key `"ModelContainer"` 注册 dependency）
- 输入 → 输出：
	- 输入：Intent 参数（profile entity）
	- 输出：调用 `StrategyManager.shared.startSessionFromBackground/stopSessionFromBackground/loadActiveSession` 并返回结果

#### M. NFC（写入 profile deep link）

- 职责：写 NDEF URL 到 NFC tag（并对不支持的 tag 类型给出用户可理解的错误）
- 关键文件：
	- `Foqos/Utils/NFCWriter.swift`
- 输入 → 输出：
	- 输入：URL 字符串（通常应为 `BlockedProfiles.getProfileDeepLink` 生成的 `https://foqos.app/profile/<uuid>`）
	- 输出：写入 NFC tag 或错误消息

#### N. StoreKit Tip / Rating

- 职责：
	- Tip：加载 Product、监听 Transaction updates、购买并更新已购状态
	- Rating：存在 `StoreKit` import（细节未在本文件展开）
- 关键文件：
	- `Foqos/Utils/TipManager.swift`
	- `Foqos/Utils/RatingManager.swift`（仅从搜索结果确认其使用 StoreKit）
- 输入 → 输出：
	- 输入：用户点击 Support/Donate
	- 输出：StoreKit 交易流、`TipManager.hasPurchasedTip` 驱动 UI

#### O. Background tasks + Local notifications（提醒/延迟执行）

- 职责：
	- 使用 `UNUserNotificationCenter` 调度本地通知
	- 同时用 `BGProcessingTask` 作为“冗余/韧性”机制（app 被杀后仍尝试在合适时机触发回调/取消通知）
- 关键文件：
	- `Foqos/Utils/TimersUtil.swift`
	- 允许的 BGTask id：`Foqos/Info.plist`（`BGTaskSchedulerPermittedIdentifiers`）
- 输入 → 输出：
	- 输入：调度通知（秒数/文案），以及系统触发后台 processing task
	- 输出：通知请求、`NotificationCenter` 广播 `.backgroundTaskExecuted`（userInfo 里含 taskId）

---

### 2) Data flow（canonical source of truth？状态如何到达 UI？）

#### Canonical source of truth

- App 内“结构化数据”主来源：SwiftData
	- profiles：`BlockedProfiles`（`@Model`）
	- sessions：`BlockedProfileSession`（`@Model`，并通过 relationship 绑定 profile）
	- 证据：`foqosApp.swift` 创建 `ModelContainer(for: BlockedProfileSession.self, BlockedProfiles.self)`；`HomeView` 使用 `@Query` 读取 `BlockedProfiles` 与 `BlockedProfileSession`。

- 跨 target / 跨进程共享的“投影/快照”来源：`SharedData`（App Group UserDefaults）
	- profiles 快照：`SharedData.profileSnapshots`（key: `profileSnapshots`）
	- 当前 session 快照：`SharedData.activeSharedSession`（key: `activeScheduleSession`）
	- 证据：`Shared.swift` 使用 suite `group.dev.ambitionsoftware.foqos`；Widget provider 与 timer activities 直接读写 `SharedData.*`。

#### UI 状态如何到达界面

- `foqosApp` 注入多个 `EnvironmentObject`：
	- `RequestAuthorizer`, `TipManager`, `NavigationManager`, `NFCWriter`, `RatingManager`, `StrategyManager.shared`, `LiveActivityManager.shared`, `ThemeManager.shared`
- `HomeView` 用：
	- `@Query` 从 SwiftData 取 profiles/sessions
	- `@EnvironmentObject strategyManager` 读取 `isBlocking`/`activeSession`/`elapsedTime`，并触发 start/stop/break
	- `@EnvironmentObject navigationManager` 监听 deep link 变化，转为业务动作
	- `@EnvironmentObject requestAuthorizer` 监听授权状态，决定是否展示 `IntroView`

#### session 流（水平方向：UI → State → Data → Side-effect → UI）

- UI 发起：
	- 用户在 `HomeView`/`BlockedProfileView` 等触发“开始/停止”
- `StrategyManager` 执行：
	- 写 SwiftData（创建/结束 `BlockedProfileSession`）
	- 更新共享快照（通过 `BlockedProfileSession.createSession/endSession/startBreak/endBreak` 写 `SharedData`）
	-（前台）启动/更新/结束 Live Activity（`LiveActivityManager`）
- OS 层限制生效：
	- 当由 schedule/break/strategy timer 触发时，DeviceMonitor extension 在 interval start/end 内调用 `TimerActivityUtil` → `ScheduleTimerActivity/BreakTimerActivity/StrategyTimerActivity`，最终使用 `AppBlockerUtil` 操作 `ManagedSettingsStore`
- UI 回流：
	- SwiftData 的 `@Query` 刷新 + `StrategyManager` 的 `@Published` 刷新
	- Widget 从 `SharedData` 读取并刷新 timeline

---

### 3) Side-effect boundaries（OS 集成点与权限/entitlements 约束）

#### OS 集成点（在哪里发生）

- FamilyControls 授权：`RequestAuthorizer.requestAuthorization()`
- ManagedSettings 应用限制：`AppBlockerUtil.activateRestrictions/deactivateRestrictions()`
- DeviceActivity 计划与回调：
	- 计划创建：`DeviceActivityCenterUtil.*startMonitoring`
	- 回调执行：`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift` → `TimerActivityUtil`
- Widgets：`FoqosWidget/*`（`ProfileControlProvider` 读 `SharedData`）
- Live Activities：`LiveActivityManager`（app）+ `FoqosWidgetLiveActivity`（widget UI）
- App Intents（Shortcuts）：`Foqos/Intents/*`（依赖注入 `ModelContainer` 后调用 `StrategyManager`）
- NFC 写卡：`NFCWriter`（CoreNFC）
- BackgroundTasks + Notifications：`TimersUtil`（BGTaskScheduler + UNUserNotificationCenter）
- Universal Links：`foqosApp` 处理 `onOpenURL` 与 `onContinueUserActivity`，并由 `NavigationManager` 解析 path
- StoreKit：`TipManager`（Product/Transaction）

#### 权限/entitlements（哪些 target 有哪些能力）

- App（`Foqos/foqos.entitlements`）：
	- Associated Domains：`applinks:foqos.app`
	- Family Controls：`com.apple.developer.family-controls = true`
	- NFC tag 读取格式：`com.apple.developer.nfc.readersession.formats = [TAG]`
	- App Groups：`group.dev.ambitionsoftware.foqos`
	- 文件访问：`com.apple.security.files.user-selected.read-only = true`
- DeviceMonitor extension（`FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`）：
	- Family Controls + App Groups（同上）
- ShieldConfiguration extension（`FoqosShieldConfig/FoqosShieldConfig.entitlements`）：
	- App Groups（同上）
- Widget extension（`FoqosWidget/FoqosWidgetExtension.entitlements`）：
	- App Groups（同上）

- 后台模式与 BGTask：`Foqos/Info.plist`
	- `UIBackgroundModes = [fetch, processing]`
	- `BGTaskSchedulerPermittedIdentifiers` 包含 `com.foqos.backgroundprocessing`

---

### 4) Learning order（推荐阅读顺序）

1. `Foqos/foqosApp.swift`：入口、容器、EnvironmentObject 注入、universal links、AppIntents 依赖注册
2. `Foqos/Views/HomeView.swift`：根页面如何把数据/状态/导航/授权串起来
3. SwiftData 模型：`Foqos/Models/BlockedProfiles.swift`、`Foqos/Models/BlockedProfileSessions.swift`
4. 共享快照：`Foqos/Models/Shared.swift`（理解为什么 Widget/extension 不直接读 SwiftData）
5. 核心编排：`Foqos/Utils/StrategyManager.swift`（开始/停止/break/deeplink 逻辑）
6. 限制生效：`Foqos/Utils/AppBlockerUtil.swift`（ManagedSettings 映射）
7. 计划/定时：`Foqos/Utils/DeviceActivityCenterUtil.swift` + `Foqos/Models/Timers/*`
8. 扩展入口：`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift` + `FoqosShieldConfig/ShieldConfigurationExtension.swift`
9. Widget：`FoqosWidget/Providers/ProfileControlProvider.swift` + `FoqosWidget/ProfileSelectionIntent.swift`
10. 其它 side-effects：`Foqos/Utils/NFCWriter.swift`、`Foqos/Utils/TimersUtil.swift`、`Foqos/Utils/TipManager.swift`、`Foqos/Utils/LiveActivityManager.swift`

## Unconfirmed

- `AppDependencyManager` 的定义不在 repo 内（仅在 `foqosApp.swift` 看到调用）。它可能来自 Apple 的 AppIntents 相关 API，也可能是外部/生成代码；需要通过 Xcode “Jump to Definition” 或构建确认。
- CoreNFC 常见要求在 Info.plist 提供 `NFCReaderUsageDescription`。在已检查的 `Foqos/Info.plist` 中未看到该 key；但无法排除项目使用了其它 Info.plist/xcconfig 合并或 target 特定 plist。若确实缺失，NFC 功能在真机上可能无法工作。
- Live Activities entitlement（例如 `NSSupportsLiveActivities` / ActivityKit 相关配置）未在已检查的 entitlements/plist 中直接确认；目前只能从代码 `ActivityKit` 使用推断其意图。

## How to confirm

- 确认 `AppDependencyManager` 来源：
	- 在 Xcode 打开 `Foqos/foqosApp.swift`，对 `AppDependencyManager` “Jump to Definition”。
	- 或全局搜索 `AppDependencyManager`（已知 repo 内仅出现一次）。
- 确认 NFC 隐私描述是否存在于其它 plist：
	- 搜索 `NFCReaderUsageDescription` 于整个工程（包括 target 专用 Info.plist）。
	- 在 Xcode -> target Build Settings 查看 `Info.plist File` 与是否有 build phase 注入。
- 确认 Live Activities 相关配置：
	- 检查 App target 的 capabilities/entitlements（Xcode -> Signing & Capabilities）。
	- 搜索 `NSSupportsLiveActivities`、`Supports Live Activities` 等相关 key。
- 确认 Widget/extension 是否依赖 SharedData 作为唯一数据源：
	- 搜索 `SharedData.`（Widget provider 与 timer activity util 已确认在用）。
	- 搜索 Widget target 是否有 SwiftData/ModelContainer 相关引用（目前已见主要走 SharedData）。

## Key takeaways

- App 内的数据主存储是 SwiftData（profiles + sessions），但跨 target（Widget/DeviceMonitor/Shield）依赖 App Group 的 `SharedData` 快照与共享 session。
- `StrategyManager` 是核心编排器：把 UI 事件转成 session lifecycle，并驱动 Live Activity；而 schedule/break/strategy 这类“系统定时”侧的限制生效由 DeviceMonitor extension 回调驱动。
- OS side-effects 边界很清晰：授权（FamilyControls）→ 限制映射（ManagedSettings）→ 定时（DeviceActivity）→ 跨进程共享（App Group UserDefaults）→ 展示（Widget/Live Activity）。
