# DeviceActivityReport

## 1) Class summary
`DeviceActivityReport` 是一个 SwiftUI `View`，用于展示“经过隐私保护的 device activity 报告”。当 app 创建 `DeviceActivityReport(context, filter:)` 时，系统会调用你的 device activity report extension（`com.apple.deviceactivityui.report-extension`）来生成实际渲染内容。

> 证据说明：在当前 Xcode iPhoneSimulator SDK 中，SwiftUI 相关接口出现在 `_DeviceActivity_SwiftUI.framework` 的 `.swiftinterface`（而不是 `DeviceActivity.framework` 的主 interface）中。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- iOS SDK 形态证据（_DeviceActivity_SwiftUI.framework）：
  - `.../_DeviceActivity_SwiftUI.framework/.../arm64-apple-ios-simulator.swiftinterface` 包含：
    - `public struct DeviceActivityReport : View`
    - `public init(_ context: DeviceActivityReport.Context, filter: DeviceActivityFilter = DeviceActivityFilter())`
    - `public protocol DeviceActivityReportExtension`、`DeviceActivityReportScene`、`DeviceActivityResults` 等。
- 项目中没有 report extension（Confirmed by repo search）：
  - `foqos.xcodeproj/project.pbxproj` 中未发现 `com.apple.deviceactivityui.report-extension`。
  - Swift 代码中也未发现 `DeviceActivityReport` / `DeviceActivityReportScene` / `DeviceActivityReportExtension` 的实现。
- 项目已有“相关但不同的 extension”实现（Confirmed）：
  - DeviceActivity monitor extension：`com.apple.deviceactivity.monitor-extension`（`FoqosDeviceMonitor/Info.plist`）。
  - Shield configuration extension：`com.apple.ManagedSettingsUI.shield-configuration-service`（`FoqosShieldConfig/Info.plist`）。

### Unconfirmed
- 项目是否计划增加“使用数据报告/洞察”UI。

### How to confirm
- 在 `foqos.xcodeproj/project.pbxproj` 搜：`com.apple.deviceactivityui.report-extension`。
- 在代码里搜：`DeviceActivityReportScene`。

## 3) Entry points

### UI entry（views/screens）
- 若实现后：在任意 SwiftUI View 里直接使用：`DeviceActivityReport(context, filter: filter)`。

### Non-UI entry
- Report extension entry（系统调用）：
  - extension point identifier：`com.apple.deviceactivityui.report-extension`（需你新增 target 并配置）。
  - 你的 extension 通过 `DeviceActivityReportExtension.body` 提供一个或多个 scene（按 context 匹配）。

## 4) Data flow

### State owners
- App 侧：持有 `context` 与 `filter`（通常是 `@State`）。
- System：根据 filter 提供 `DeviceActivityResults<DeviceActivityData>`。
- Extension：
  - `DeviceActivityReportScene.makeConfiguration(representing:) async` 把 results 转换成自己的配置模型。
  - `content(configuration)` 渲染 SwiftUI UI。

### Persistence
- Unconfirmed：report extension 是否允许/适合读写 App Group 数据。
- How to confirm：查看 Apple 文档对 report extension 沙盒与数据访问的限制。

### Network calls
- Unconfirmed（但高度相关）：接口注释（你提供的片段）提到 report extension sandbox 阻止网络。
- How to confirm：在 report extension 中尝试网络请求观察是否被系统拒绝；或查 Apple 文档。

## 5) Key Apple frameworks/APIs
- `_DeviceActivity_SwiftUI.DeviceActivityReport`（SwiftUI view）。
- `DeviceActivity.DeviceActivityFilter` / `DeviceActivity.DeviceActivityData`（数据与筛选来自 DeviceActivity.framework）。
- `FamilyControls` 授权（项目已实现）：`AuthorizationCenter.shared.requestAuthorization(for: .individual)`。

## 6) Edge cases & pitfalls
- 上下文匹配：`DeviceActivityReport.Context` 只是 `RawRepresentable(String)`；extension 必须提供对应 context 的 scene，否则可能显示为空或默认。
- 沙盒限制（Unconfirmed，但常见）：report extension 通常不能网络、不能把敏感数据导出。
- 性能：`makeConfiguration(representing:)` 是 async，可能需要做增量聚合，避免每次全量遍历导致卡顿。

## 7) How to validate

### Manual steps
1. 在 Xcode 新增一个 Device Activity Report Extension target（需要在工程里操作；本仓库当前不存在该 target）。
2. 在 extension 中实现一个最简单 scene：
   - `makeConfiguration` 里统计总时长。
   - `content` 里显示一个 `Text`。
3. 在 app 中新增一个 debug 页面展示 `DeviceActivityReport`。
4. 真机运行并授权 `FamilyControls`，观察 report 是否能加载数据。

### Suggested tests
- Unit：对“从 DeviceActivityResults 聚合出 configuration”的逻辑做单测（把聚合抽成纯函数）。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
本项目当前未实现 `DeviceActivityReport`。以下为“可执行”的最小实现计划（需要你在 Xcode 中新增 target）：

Step-by-step（最小可用）：
1. 新增 target：Device Activity Report Extension。
   - 产物：一个新的 extension 目录（例如 `FoqosDeviceActivityReport/`，名称以你创建的为准）。
   - 配置 extension point 为 `com.apple.deviceactivityui.report-extension`。
2. 在 extension 中实现 `DeviceActivityReportExtension`：
   - 定义一个 `DeviceActivityReport.Context`（例如 `"basic"`）。
   - 提供一个 scene，`context = .init("basic")`。
3. 实现 `makeConfiguration(representing:)`：
   - async 遍历 `DeviceActivityData.activitySegments`，聚合 `totalActivityDuration`。
4. 实现 `content(configuration)`：
   - 显示总时长与更新时间。
5. 在 app 中新增一个 debug view：
   - `DeviceActivityReport(.init("basic"), filter: DeviceActivityFilter(...))`。
6. 验证：真机授权 + 打开该 debug view，能看到数据。

最小可用边界：
- 不做图表，不做网络，不做复杂筛选 UI。

验收标准：
- report view 能显示非空配置（至少总时长/更新时间）。

## 9) What to learn next
- `DeviceActivityFilter`：如何筛出 children/devices/日期区间。
- `DeviceActivityData`：如何 async 遍历 segments/categories/apps/domains。
- 项目侧现有的“限制执行链路”：`AppBlockerUtil` + shield extension（可以把 report 作为“解释为什么被挡”的数据来源）。
