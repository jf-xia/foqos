# DeviceActivityData

## 1) Class summary
`DeviceActivityData` 表示“某个用户/设备在某段时间里的活动数据”，用于 device activity report（而不是 monitor interval 回调）。它包含 segment interval、lastUpdatedDate，以及可异步遍历的 activitySegments（分类/应用/域名维度）。

## 2) Project similarity check（项目内相似实现盘点）

### Confirmed
- iOS SDK 形态证据：
  - DeviceActivity.framework：`public struct DeviceActivityData : Hashable`（可通过 swiftinterface grep 定位）。
  - `_DeviceActivity_SwiftUI.framework`：report scene 的签名中出现 `DeviceActivityResults<DeviceActivityData>`（例如 swiftinterface 中 `makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>)`）。
- 项目中没有使用 `DeviceActivityData`（Confirmed by repo search）：
  - 对 `**/*.swift` 搜索 `DeviceActivityData` 无命中（已做 includeIgnoredFiles 搜索）。

### Unconfirmed
- 项目未来是否会增加“使用数据洞察/报告”功能从而用到 `DeviceActivityData`。

### How to confirm
- 搜：`DeviceActivityData` / `DeviceActivityResults`。
- 检查是否存在 report extension target（通常会出现 `DeviceActivityReportScene.makeConfiguration(representing:)` 的实现）。

## 3) Entry points

### UI entry（views/screens）
- `DeviceActivityData` 通常不会直接被 app 读取；它会通过 report extension 的 `makeConfiguration(representing:)` 作为输入提供（SDK interface）。

### Non-UI entry
- Report extension scene：
  - `DeviceActivityReportScene.makeConfiguration(representing:)`（在 `_DeviceActivity_SwiftUI` swiftinterface 可见）。

## 4) Data flow

### State owners
- System 根据 filter 生成数据并以 `DeviceActivityResults<DeviceActivityData>` 的形式提供给 extension。
- Extension 把 data 转换成自己的 `Configuration`（你的 view model）并渲染。

### Persistence
- Unconfirmed：report extension 内通常只做计算与展示，不建议持久化敏感数据。
- How to confirm：查看 `_DeviceActivity_SwiftUI` interface 对 report extension 的沙盒/隐私限制说明（Apple 文档/注释）。

### Network calls
- Unconfirmed：Apple 文档通常强调 report extension 禁止网络。
- How to confirm：查 Apple 文档或在 extension 运行时测试网络请求是否被系统阻止。

## 5) Key Apple frameworks/APIs
- `DeviceActivityData`（DeviceActivity.framework）。
- `DeviceActivityResults<Element>`（在 `_DeviceActivity_SwiftUI` 中作为 AsyncSequence 提供遍历）。

## 6) Edge cases & pitfalls
- 隐私与沙盒（Unconfirmed，但强烈相关）：报告 extension 往往运行在更严格沙盒中。
- 异步序列消费：`DeviceActivityResults` 是 `AsyncSequence`，构造 configuration 通常需要 async 遍历并聚合。

## 7) How to validate

### Manual steps
- 实现 report extension 后：
  1. 在 `makeConfiguration(representing:)` 中对 `activitySegments` 做 async 遍历并打印计数。
  2. 在 UI 上展示聚合结果（例如每天总时长）。

### Suggested tests
- Unit：对“从 segments 聚合出 UI model”的纯函数做单测。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
本项目当前未使用 `DeviceActivityData`。最小练习建议与 `DeviceActivityReport` 配套进行：

Step-by-step：
1. 先新增 report extension target（见 `DeviceActivityReport` 卡片）。
2. 在 extension 中实现一个最简单的 scene：
   - `makeConfiguration(representing:)` 里只计算 `totalActivityDuration` 的和。
3. 用一个简单 SwiftUI view 显示“总时长”。

最小可用边界：
- 不做网络、不做持久化、不做复杂图表。

验收标准：
- 能在 report view 中看到随时间变化的聚合数值。

## 9) What to learn next
- `DeviceActivityFilter`：如何选择日期区间/分段粒度。
- `DeviceActivityReport`：如何把 filter/context 送进系统并触发 extension。
