# 99 Open Questions

> 只记录“目前无法从仓库文件直接证实”的点，并给出最短确认路径。

## Context

- 本文件在 triage 阶段创建，关联项目地图见 [docs/study/00-project-map.md](00-project-map.md)。

## Confirmed

- 已存在 App + 3 个扩展（Widget/DeviceActivity Monitor/Shield Config）+ Tests 的 target 定义。
  - 证据：[foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)

## Unconfirmed

1) iOS 最低版本到底是多少？
- README 声称 iOS 16.0+；但工程的 `IPHONEOS_DEPLOYMENT_TARGET` 为 17.6。

2) `FoqosShieldConfig` 扩展里 `ThemeManager.shared` 的来源是否正确？
- `ShieldConfigurationExtension` 直接引用 `ThemeManager.shared`，但 `project.pbxproj` 里出现了一个关于 `Utils/ThemeManager.swift` 的 file-system sync “exception” 线索（是否会把该文件排除出该扩展 target 尚不确定）。

3) 文件路径大小写是否会在 CI/大小写敏感文件系统上导致构建问题？
- 工程里出现 `foqos/Info.plist`、`foqos/foqos.entitlements` 的路径写法，而仓库目录为 `Foqos/...`。

4) Universal Link 的最终生效域名集合是什么？
- entitlement 里是 `applinks:foqos.app`，但 Live Activity widget 里 `widgetURL` 用了 `http://www.foqos.app`（www + http）。

5) 后台任务标识符 `com.foqos.backgroundprocessing` 是否与最终 bundle id 策略一致？
- 目前它出现在 [Foqos/Info.plist](../../Foqos/Info.plist) 与 [Foqos/Utils/TimersUtil.swift](../../Foqos/Utils/TimersUtil.swift) 常量中，但是否需要以 bundle id 为前缀、以及是否已在开发者后台正确配置，无法从代码完全确认。

6) “习惯追踪 / streak” 的计算规则与数据口径是什么？
- UI 有 HabitTracker 组件，但具体算法未在 triage 中审阅。

## How to confirm

- (1) iOS 最低版本：
  - 查 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj) 中 `IPHONEOS_DEPLOYMENT_TARGET`（已看到 17.6）；同时核对 README 的 Requirements 段落。
- (2) ThemeManager 在 Shield 扩展的可见性：
  - 在 Xcode 中选中 target `FoqosShieldConfig` → Build Phases → Compile Sources，确认是否包含 `ThemeManager.swift`。
  - 或者在命令行跑一次 `xcodebuild -scheme foqos -showBuildSettings` / 直接构建该 extension，观察是否有 `ThemeManager` 未定义的编译错误。
- (3) 大小写敏感问题：
  - 在大小写敏感 APFS 卷上 clone 并构建，或检查 `project.pbxproj` 里相关 `path =` 的实际大小写。
- (4) Universal Links：
  - 检查 Associated Domains entitlement（已看到 `applinks:foqos.app`），再核对站点的 apple-app-site-association 文件（仓库里没有；需要在服务器侧确认）。
- (5) BGTaskScheduler 标识符：
  - 检查 Apple Developer/Capabilities 配置与实际运行日志；代码侧可以从 `BGTaskSchedulerPermittedIdentifiers` 与 `BGTaskScheduler.shared.register/submit` 的 identifier 对照确认一致性。
- (6) Habit tracking：
  - 从 [Foqos/Components/Dashboard](../../Foqos/Components/Dashboard) 追踪到数据来源与计算函数。

## Key takeaways

- 这几项不确定点里，(2) 与 (3) 最可能直接影响“能否构建/能否在 CI 构建”。
