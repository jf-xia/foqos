# ManagedSettingsUI.ShieldConfigurationDataSource — API 学习卡

## 1) Class summary
`ShieldConfigurationDataSource` 是一个由系统调用的扩展入口点，用于在 Shield 覆盖 App/网站时提供自定义的 `ShieldConfiguration`（颜色、标题、副标题、按钮文案、icon 等）。Foqos 通过 `FoqosShieldConfig` extension 提供“品牌色 + 随机文案 + emoji 图标”的自定义 Shield UI。

**Apple SDK 形态证据（iOS Simulator SDK）**
- 见 [docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md](docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md)
  - `ShieldConfigurationDataSource` 类型：`L20`
  - `configuration(shielding application: ...)`：`L21–L22`
  - `configuration(shielding webDomain: ...)`：`L23–L24`

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- Extension principal class：`FoqosShieldConfig/ShieldConfigurationExtension.swift`
  - `class ShieldConfigurationExtension: ShieldConfigurationDataSource`
  - 覆写：
    - `configuration(shielding application: Application)`
    - `configuration(shielding application: Application, in category: ActivityCategory)`
    - `configuration(shielding webDomain: WebDomain)`
    - `configuration(shielding webDomain: WebDomain, in category: ActivityCategory)`
  - UI 构建：`createCustomShieldConfiguration(for:title:)`
    - 使用 `ThemeManager.shared.themeColor`（品牌色）
    - 用 `UIGraphicsImageRenderer` 把 emoji 渲染成 `UIImage` 作为 icon
- Extension point 配置：`FoqosShieldConfig/Info.plist`
  - `NSExtensionPointIdentifier = com.apple.ManagedSettingsUI.shield-configuration-service`
  - `NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).ShieldConfigurationExtension`

### Unconfirmed
- Shield UI 的按钮行为：本项目设置了 `primaryButtonLabel`，但没有实现 `ShieldActionDelegate` 来响应按钮点击（因此系统默认行为是什么需要真机确认）。

### How to confirm
- 搜索 `ShieldConfigurationDataSource` / `ShieldConfiguration(` / `NSExtensionPointIdentifier`。
- 真机验证：启动一个被 shield 的 App/网站，检查颜色、标题文案、按钮是否符合预期。

## 3) Entry points
### UI entry（views/screens）
- 无直接 UI 入口（这是系统 Extension 的回调入口）。

### Non-UI entry（App Intent、extension、widget、background…）
- `FoqosShieldConfig` app extension
  - 系统在需要显示 shield 时回调该 extension 的 `configuration(...)`。

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- 系统触发：当 `ManagedSettingsStore.shield` 配置命中某个 App/域名时。
- Extension 侧状态：
  - `ThemeManager.shared.themeColor`（决定背景色）
  - `getFunBlockMessage(...)` 用当天日期 + title seed 选择稳定的文案（同一天/同 title 相对稳定）

### Persistence
- Confirmed：该扩展代码中未见持久化写入（只读 `ThemeManager.shared`，但其内部是否持久化不在本卡证据范围）。

### Network calls
- Confirmed：未见网络调用。

## 5) Key Apple frameworks/APIs
- `ManagedSettingsUI.ShieldConfigurationDataSource`
  - 为什么：系统要求通过 extension 来提供 shield UI
- `ManagedSettingsUI.ShieldConfiguration`
  - 为什么：承载 UI 细节（颜色、labels、buttons、icon）
- UIKit（`UIGraphicsImageRenderer`, `UIImage`, `UIFont`）
  - 为什么：`ShieldConfiguration.icon` 使用 `UIImage?`，需要把 emoji 渲染成图片

## 6) Edge cases & pitfalls
- 运行环境：extension 不是 App 进程，避免依赖不可用的资源/权限。
- 文案/颜色安全：需要处理 `application.localizedDisplayName` / `webDomain.domain` 为 nil 的情况（项目已用 `?? "App"` / `?? "Website"`）。
- 性能：`UIGraphicsImageRenderer` 每次回调都会生成图片；如果 shield 频繁刷新，可能产生开销（是否成问题需 profiling）。

## 7) How to validate
### Manual steps
1. 确保 profile 触发 Shield（例如在 Block mode 选择一个 App）。
2. 启动被 shield 的 App，观察：背景色是否为当前主题色、标题/副标题/按钮文案是否出现。
3. 在不同 title（不同 App/域名）下，验证同一天文案是否“稳定但不同”。

### Suggested tests
- Unit（可选）：对 `stableSeed(for:)` 做确定性测试（同输入同输出）。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
**本项目已存在实现**（`FoqosShieldConfig/ShieldConfigurationExtension.swift`）。

可练习的最小任务：
- 加一个最小 `ShieldActionDelegate` extension，在用户点按钮时记录日志/触发 app 内动作（见对应 API 卡）。

## 9) What to learn next
- `ManagedSettings.ShieldActionDelegate`：响应 shield 上按钮点击（本仓库未实现）。
- `ManagedSettingsStore.shield`：哪些 token 会触发该 UI（见 `AppBlockerUtil`）。
