**Class Summary**
- **What:** `ShieldConfiguration` / `ShieldConfigurationDataSource`（来自 `ManagedSettingsUI`），用于定义系统在对应用或网站进行 Shield（遮罩/屏蔽）时显示的视觉与文本内容。
- **Why:** 扩展提供自定义 Shield UI，使在家长/专注场景下被屏蔽的内容展示友好提示与交互按钮。

**Project Similarity Check**
- **Confirmed:**
  - `FoqosShieldConfig/ShieldConfigurationExtension.swift`：项目已实现 `ShieldConfigurationDataSource` 的子类并重写 `configuration(shielding:)` 方法来返回自定义 `ShieldConfiguration`（见 [FoqosShieldConfig/ShieldConfigurationExtension.swift](FoqosShieldConfig/ShieldConfigurationExtension.swift#L1-L200)）。
  - `Foqos/Utils/AppBlockerUtil.swift`：项目通过 `ManagedSettingsStore()` 写入 `store.shield.*`（应用/类别/域名）以触发系统的 Shield 行为（见 [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L1-L140)）。
  - `FoqosShieldConfig/Info.plist`：扩展点和 `NSExtensionPrincipalClass` 配置为 `shield-configuration-service`，指向扩展的 principal class（见 [FoqosShieldConfig/Info.plist](FoqosShieldConfig/Info.plist#L1-L20)）。
  - `FoqosShieldConfig/FoqosShieldConfig.entitlements`：包含 App Group，用于扩展与主 App 共享数据（见 [FoqosShieldConfig/FoqosShieldConfig.entitlements](FoqosShieldConfig/FoqosShieldConfig.entitlements#L1-L20)）。
  - Docs 已有关联卡：`docs/study/07-api-cards/managedsettingsstore.md` 讨论了 `ManagedSettingsStore` 与 `shield` 的写入（见 [docs/study/07-api-cards/managedsettingsstore.md](docs/study/07-api-cards/managedsettingsstore.md#L1-L140)）。
- **Unconfirmed:**
  - `ShieldActionDelegate`（处理用户在 Shield 上的按钮动作）是否在仓库中实现：未找到直接实现证据。
- **How to confirm:**
  - 在仓库根运行：
    - `rg "ShieldActionDelegate" || true`
    - `rg "shield\." || true`
  - 在 Xcode 中打开 `FoqosShieldConfig` target，检查 `Info.plist` 的 `NSExtensionPointIdentifier` 与 `NSExtensionPrincipalClass`（已在上文证据中找到）。

**Entry Points**
- **UI entry:** `FoqosShieldConfig/ShieldConfigurationExtension.swift` — 扩展（NSExtension）被系统调用以构造 Shield UI（see Info.plist 上的 `com.apple.ManagedSettingsUI.shield-configuration-service`）。
- **Non-UI entry:** 主 App 或后台逻辑通过 `ManagedSettingsStore` 写入 shield 策略来触发 Shield（见 [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L1-L140)）。

**Data Flow**
- **State owners:**
  - 用户选择/配置保存在主 App 的 `ProfileSnapshot`（`AppBlockerUtil.activateRestrictions(for:)` 接收并将选择转为 `ManagedSettingsStore` 写入）。证据见 [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L1-L140)。
- **Persistence / sharing:**
  - App Group（`group.dev.ambitionsoftware.foqos`）存在于扩展 entitlements，表明扩展与主 App 用 App Group 共享配置/资源（见 [FoqosShieldConfig/FoqosShieldConfig.entitlements](FoqosShieldConfig/FoqosShieldConfig.entitlements#L1-L20)）。
- **Network calls:**
  - 无证据表明 ShieldConfiguration 扩展可以或需要进行网络请求（扩展运行在受限沙箱中）。

**Key Apple Frameworks / APIs**
- **ManagedSettings / ManagedSettingsUI:** 用于写入系统级限制和提供 Shield UI 扩展点。项目内调用点：
  - 写入：`ManagedSettingsStore().shield.*`（见 [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L1-L140)）。
  - UI：实现 `ShieldConfigurationDataSource` 子类（见 [FoqosShieldConfig/ShieldConfigurationExtension.swift](FoqosShieldConfig/ShieldConfigurationExtension.swift#L1-L200)）。
- **UIKit / SwiftUI:** `ShieldConfiguration` 使用 `UIColor`/`UIImage`；扩展示例同时使用 SwiftUI/UIFont 工具来构造图像。

**Edge Cases & Pitfalls**
- **Entitlements & extension config:** 必须在 `Info.plist` 将 `NSExtensionPointIdentifier` 设为 `com.apple.ManagedSettingsUI.shield-configuration-service` 且 `NSExtensionPrincipalClass` 指向正确类（证据见 [FoqosShieldConfig/Info.plist](FoqosShieldConfig/Info.plist#L1-L20)）。
- **Sandbox limits:** Shield 配置扩展在沙箱中运行 — 不允许任意网络/外部资源访问。任何需要共享数据应通过 App Group 或被主 App 注入的本地资源。证据：Apple 扩展模型 + 项目 entitlements。
- **Performance:** 系统期望快速返回 `ShieldConfiguration`；长时间阻塞会导致系统使用默认外观。验证时注意不要做耗时同步工作。证据：`ManagedSettingsUI` 文档（ManagedSettings API 设计）。
- **Button actions:** 若要处理 Shield 上的按钮行为，需要实现 `ShieldActionDelegate`（或相关扩展），但仓库中未发现实现；因此交互处理是一个未闭合的点（见 Unconfirmed）。

**How to Validate**
- **Manual steps:**
  1. 在主 App 中通过 UI 或调试调用 `AppBlockerUtil.activateRestrictions(for:)`，或运行一个 profile 以写入 `ManagedSettingsStore().shield.*`（参见 [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L1-L140)）。
  2. 在运行设备/模拟器上打开被屏蔽的应用或域名，观察是否出现自定义 Shield UI（应由 `FoqosShieldConfig` 扩展提供；证据见 [FoqosShieldConfig/ShieldConfigurationExtension.swift](FoqosShieldConfig/ShieldConfigurationExtension.swift#L1-L200)）。
  3. 验证扩展的 Info.plist 已正确配置（见 [FoqosShieldConfig/Info.plist](FoqosShieldConfig/Info.plist#L1-L20)）。
- **Suggested tests:**
  - Unit test: 对 `ShieldConfigurationExtension.createCustomShieldConfiguration(for:title:)` 的输出属性进行断言（颜色、标题文案、icon 非空等）。
  - Integration: 在开发设备上激活一个最小 profile（仅阻止单一 app），打开该 app 并人工检查 Shield UI。记录屏幕截图作为验证证据。

**If NOT Found: Practice Task**
- N/A — 项目已实现 `ShieldConfigurationDataSource` 扩展并提供自定义 Shield（见 Confirmed）。

**What to Learn Next**
- **Related card:** `ManagedSettingsStore` — 查看如何从用户选择转换为写入规则（见 [docs/study/07-api-cards/managedsettingsstore.md](docs/study/07-api-cards/managedsettingsstore.md#L1-L140)）。
- **Suggested follow-ups:**
  - 实现/确认 `ShieldActionDelegate`（如果需要在 Shield 上处理按钮事件），搜索符号 `ShieldActionDelegate` 并根据需要添加扩展。
  - 检查 App Group 中共享数据的格式与同步策略（在主 App 与扩展间）。

**Key Takeaways**
- 项目已经使用 `ManagedSettingsStore().shield` 来触发 Shield，并实现了 `ShieldConfigurationDataSource` 扩展 (`FoqosShieldConfig/ShieldConfigurationExtension.swift`) 来提供自定义视觉与文案。
