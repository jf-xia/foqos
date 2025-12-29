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

✅ 更新（已确认）：在 `iphonesimulator` 上以 `CODE_SIGNING_ALLOWED=NO` 构建 `foqos` scheme 成功，且 `FoqosShieldConfig` extension 可正常编译（未出现 `ThemeManager` 未定义错误）。因此 **ThemeManager 对该扩展是可见的**。
  - 这仍不等价于“Xcode UI 里 Compile Sources 列表一定包含它”，但至少说明当前工程配置下该引用是可编译的。

3) 文件路径大小写是否会在 CI/大小写敏感文件系统上导致构建问题？
- 工程里出现 `foqos/Info.plist`、`foqos/foqos.entitlements` 的路径写法，而仓库目录为 `Foqos/...`。

4) Universal Link / Widget URL 的最终生效域名集合是什么？
- **已确认现象**：entitlements 里是 `applinks:foqos.app`，但 Live Activity widget 里 `widgetURL` 用了 `http://www.foqos.app`（www + http）。
- **未确认影响**：这是否会导致从 Live Activity 点回 App 时无法走 Universal Link（退化成打开网页或无效跳转），需要在真机上验证。

5) 后台任务标识符 `com.foqos.backgroundprocessing` 是否与最终 bundle id 策略一致？
- 目前它出现在 [Foqos/Info.plist](../../Foqos/Info.plist) 与 [Foqos/Utils/TimersUtil.swift](../../Foqos/Utils/TimersUtil.swift) 常量中，但是否需要以 bundle id 为前缀、以及是否已在开发者后台正确配置，无法从代码完全确认。

6) “习惯追踪 / streak” 的计算规则与数据口径是什么？
- UI 有 HabitTracker 组件，但具体算法未在 triage 中审阅。

7) App Extension 的版本号是否应该与主 App 对齐？
- **已确认现象**：模拟器构建时出现警告：`FoqosShieldConfig`（1.0）、`FoqosWidgetExtension`（1.11）、`FoqosDeviceMonitor`（1.11）与主 App（1.28）的 `CFBundleShortVersionString` 不一致。
- **未确认影响**：这在 App Store / TestFlight 上传或审核时是否会被当作错误（通常建议一致）。

## How to confirm

- (1) iOS 最低版本：
  - 查 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj) 中 `IPHONEOS_DEPLOYMENT_TARGET`（已看到 17.6）；同时核对 README 的 Requirements 段落。
- (2) ThemeManager 在 Shield 扩展的可见性：
  - 在 Xcode 中选中 target `FoqosShieldConfig` → Build Phases → Compile Sources，确认是否包含 `ThemeManager.swift`。
  - 或者在命令行跑一次 `xcodebuild -scheme foqos -showBuildSettings` / 直接构建该 extension，观察是否有 `ThemeManager` 未定义的编译错误。
- (3) 大小写敏感问题：
  - 在大小写敏感 APFS 卷上 clone 并构建，或检查 `project.pbxproj` 里相关 `path =` 的实际大小写。
- (4) Universal Links + Live Activity 回跳：
  - 代码侧确认：`FoqosWidget/FoqosWidgetLiveActivity.swift` 的 `.widgetURL(...)` 用的 URL。
  - 配置侧确认：entitlements 的 Associated Domains（已看到 `applinks:foqos.app`）。
  - 线上侧确认：站点 `https://foqos.app/.well-known/apple-app-site-association`（仓库里没有；需要服务器侧确认）。
  - 真机验证：在有 active Live Activity 的情况下点按回跳，观察是打开 App、打开 Safari、还是无响应。
- (5) BGTaskScheduler 标识符：
  - 检查 Apple Developer/Capabilities 配置与实际运行日志；代码侧可以从 `BGTaskSchedulerPermittedIdentifiers` 与 `BGTaskScheduler.shared.register/submit` 的 identifier 对照确认一致性。
- (6) Habit tracking：
  - 从 [Foqos/Components/Dashboard](../../Foqos/Components/Dashboard) 追踪到数据来源与计算函数。

- (7) Extension 版本号一致性：
  - 查看 [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj) 中各 target 的 `MARKETING_VERSION`。
  - 真机/上传验证：尝试 `Archive` 并在 Organizer 验证/上传时观察是否报错（需要开发者账号环境，仓库内无法确认）。

## Key takeaways

- 这几项不确定点里，(2) 与 (3) 最可能直接影响“能否构建/能否在 CI 构建”。
