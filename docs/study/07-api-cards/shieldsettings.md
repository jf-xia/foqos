# ManagedSettings.ShieldSettings — API 学习卡

## 1) Class summary
`ShieldSettings` 描述“哪些 App / 网站应被系统用 Shield 覆盖”，并可按“全部/部分 + 例外”表达策略。Foqos 使用它来实现两种模式：
- **Block mode**：对选中的 apps/categories/domains 进行 Shield
- **Allow mode**：Shield 全部内容，但把选中的 token 作为例外（允许）

**Apple SDK 形态证据（iOS Simulator SDK）**
- 见 [docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md](docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md)
  - `ShieldSettings`：`L335`
  - `applications`：`L337`
  - `applicationCategories`：`L344`
  - `webDomains`：`L351`
  - `webDomainCategories`：`L358`
  - `ActivityCategoryPolicy`：`L232`

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- Shield 配置写入点：`Foqos/Utils/AppBlockerUtil.swift`
  - Allow mode（apps）：`store.shield.applicationCategories = .all(except: applicationTokens)`
  - Block mode（apps）：
    - `store.shield.applications = applicationTokens`
    - `store.shield.applicationCategories = .specific(categoriesTokens)`
  - Safari blocking 开关：
    - Allow mode（web）：`store.shield.webDomainCategories = .all(except: webTokens)`
    - Block mode（web）：`store.shield.webDomainCategories = .specific(categoriesTokens)` + `store.shield.webDomains = webTokens`
- 自定义 Shield UI（外观而非“哪些内容被 shield”）：`FoqosShieldConfig/ShieldConfigurationExtension.swift`
  - 子类 `ShieldConfigurationDataSource`，根据 `Application.localizedDisplayName` / `WebDomain.domain` 生成 `ShieldConfiguration`

### Unconfirmed
- `applicationCategories = .specific(categoriesTokens)` 的 token 来源与语义是否完全符合预期（项目使用 `FamilyActivitySelection.categoryTokens`；这是否同时覆盖 app 类别与 web 类别取决于系统定义）。

### How to confirm
- 搜索：`store.shield.`、`.all(except:`、`.specific(`
- 观察实际运行行为：
  - 在 Block mode 只选 categories 时，启动类别内任意 App 看是否被 Shield
  - 开关 `enableSafariBlocking` 后访问 web domains，确认 shield 的触发条件

## 3) Entry points
### UI entry（views/screens）
- `Foqos/Views/HomeView.swift`：用户触发 session start/stop 后，间接触发 shield 生效/清理（通过 `StrategyManager` → `AppBlockerUtil`）

### Non-UI entry（App Intent、extension、widget、background…）
- `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`：系统定时回调时通过 `TimerActivityUtil` 同样触发 shield 生效/清理

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- “用户选择的 token 集合”：`SharedData.ProfileSnapshot.selectedActivity`（来自 `FamilyActivitySelection`）
- “写入系统 shield 的地方”：`AppBlockerUtil.activateRestrictions(for:)`

### Persistence（UserDefaults/文件/CoreData/Keychain/App Group 等）
- `SharedData.profileSnapshots`（App Group UserDefaults）保存 `FamilyActivitySelection`，供扩展读取

### Network calls
- Confirmed：shield 设置的构建与写入未见网络调用。

## 5) Key Apple frameworks/APIs
- `ManagedSettings.ShieldSettings`
  - 用途：声明 shield 的目标（apps/web domains/categories）
  - 项目映射：Allow mode 使用 `.all(except:)`，Block mode 使用 `.specific(...)` / token set
- `FamilyControls.FamilyActivitySelection`
  - 用途：提供 `applicationTokens` / `webDomainTokens` / `categoryTokens`

## 6) Edge cases & pitfalls
- 系统上限：一次 shield 的 token 数量有限制；Allow mode 可能更容易接近上限（因为“允许集合”反而是例外列表）。
- 类别 token 的“覆盖范围”：`applicationCategories` 与 `webDomainCategories` 是两个不同的字段，项目在 Block mode 时分别设置；但 categories token 的语义与来源仍需要真机验证。
- Safari blocking 开关：项目仅在 `enableSafariBlocking` 为 true 时配置 web 的 shield。

## 7) How to validate
### Manual steps
1. 选一个 profile，只选 1–2 个 App token，开启 Block mode，启动该 App 验证出现 Shield。
2. 切换 Allow mode：只允许 1–2 个 App，其余应被 Shield（通过 `applicationCategories = .all(except:)`）。
3. 开关 `enableSafariBlocking` 并访问目标域名，验证 web shield 行为变化。

### Suggested tests
- 手工集成测试优先（Shield 行为依赖系统）。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
**本项目已存在实现**（`AppBlockerUtil` 已写入 `store.shield.*`）。

可练习的最小任务：
- 做一个纯函数 `func buildShieldSettings(from snapshot: SharedData.ProfileSnapshot) -> (apps:…, web:…)`，让映射更容易测试；但这需要重构 `AppBlockerUtil`（本卡仅作为练习建议）。

## 9) What to learn next
- `ManagedSettingsUI.ShieldConfigurationDataSource`：如何定制 shield 的 UI（本项目已实现）。
- `ManagedSettings.ShieldActionDelegate`：如何响应用户在 shield 上的按钮点击（本项目未实现）。
