# DeviceActivityFilter

## 1) Class summary
`DeviceActivityFilter` 用来描述 device activity report 的筛选条件：包括时间分段（hourly/daily/weekly）、用户范围（children/all）、设备范围、以及 apps/categories/webDomains 的子集。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- iOS SDK 形态证据（DeviceActivity.framework）：
  - `.../DeviceActivity.framework/.../arm64-apple-ios-simulator.swiftinterface` 中存在 `public struct DeviceActivityFilter`（grep 可定位到 `public struct DeviceActivityFilter` 行）。
- 项目中没有直接使用 `DeviceActivityFilter`（Confirmed by repo search）：
  - 对 `**/*.swift` 搜索 `DeviceActivityFilter` 无命中（已做 includeIgnoredFiles 搜索）。

### Unconfirmed
- 项目未来是否会做“活动报告/洞察”（例如 profile 的使用统计）从而需要 `DeviceActivityFilter`。

### How to confirm
- 仓库内搜：`DeviceActivityFilter`。
- Xcode Targets 里是否存在 device activity report extension（通常与 `DeviceActivityReport` 一起出现）。

## 3) Entry points

### UI entry（views/screens）
- 若要显示报告：UI 会创建 `DeviceActivityReport(context, filter: ...)`，filter 即入口（当前项目未实现）。

### Non-UI entry
- Device Activity report extension 会接收系统根据 filter 产生的数据流（见 `DeviceActivityReportScene.makeConfiguration(representing:)` 的签名）。

## 4) Data flow

### State owners
- Filter 通常由 app 侧状态持有（例如 `@State var filter`），用户通过 picker 改变。

### Persistence
- Unconfirmed：是否要保存 filter（例如保存用户选择的日期范围、设备范围）。
- How to confirm：看需求是否要“下次打开仍保留筛选”。

### Network calls
- 无。

## 5) Key Apple frameworks/APIs
- `DeviceActivityFilter.SegmentInterval`：hourly/daily/weekly（DeviceActivity.framework）。
- `DeviceActivityFilter.Users` / `.Devices`：与 iCloud Family / 多设备共享相关（SDK 注释提示）。

## 6) Edge cases & pitfalls
- Children 数据权限（Confirmed, SDK 注释片段）：只有家长/监护人且通过 FamilyControls 管理儿童时才可筛 children。
- 多设备共享（Confirmed, SDK 注释片段）：用户可以在 iCloud 设置中控制设备是否共享 activity 数据。
- 日期区间精度（Confirmed, SDK 注释片段）：hourly/daily/weekly 会忽略小于对应粒度的 date components。

## 7) How to validate

### Manual steps
- 若你实现了 report：
  1. 用 `.daily(during: ...)` 等不同 segmentInterval 创建 filter。
  2. 切换 users/devices 选项（如果你的账号/设备支持）。
  3. 确认 report view 内容随 filter 更新。

### Suggested tests
- 主要是 UI/integration 验证；filter 多为 value type，单测意义有限。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
本项目当前未使用 `DeviceActivityFilter`。如果你想做最小练习（不新增 report extension 的前提下），可以先做“构造 filter 的纯数据层”：

Step-by-step：
1. 新建一个 Debug-only SwiftUI view（例如在 Debug 页面里）展示一个 `DeviceActivityFilter` 的当前值（文本化）。
2. 用 Picker 改变 segmentInterval（hourly/daily/weekly）和 apps/categories/webDomains 的集合。
3. 暂不接入 `DeviceActivityReport`，只验证 filter 构造逻辑与 UI 状态绑定。

最小可用边界：
- 不新增 extension target。

验收标准：
- 能稳定构造/更新 `DeviceActivityFilter`，UI 不崩溃。

## 9) What to learn next
- 若你要真正得到数据：需要 `DeviceActivityReport` + report extension（见对应卡片）。
