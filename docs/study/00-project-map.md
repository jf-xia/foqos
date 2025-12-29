# 00 项目地图（Project Map）— Foqos

## Context

本笔记基于以下仓库文件（有证据可回溯）：

- [README.md](../../README.md)
- [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)
- [Foqos/foqosApp.swift](../../Foqos/foqosApp.swift)
- [Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift)
- [Foqos/Utils/NavigationManager.swift](../../Foqos/Utils/NavigationManager.swift)
- [Foqos/Utils/RequestAuthorizer.swift](../../Foqos/Utils/RequestAuthorizer.swift)
- [Foqos/Utils/StrategyManager.swift](../../Foqos/Utils/StrategyManager.swift)
- [Foqos/Utils/AppBlockerUtil.swift](../../Foqos/Utils/AppBlockerUtil.swift)
- [Foqos/Utils/NFCScannerUtil.swift](../../Foqos/Utils/NFCScannerUtil.swift)
- [Foqos/Components/Strategy/QRCodeScanner.swift](../../Foqos/Components/Strategy/QRCodeScanner.swift)
- [Foqos/Utils/TimersUtil.swift](../../Foqos/Utils/TimersUtil.swift)
- [Foqos/Utils/LiveActivityManager.swift](../../Foqos/Utils/LiveActivityManager.swift)
- [Foqos/Info.plist](../../Foqos/Info.plist)
- [Foqos/foqos.entitlements](../../Foqos/foqos.entitlements)
- [FoqosWidget/FoqosWidgetBundle.swift](../../FoqosWidget/FoqosWidgetBundle.swift)
- [FoqosWidget/FoqosWidgetLiveActivity.swift](../../FoqosWidget/FoqosWidgetLiveActivity.swift)
- [FoqosWidget/Info.plist](../../FoqosWidget/Info.plist)
- [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](../../FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift)
- [FoqosDeviceMonitor/Info.plist](../../FoqosDeviceMonitor/Info.plist)
- [FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements](../../FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements)
- [FoqosShieldConfig/ShieldConfigurationExtension.swift](../../FoqosShieldConfig/ShieldConfigurationExtension.swift)
- [FoqosShieldConfig/Info.plist](../../FoqosShieldConfig/Info.plist)
- [FoqosShieldConfig/FoqosShieldConfig.entitlements](../../FoqosShieldConfig/FoqosShieldConfig.entitlements)

---

## 1) App purpose & primary user journeys

### Confirmed

- App 目的：通过“物理触发”（NFC 标签或二维码）来开始/停止专注会话，把分心应用与网站放进屏蔽清单，帮助用户建立更好的数字习惯。
  - 证据：README 的产品描述与特性列表（见 [README.md](../../README.md)）。
- 支持的核心能力（从 README 与代码交叉印证）：
  - “Profiles / Blocking sessions”（存在 Profile 与 Session 的 SwiftData 模型、HomeView 以 profiles/sessions 作为主 UI 驱动）
    - 证据：[Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift)、[Foqos/Utils/StrategyManager.swift](../../Foqos/Utils/StrategyManager.swift)
  - “NFC & QR blocking / physical unblock”（存在 CoreNFC 扫描/写入工具与 CodeScanner 扫码组件，且策略管理器包含 NFC/QR 相关策略）
    - 证据：[Foqos/Utils/NFCScannerUtil.swift](../../Foqos/Utils/NFCScannerUtil.swift)、[Foqos/Components/Strategy/QRCodeScanner.swift](../../Foqos/Components/Strategy/QRCodeScanner.swift)、[Foqos/Utils/StrategyManager.swift](../../Foqos/Utils/StrategyManager.swift)
  - “Website blocking”（ManagedSettingsStore.webContent / shield webDomains 设置）
    - 证据：[Foqos/Utils/AppBlockerUtil.swift](../../Foqos/Utils/AppBlockerUtil.swift)
  - “Live Activities”（存在 ActivityKit + WidgetKit 的 Live Activity widget，以及 app 侧的 LiveActivityManager）
    - 证据：[FoqosWidget/FoqosWidgetLiveActivity.swift](../../FoqosWidget/FoqosWidgetLiveActivity.swift)、[Foqos/Utils/LiveActivityManager.swift](../../Foqos/Utils/LiveActivityManager.swift)、以及工程设置中的 `INFOPLIST_KEY_NSSupportsLiveActivities`（见 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)）

### Unconfirmed

- “习惯追踪 / streak 计算”的具体算法与数据来源（UI 组件存在，但尚未审阅实现细节）。
  - 如何确认：从 [Foqos/Components/Dashboard](../../Foqos/Components/Dashboard) 与 session 模型（例如 BlockedProfileSession）开始，追踪 streak 的计算位置。

### How to confirm

- 如果想快速把握“用户到底点了什么会发生什么”，建议以 HomeView 的 action 回调为起点，顺藤摸到 StrategyManager 与各个策略类。
  - 入口：见 [Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift)。

### Key takeaways

- 这不是纯软件开关，而是把“开始/结束专注”绑定到 NFC/QR 这样的外部动作。
- 主流程围绕“Profile（配置）→ Session（会话）→ 屏蔽策略（策略/定时/物理解锁）”。

---

## 2) Entry points

### Confirmed

- App 启动入口：SwiftUI `@main` App 类型。
  - 证据：[Foqos/foqosApp.swift](../../Foqos/foqosApp.swift)
- Root view：`HomeView()`。
  - 证据：[Foqos/foqosApp.swift](../../Foqos/foqosApp.swift)、[Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift)
- 深链 / Universal Link 入口：
  - SwiftUI `onOpenURL` 与 `onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` 都会走 `NavigationManager.handleLink`。
  - `NavigationManager` 目前识别 `/<base>/<id>` 形式的路径，其中 base 支持 `profile` 与 `navigate`。
  - 证据：[Foqos/foqosApp.swift](../../Foqos/foqosApp.swift)、[Foqos/Utils/NavigationManager.swift](../../Foqos/Utils/NavigationManager.swift)

### Unconfirmed

- 是否存在 UIKit 的 AppDelegate/SceneDelegate：在已检查的入口文件中未看到；推测没有。
  - 如何确认：在仓库中搜索 `UIApplicationDelegate` / `@UIApplicationDelegateAdaptor` / `SceneDelegate`。

### How to confirm

- 运行时“收到链接后到底发生什么”：
  - `HomeView` 监听 `navigationManager.profileId`，触发 `StrategyManager.toggleSessionFromDeeplink(...)`。
  - 证据：[Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift)、[Foqos/Utils/StrategyManager.swift](../../Foqos/Utils/StrategyManager.swift)

### Key takeaways

- `NavigationManager` 只负责解析 URL 并发布状态；真正的业务动作在 `HomeView`/`StrategyManager`。

---

## 3) Project shape

### Confirmed

- Targets（来自 Xcode 工程定义）：
  - `foqos`（主 App）
  - `FoqosWidgetExtension`（WidgetKit extension）
  - `FoqosDeviceMonitor`（DeviceActivity monitor extension）
  - `FoqosShieldConfig`（ManagedSettingsUI shield configuration extension）
  - `foqosTests`（单元测试）
  - `foqosUITests`（UI 测试）
  - 证据：[foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)
- Extension point identifiers（来自各自 Info.plist）：
  - DeviceActivity monitor：`com.apple.deviceactivity.monitor-extension`
    - 证据：[FoqosDeviceMonitor/Info.plist](../../FoqosDeviceMonitor/Info.plist)
  - Shield configuration：`com.apple.ManagedSettingsUI.shield-configuration-service`
    - 证据：[FoqosShieldConfig/Info.plist](../../FoqosShieldConfig/Info.plist)
  - Widget：`com.apple.widgetkit-extension`
    - 证据：[FoqosWidget/Info.plist](../../FoqosWidget/Info.plist)
- 目录结构（高层）：
  - [Foqos](../../Foqos)（主 App：Views / Models / Components / Utils / Intents 等）
  - [FoqosWidget](../../FoqosWidget)（Widget + Live Activity）
  - [FoqosDeviceMonitor](../../FoqosDeviceMonitor)（DeviceActivity 监控扩展）
  - [FoqosShieldConfig](../../FoqosShieldConfig)（Shield UI 自定义扩展）
  - 证据：仓库目录结构与 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)

### Unconfirmed

- 文件路径大小写一致性：`project.pbxproj` 中出现了 `foqos/Info.plist`、`foqos/foqos.entitlements` 的路径写法，但仓库目录为 [Foqos](../../Foqos)。macOS 默认大小写不敏感，CI 若使用大小写敏感文件系统可能出问题。
  - 如何确认：在大小写敏感磁盘镜像上 clone 并构建，或检查 Xcode 文件引用的实际路径大小写。

### Key takeaways

- “屏蔽”能力不是单一 target 完成：主 App + 监控扩展 + Shield UI 扩展 + Widget（含 Live Activity）共同组成。

---

## 4) Key frameworks

### Confirmed

- UI：SwiftUI
  - 证据：主入口与大量视图文件；例如 [Foqos/foqosApp.swift](../../Foqos/foqosApp.swift)
- 本地持久化：SwiftData
  - 证据：`ModelContainer` 初始化于 [Foqos/foqosApp.swift](../../Foqos/foqosApp.swift)，并在视图中使用 `@Query`（见 [Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift)）。
- 屏蔽与屏幕使用时间：FamilyControls / ManagedSettings / DeviceActivity
  - 证据：
    - 授权： [Foqos/Utils/RequestAuthorizer.swift](../../Foqos/Utils/RequestAuthorizer.swift)
    - 施加屏蔽： [Foqos/Utils/AppBlockerUtil.swift](../../Foqos/Utils/AppBlockerUtil.swift)
    - DeviceActivity 扩展： [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](../../FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift)
- NFC：CoreNFC
  - 证据：[Foqos/Utils/NFCScannerUtil.swift](../../Foqos/Utils/NFCScannerUtil.swift)、以及主 target 的 `INFOPLIST_KEY_NFCReaderUsageDescription`（见 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)）
- QR 扫描：CodeScanner（SPM）
  - 证据：
    - SPM：`https://github.com/twostraws/CodeScanner`（见 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj) 与 workspace 的 Package.resolved）
    - 使用： [Foqos/Components/Strategy/QRCodeScanner.swift](../../Foqos/Components/Strategy/QRCodeScanner.swift)
- Live Activities / Widgets：ActivityKit / WidgetKit
  - 证据： [FoqosWidget/FoqosWidgetLiveActivity.swift](../../FoqosWidget/FoqosWidgetLiveActivity.swift)、[FoqosWidget/FoqosWidgetBundle.swift](../../FoqosWidget/FoqosWidgetBundle.swift)
- 后台任务：BackgroundTasks（BGTaskScheduler）
  - 证据：[Foqos/Utils/TimersUtil.swift](../../Foqos/Utils/TimersUtil.swift)、以及 [Foqos/Info.plist](../../Foqos/Info.plist) 的 `BGTaskSchedulerPermittedIdentifiers`
- App Intents（Shortcuts/自动化入口）：AppIntents
  - 证据：入口文件 import，以及 [Foqos/Intents](../../Foqos/Intents) 与 Widget 侧的 intent 文件（目录存在，具体实现未在本笔记展开）。
- 付费/打赏：StoreKit
  - 证据：工程链接 StoreKit.framework（见 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)），以及 [Foqos/Utils/TipManager.swift](../../Foqos/Utils/TipManager.swift)（未在本笔记中逐行审阅）。

### Unconfirmed

- 网络层：从已检查文件看不到独立 networking 模块；可能主要是本地能力（FamilyControls/NFC/QR），但未系统性排查。
  - 如何确认：搜索 `URLSession` / `Alamofire` / `Networking` 等关键词。

### Key takeaways

- “系统级屏蔽”链路核心是 FamilyControls/ManagedSettings/DeviceActivity + 两个扩展（monitor + shield）。
- “物理触发”链路核心是 CoreNFC + CodeScanner + 深链解析。

---

## 5) Start-here reading path（建议从这里开始读）

以下是 10 个推荐阅读点（按理解主流程的收益排序）：

1. [Foqos/foqosApp.swift](../../Foqos/foqosApp.swift)
   - 为什么：应用启动、SwiftData container 注入、Universal Link 入口都在这里。
2. [Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift)
   - 为什么：主屏 UI 与关键 actions（开始/停止/休息/深链切换）都从这里发起。
3. [Foqos/Utils/RequestAuthorizer.swift](../../Foqos/Utils/RequestAuthorizer.swift)
   - 为什么：Screen Time（FamilyControls）授权是产品能否工作的前置条件。
4. [Foqos/Utils/StrategyManager.swift](../../Foqos/Utils/StrategyManager.swift)
   - 为什么：把不同“策略”（手动/NFC/QR/定时）统一编排，并管理 active session 与 Live Activity。
5. [Foqos/Utils/AppBlockerUtil.swift](../../Foqos/Utils/AppBlockerUtil.swift)
   - 为什么：真正对系统施加屏蔽/允许策略（apps + web）的地方。
6. [Foqos/Utils/NavigationManager.swift](../../Foqos/Utils/NavigationManager.swift)
   - 为什么：深链解析规则（`/profile/<id>`、`/navigate/<id>`）定义在此。
7. [Foqos/Utils/NFCScannerUtil.swift](../../Foqos/Utils/NFCScannerUtil.swift)
   - 为什么：NFC 扫描/写入实现，包含如何从 tag 的 NDEF URL 中筛选 `https://foqos.app/...`。
8. [Foqos/Components/Strategy/QRCodeScanner.swift](../../Foqos/Components/Strategy/QRCodeScanner.swift)
   - 为什么：二维码扫描 UI 的落点（CodeScanner 集成）。
9. [Foqos/Utils/TimersUtil.swift](../../Foqos/Utils/TimersUtil.swift)
   - 为什么：后台任务与通知的调度机制（BGProcessingTask + UNUserNotification）。
10. 扩展与 Widget：
   - [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](../../FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift)
   - [FoqosShieldConfig/ShieldConfigurationExtension.swift](../../FoqosShieldConfig/ShieldConfigurationExtension.swift)
   - [FoqosWidget/FoqosWidgetBundle.swift](../../FoqosWidget/FoqosWidgetBundle.swift)
   - [FoqosWidget/FoqosWidgetLiveActivity.swift](../../FoqosWidget/FoqosWidgetLiveActivity.swift)
   - 为什么：理解“系统如何在后台维持/结束屏蔽，以及屏蔽 UI 如何呈现”。

---

## 6) Open questions

- 已将本次 triage 过程中的不确定点与待核对项记录到：
  - [docs/study/99-open-questions.md](99-open-questions.md)
