# Feature Card: Blocked Profiles（开始/停止阻止配置）

## 1) Feature summary

**Confirmed**
- 该功能允许用户创建“Profile”（包含要屏蔽/允许的 App、类别、网站、域名等设置），并通过“开始/停止 session”在系统层面启用/解除限制。
- 限制的执行依赖 iOS Screen Time 相关框架：App 内启动时直接设置 ManagedSettings；后台定时（Schedule/Break/Strategy Timer）则由 DeviceActivity monitor extension 触发并执行同样的限制逻辑。

**Context（inspected）**
- App 入口与依赖注入：`Foqos/foqosApp.swift`
- UI：`Foqos/Views/HomeView.swift`、`Foqos/Views/BlockedProfileListView.swift`、`Foqos/Views/BlockedProfileView.swift`
- Intent：`Foqos/Intents/StartProfileIntent.swift`、`StopProfileIntent.swift`、`CheckProfileStatusIntent.swift`
- 数据与跨进程共享：`Foqos/Models/BlockedProfiles.swift`、`Foqos/Models/BlockedProfileSessions.swift`、`Foqos/Models/Shared.swift`
- 系统限制执行：`Foqos/Utils/AppBlockerUtil.swift`
- 定时活动：`Foqos/Utils/DeviceActivityCenterUtil.swift`、`Foqos/Models/Timers/*`
- 扩展：`FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`、`FoqosShieldConfig/ShieldConfigurationExtension.swift`
- Widget：`FoqosWidget/Providers/ProfileControlProvider.swift`

**Unconfirmed**
- 该功能是否支持“网络拉取/同步 Profile”。

**How to confirm**
- 全仓搜索 `URLSession|Alamofire|GraphQL|Apollo|firebase|supabase` 以及相关 service 层。

**Key takeaways**
- Profile = 可持久化配置；Session = 运行中的阻止状态；SharedData = 扩展/Widget 的跨进程桥梁。

---

## 2) Entry points

### UI entry (views/screens)

**Confirmed**
- App 主界面：`HomeView` 展示 `BlockedProfileCarousel`，用户点击 start/stop 调用 `StrategyManager.toggleBlocking(context:activeProfile:)`。
- Profile 管理：`BlockedProfileListView` 展示列表，可新增/编辑/导出；点击编辑弹出 `BlockedProfileView(profile:)`。
- Profile 编辑：`BlockedProfileView` 用 `Form` 编辑 name、选择 App/类别/网站、Allow/Block 模式、Safari 阻止、Strict、Break、Schedule、Physical unblock（NFC/QR）等。

**How to confirm**
- 直接查看 `HomeView.strategyButtonPress`、`BlockedProfileListView` 的 `.sheet`、以及 `BlockedProfileView` 的 state/表单项。

### Non-UI entry (App Intent, background task, widget refresh, notification)

**Confirmed**
- App Intents：
  - `StartProfileIntent.perform` → `StrategyManager.startSessionFromBackground(profile.id, context:)`
  - `StopProfileIntent.perform` → `StrategyManager.stopSessionFromBackground(profile.id, context:)`
  - `CheckProfileStatusIntent.perform` → `StrategyManager.loadActiveSession` 后返回 Bool。
- DeviceActivity monitor extension：`DeviceActivityMonitorExtension.intervalDidStart/End` → `TimerActivityUtil.startTimerActivity/stopTimerActivity`。
- Widget：`ProfileControlProvider` 使用 `SharedData.getActiveSharedSession()` 和 `SharedData.profileSnapshots` 生成 widget entry，并生成 deep link（`https://foqos.app/profile/<id>` 或 `https://foqos.app/navigate/<id>`）。
- Universal link 路由：`foqosApp` 的 `.onOpenURL`/`.onContinueUserActivity` → `NavigationManager.handleLink(_:)`，再由 `HomeView.onChange` 接收并触发 `StrategyManager.toggleSessionFromDeeplink` 或导航。

**Unconfirmed**
- Reminder/通知在“session 结束后”是否一定触发（依赖系统通知权限与 TimersUtil 具体实现）。

**How to confirm**
- 阅读 `Foqos/Utils/TimersUtil.swift`、以及 `StrategyManager.scheduleReminder`/`scheduleBreakReminder` 的调用链。

**Key takeaways**
- “启动/停止”既可以来自 App UI，也可以来自 Shortcuts/App Intents；定时/扩展场景通过 SharedData + DeviceActivity 触发。

---

## 3) Data flow

**Confirmed**
- State owners
  - `StrategyManager`：维护 `activeSession`、`isBlocking`、break 状态、计时器、错误消息，并在 session 开始/结束时触发 Widget 刷新（`WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")`）。
  - SwiftData：
    - `BlockedProfiles`（Profile 配置）
    - `BlockedProfileSession`（运行记录 + break 记录）
  - `SharedData`（App Group UserDefaults）：保存 `profileSnapshots`、`activeSharedSession`、`completedScheduleSessions`，供 Widget/扩展读取。
- Persistence
  - App 内持久化：SwiftData `ModelContainer(for: BlockedProfileSession.self, BlockedProfiles.self)`。
  - 跨进程持久化：`SharedData` 使用 suite `group.dev.ambitionsoftware.foqos` 的 UserDefaults。
  - Profile 更新会更新快照：`BlockedProfiles.updateProfile(...)` 内调用 `updateSnapshot(for:)`。
- 定时/扩展侧执行逻辑
  - `DeviceActivityMonitorExtension` 收到 interval start/end 时，委托 `TimerActivityUtil`。
  - `TimerActivityUtil` 根据 activity name 的前缀/格式分派到：
    - `ScheduleTimerActivity`（兼容旧格式：rawValue 直接是 profile UUID）
    - `BreakTimerActivity`（`BreakScheduleActivity:<profileId>`）
    - `StrategyTimerActivity`（`StrategyTimerActivity:<profileId>`）
  - 各 TimerActivity 的 `start/stop` 内通过 `AppBlockerUtil.activateRestrictions/deactivateRestrictions` 启停限制，并用 `SharedData` 更新 active session/break 时间。

**Unconfirmed**
- `SharedData.profileSnapshots` 在哪些生命周期点被“全量刷新”（除了 update/delete 时）。

**How to confirm**
- 搜索 `updateSnapshot(`、`deleteSnapshot(`、`SharedData.setSnapshot` 的调用点；重点看 `BlockedProfiles.createProfile`/`updateProfile`/`deleteProfile`（后半段未在本卡完全展开）。

**Key takeaways**
- App 内靠 SwiftData 维护真相；扩展/Widget 不读 SwiftData，而读 `SharedData` 的快照。

---

## 4) Key Apple frameworks/APIs

**Confirmed**
- `FamilyControls`：请求授权（`AuthorizationCenter.shared.requestAuthorization(for: .individual)`）以及在 UI 中选择 `FamilyActivitySelection`。
- `ManagedSettings`：通过 `ManagedSettingsStore` 设置 shield 与 web content filter；Strict mode 使用 `store.application.denyAppRemoval`。
- `DeviceActivity`：`DeviceActivityCenter.startMonitoring` + `DeviceActivityMonitor` 扩展回调，承载 Schedule/Break/Strategy timer 触发。
- `ManagedSettingsUI`：Shield 配置扩展 `ShieldConfigurationDataSource` 自定义拦截界面。
- `AppIntents`：Shortcuts/Intent 入口（Start/Stop/Status）。
- `SwiftData`：本地持久化 Profile/Session。
- `WidgetKit`：Widget timeline + 通过 `WidgetCenter.reloadTimelines` 刷新。

**Key takeaways**
- 这是一个典型的 Screen Time 家族组合：FamilyControls（授权/选择）+ ManagedSettings（施加限制）+ DeviceActivity（定时触发）+ ManagedSettingsUI（展示 Shield）。

---

## 5) Edge cases & pitfalls

**Confirmed**
- 授权：未授权时限制可能无法生效；`RequestAuthorizer.isAuthorized` 驱动 Intro 屏幕展示。
- Allow Mode 的“50 项限制”陷阱：`FamilyActivityUtil` 注释指出 Allow mode 下类别会被系统展开为 app 列表后再计算限制，选几个类别也可能超限。
- Schedule 的“过新”保护：`ScheduleTimerActivity.start` 要求 `schedule.olderThan15Minutes()` 才会执行（避免刚更新 schedule 立刻触发）。
- Background stop 禁止：`StrategyManager.stopSessionFromBackground`/`toggleSessionFromDeeplink` 遇到 `disableBackgroundStops` 会拒绝停止并设置 `errorMessage`。
- Break 行为：`BreakTimerActivity.start` 会 `deactivateRestrictions`，`stop` 时再 `activateRestrictions` 并写 break end。
- Activity name 兼容：`TimerActivityUtil` 支持旧版 schedule（activity rawValue 直接是 profile UUID），但 break/strategy 依赖 `type:profileId` 格式。

**Unconfirmed**
- ManagedSettings 的设置在“多设备/多用户”下的行为差异（例如家庭共享、受管设备）。

**How to confirm**
- 需要真实设备 + Screen Time 授权环境验证；并查看 Apple 文档/限制说明（仓库内无法直接确认）。

**Key takeaways**
- 关键风险点集中在：授权状态、Allow 模式选择上限、后台停止策略、以及 schedule/break 的跨进程一致性。

---

## 6) How to validate

**Manual steps (suggested)**
- 授权流：首次启动 → Intro → 点击授权 → 回到 Home，确认 `authorizationStatus` 改变。
- 创建 Profile：Home → 新建 → 选择要阻止的 App/类别/网站 → 保存。
- 手动开始/停止：Home 的 profile 卡片点击 start → 尝试打开被屏蔽 App/网站，确认出现 Shield（自定义文案/颜色）。再 stop，确认解除。
- Deep link：在 Safari 打开 `https://foqos.app/profile/<uuid>`（用 `BlockedProfiles.getProfileDeepLink` 生成）→ 应触发 `toggleSessionFromDeeplink`。
- Schedule：在 `BlockedProfileView` 设置 schedule 为 active，并调用 `DeviceActivityCenterUtil.scheduleTimerActivity`（保存 profile 时会触发）→ 到达时间段后验证限制自动开启/关闭。
- Break：开始 session 后触发 break（UI 按钮）→ break 期间限制解除，到 break 结束后限制恢复。
- Widget：添加 widget → 选择 profile（若支持配置）→ 点击 widget deep link（profile/navigate）→ 应在 App 内切换/导航。

**Suggested tests**
- Unit
  - `NavigationManager.handleLink(_:)`：`/profile/<id>` 与 `/navigate/<id>` 解析。
  - `TimerActivityUtil.getTimerParts`：`"type:profileId"` 与旧格式 `"<uuid>"`。
- Integration
  - `BlockedProfiles.updateProfile` 是否写入 `SharedData.profileSnapshots`；`BlockedProfileSession.createSession/endSession` 是否同步 `SharedData.activeSharedSession`。

**Unconfirmed**
- 当前仓库是否已有测试 target/测试基础设施可直接落地上述测试。

**How to confirm**
- 查看 `foqos.xcodeproj/project.pbxproj` 是否存在 test targets；或检查是否有 `*Tests` 目录。

---

## 7) What to learn next

- 建议补一张卡：Schedules（专门聚焦 `DeviceActivityCenterUtil` + `ScheduleTimerActivity` 的时间计算与“15 分钟保护”原因）。
- 建议补一张卡：Strategies（NFC/QR/Timer 策略如何创建 session + 启动 strategy timer activity）。
- 建议补一张卡：Widget 控制（`ProfileSelectionIntent` + `ProfileControlProvider` + 深链路语义：profile vs navigate）。
- 相关模块索引：`docs/study/03-module-map.md`（已有对 profiles/sessions/intents 的总览）。
