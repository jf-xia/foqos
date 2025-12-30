# FamilyControls.FamilyActivityPicker — API 学习卡

## 1) Class summary
`FamilyActivityPicker` 是一个 SwiftUI View，用于让用户在系统 UI 中选择“应用/分类/网站域名”等 Family Controls 活动对象，并将结果写入绑定的 `FamilyActivitySelection`。本项目在编辑 Profile 时使用它来配置要阻止/允许的活动集合。

**Apple SDK 形态证据（iOS Simulator SDK）**
- `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/FamilyControls.framework/Modules/FamilyControls.swiftmodule/arm64-apple-ios-simulator.swiftinterface`
  - 可 grep 锚点：`public struct FamilyActivityPicker`（本地 grep 显示在该文件第 170 行附近）

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- 直接使用 `FamilyActivityPicker(selection: $selection)`：`Foqos/Components/BlockedProfileView/AppPicker.swift`
  - 通过 `.id(refreshID)` 强制刷新 picker（项目内备注 “Updating view state because of bug in iOS...”）
  - `handleDone()` 会在超出限制时弹 alert 并阻止关闭 sheet
- picker 的呈现入口：`Foqos/Views/BlockedProfileView.swift`
  - `.sheet(isPresented: $showingActivityPicker) { AppPicker(selection: $selectedActivity, ...) }`
- selection 的展示/统计：
  - `Foqos/Components/BlockedProfileView/BlockedProfileAppSelector.swift`
  - `Foqos/Utils/FamilyActivityUtil.swift`

### Unconfirmed
- `FamilyActivityPicker` 的系统“50 项限制”规则是否精确/是否随 iOS 版本变化。
  - 项目在 UI 文案中声明了该限制，并区分 Allow/Block 模式的计数语义（见 `AppPicker` 和 `FamilyActivityUtil` 的注释/文案）。

### How to confirm
- 在仓库内搜索：`FamilyActivityPicker(`、`.familyActivityPicker(`（view modifier 形式）
- 验证 SDK 形态：
  - `grep -n "public struct FamilyActivityPicker" /Applications/Xcode.app/.../FamilyControls...swiftinterface`
- 验证限制规则：
  - 参考 Apple Family Controls 文档（或 WWDC 资料）
  - 真机上选择大量 apps/categories/domains，观察系统行为与 App 的 alert 是否一致

## 3) Entry points
### UI entry（views/screens）
- `Foqos/Views/BlockedProfileView.swift`
  - Profile 编辑页：点击 app selector 按钮 -> 打开 `AppPicker` sheet
- `Foqos/Components/BlockedProfileView/AppPicker.swift`
  - 内部包含 `FamilyActivityPicker`，并提供 Done/Refresh toolbar

### Non-UI entry（App Intent、extension、widget、background…）
- Confirmed：未发现扩展/Intent/Widget 直接呈现 `FamilyActivityPicker`。
- 说明：该组件是 SwiftUI UI 组件，通常只在主 app 前台 UI 使用。

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- `BlockedProfileView` 持有：`@State private var selectedActivity = FamilyActivitySelection()`
  - 新建/编辑 profile 时，会用 `profile?.selectedActivity` 初始化该 state
- `AppPicker` 接收绑定：`@Binding var selection: FamilyActivitySelection`
  - `FamilyActivityPicker(selection: $selection)` 更新绑定
- `BlockedProfiles.updateProfile(... selection: selectedActivity ...)` 将结果保存到 SwiftData 模型

### Persistence（UserDefaults/文件/CoreData/Keychain/App Group 等）
- Confirmed：selection 被存入 SwiftData 模型字段：`BlockedProfiles.selectedActivity: FamilyActivitySelection`（见 `Foqos/Models/BlockedProfiles.swift`）。
- Confirmed：profile 的 snapshot（含 selection）会写入 App Group UserDefaults：`Foqos/Models/Shared.swift` + `BlockedProfiles.updateSnapshot(for:)`。

### Network calls
- Confirmed：`AppPicker` 路径未发现网络调用。

## 5) Key Apple frameworks/APIs
- `FamilyControls.FamilyActivityPicker`（SwiftUI View）
  - 用途：系统隐私保护的“选取 apps/categories/domains”UI
  - 调用点：`Foqos/Components/BlockedProfileView/AppPicker.swift`
- `SwiftUI.sheet` + `NavigationStack`
  - 用途：作为编辑 profile 的 sheet 展示 picker
  - 调用点：`Foqos/Views/BlockedProfileView.swift`、`Foqos/Components/BlockedProfileView/AppPicker.swift`

## 6) Edge cases & pitfalls
- iOS bug/workaround
  - Confirmed：`AppPicker` 用 `refreshID` + `.id(refreshID)` 手动刷新 picker，并用 `Timer.publish` 周期性 toggle `updateFlag`（见 `Foqos/Components/BlockedProfileView/AppPicker.swift`）。
  - 风险：频繁刷新可能影响性能/状态一致性；也可能掩盖真正的崩溃触发条件。
- “50 limit” 的处理
  - Confirmed：当计数 `> 50` 时，`AppPicker.handleDone()` 会弹 `Over 50 App Limit` alert，阻止关闭。
  - Unconfirmed：该计数是否与系统真正限制一致（尤其 Allow mode 下 categories 展开语义）。
- 并发/线程
  - Confirmed：picker 本身在主线程 UI 使用；未发现额外并发逻辑。

## 7) How to validate
### Manual steps
1. 在 App 中进入 Profile 创建/编辑页（`BlockedProfileView`）。
2. 点击“Select Apps to Restrict/Allow”打开 `AppPicker`。
3. 在系统 picker 中选择一些 apps/categories/domains。
4. 点击右上角 Done：
   - 若未超限，应关闭 sheet 并回到 Profile 编辑。
   - 若超限，应弹出 alert。
5. 保存 Profile 后再次进入编辑，检查 selection 是否回显。

### Suggested tests
- Unit：`FamilyActivityUtil.countSelectedActivities`、`shouldShowAllowModeWarning` 的计数/规则测试。
- UI：`BlockedProfileView` -> 打开 `AppPicker` 的 sheet 展示与关闭逻辑（可用 UI 测试）。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
**本项目已存在实现**（`BlockedProfileView` + `AppPicker`）。

可选练习（保持 UX 不扩展）：
1. 在 `AppPicker` 内将“超限判断”逻辑抽到纯函数（便于测试）。
2. 增加 Debug-only 的“当前 selection breakdown”展示（项目已有 `SelectedActivityDebugCard` 可复用），但需确认不改变线上 UX。

## 9) What to learn next
- Confirmed：picker 的输出 `FamilyActivitySelection` 会驱动 `ManagedSettingsStore` 的 shield/webContent 策略。
  - 继续读：`Foqos/Utils/AppBlockerUtil.swift`
- Unconfirmed：Allow mode 下 `store.shield.applicationCategories = .all(except: applicationTokens)` 的语义与 picker 的 selection 组合是否覆盖所有预期。
- How to confirm：
  - 搜索 `enableAllowMode` 的全部分支
  - 真机验证：Allow/Block + Safari blocking + domain allow mode 的组合行为
