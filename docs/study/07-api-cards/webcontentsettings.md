# ManagedSettings.WebContentSettings — API 学习卡

## 1) Class summary
`WebContentSettings` 用于配置系统级的 Web 内容过滤策略（按域名允许/阻止）。Foqos 用它实现“域名阻止/只允许域名”两种模式，并把用户输入的 domain 字符串映射为 `WebDomain(domain:)` 后写入 `ManagedSettingsStore.webContent.blockedByFilter`。

**Apple SDK 形态证据（iOS Simulator SDK）**
- 见 [docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md](docs/study/05-file-notes/apple-sdk__managedsettings__swiftinterface-evidence.md)
  - `WebContentSettings`：`L541`
  - `FilterPolicy`：`L542`
  - `blockedByFilter`：`L550`

## 2) Project similarity check（项目内相似实现盘点）
### Confirmed
- 写入点：`Foqos/Utils/AppBlockerUtil.swift`
  - `let domains = getWebDomains(from: profile)`
  - Allow mode（domains）：`store.webContent.blockedByFilter = .all(except: domains)`
  - Block mode（domains）：`store.webContent.blockedByFilter = .specific(domains)`
- domain 映射：同文件 `getWebDomains(from:)`
  - `WebDomain(domain: $0)`
- domain 来源：`SharedData.ProfileSnapshot.domains: [String]?`（见 `Foqos/Models/Shared.swift`）

### Unconfirmed
- 当 `domains` 为空集合时，`.specific([])` / `.all(except: [])` 在系统层的实际行为（可能等价于“不做过滤”，也可能触发默认策略）。

### How to confirm
- 搜索：`store.webContent.blockedByFilter`、`WebDomain(domain:`
- 真机验证：
  - `domains` 为空时启动 session，观察 Safari 是否被限制
  - `domains` 包含若干域名时访问这些域名，观察是否被拦截

## 3) Entry points
### UI entry（views/screens）
- 间接入口：用户在 `HomeView` 触发 session start/stop → `StrategyManager`/策略 → `AppBlockerUtil.activateRestrictions`。

### Non-UI entry（App Intent、extension、widget、background…）
- `DeviceActivityMonitor` 扩展在 interval start/end 时同样触发 `AppBlockerUtil`（与 shield 一致）。

## 4) Data flow
### State owners（谁持有状态、谁触发更新）
- `BlockedProfiles.domains`（SwiftData）→ 写入 snapshot：`SharedData.ProfileSnapshot.domains` → `AppBlockerUtil.getWebDomains` → `store.webContent.blockedByFilter`

### Persistence（UserDefaults/文件/CoreData/Keychain/App Group 等）
- App Group UserDefaults：`SharedData.profileSnapshots` 存 `domains`（以及 selection）

### Network calls
- Confirmed：未见网络调用。

## 5) Key Apple frameworks/APIs
- `ManagedSettings.WebContentSettings.FilterPolicy`
  - 项目使用：`.specific(Set<WebDomain>)`、`.all(except: Set<WebDomain>)`
- `ManagedSettings.WebDomain`
  - 项目使用：`WebDomain(domain: String)`（注意这不是 token 形式）

## 6) Edge cases & pitfalls
- 域名规范化：项目当前直接使用用户字符串构造 `WebDomain(domain:)`，没有做大小写/前缀/子域名规范化（是否需要取决于产品定义；当前未见代码证据）。
- 与 Shield webDomains 的关系：项目同时使用了 Shield（token 形式）与 WebContent filter（domain string 形式）；两者作用域/触发条件不同，排障时需要区分。

## 7) How to validate
### Manual steps
1. 在 profile 中设置 `domains`（至少 1 个，例如 `example.com`）。
2. 开启 Block mode（`enableAllowModeDomains == false`），访问该域名验证被拦截。
3. 开启 Allow mode domains（`enableAllowModeDomains == true`），只允许列表内域名，访问其他域名验证被拦截。

### Suggested tests
- Unit：对 `getWebDomains(from:)` 做最小单测（输入 `nil` / 空数组 / 多域名）验证输出集合。

## 8) If NOT found: Practice task（若项目内不存在：练习任务）
**本项目已存在实现**（`AppBlockerUtil` 已写入 `store.webContent.blockedByFilter`）。

可练习的最小任务：
- 增加 domain 规范化函数（例如去掉 `https://`、去掉路径，仅保留 host），并在 UI 层提示无效输入；但这需要明确产品规则。

## 9) What to learn next
- `ManagedSettings.ShieldSettings.webDomains`（token 形式）与本卡的 `WebContentSettings`（字符串域名）如何组合使用（项目两者都在用）。
