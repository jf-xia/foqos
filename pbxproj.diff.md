我来分析对比这两个 Xcode 项目配置文件： 

Read [](file:///Users/jack/work/foqos/ZenBound/ZenBound.xcodeproj/project.pbxproj#1-1), lines 1 to 300

Read [](file:///Users/jack/work/foqos/foqos.xcodeproj/project.pbxproj#1-1), lines 1 to 300

让我继续读取更多配置，特别是 Build Settings 部分： 

Read [](file:///Users/jack/work/foqos/ZenBound/ZenBound.xcodeproj/project.pbxproj#300-300), lines 300 to 700

Read [](file:///Users/jack/work/foqos/foqos.xcodeproj/project.pbxproj#300-300), lines 300 to 700

让我继续读取更多 Build Settings，特别是主 App 和扩展的配置： 

Read [](file:///Users/jack/work/foqos/ZenBound/ZenBound.xcodeproj/project.pbxproj#700-700), lines 700 to 1100

Read [](file:///Users/jack/work/foqos/foqos.xcodeproj/project.pbxproj#700-700), lines 700 to 1000

让我继续读取更多配置，尤其是 Widget 和 Shield Config 的配置： 

Read [](file:///Users/jack/work/foqos/ZenBound/ZenBound.xcodeproj/project.pbxproj#1100-1100), lines 1100 to 1314

Read [](file:///Users/jack/work/foqos/foqos.xcodeproj/project.pbxproj#1000-1000), lines 1000 to 1195

现在让我查看两个项目的 entitlements 文件来完成对比： 

Read [](file:///Users/jack/work/foqos/ZenBound)

Read [](file:///Users/jack/work/foqos/ZenBound/widgetExtension.entitlements)

Read [](file:///Users/jack/work/foqos/ZenBound/ZenBound/ZenBound.entitlements)

Read [](file:///Users/jack/work/foqos/ZenBound/monitor/monitor.entitlements)

Read [](file:///Users/jack/work/foqos/ZenBound/shieldConfig/shieldConfig.entitlements)

Read [](file:///Users/jack/work/foqos/ZenBound/shieldAction/shieldAction.entitlements)

现在让我查看 foqos 的各扩展 entitlements： 

Read [](file:///Users/jack/work/foqos/FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements)

Read [](file:///Users/jack/work/foqos/FoqosShieldConfig/FoqosShieldConfig.entitlements)

现在我有了足够的信息来进行全面对比分析。

---

# 📊 Foqos vs ZenBound 项目配置对比分析

## 一、配置差异总览表

| 配置项                              | Foqos                      | ZenBound                                    | 差异说明                       |
| ----------------------------------- | -------------------------- | ------------------------------------------- | ------------------------------ |
| **Xcode 版本**                      | 16.0-16.4                  | 26.2                                        | ZenBound 使用更新的 Xcode      |
| **项目 IPHONEOS_DEPLOYMENT_TARGET** | 未在项目级设置             | 26.2                                        | ZenBound 项目级设置 iOS 26.2   |
| **主 App 最低 iOS**                 | 17.6                       | 17.6                                        | ✅ 相同                         |
| **扩展数量**                        | 3 个                       | 4 个                                        | ZenBound 多了 `shieldAction`   |
| **外部依赖包**                      | CodeScanner                | 无                                          | ZenBound 缺少 CodeScanner      |
| **主 App Framework**                | StoreKit                   | 无                                          | ZenBound 缺少 StoreKit         |
| **Swift 并发设置**                  | 无特殊设置                 | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` | ZenBound 使用 Swift 6 并发模型 |
| **App Group**                       | `group.com.lxt.foqos.data` | `group.com.zenbound.data`                   | 不同的 App Group               |
| **Bundle ID 格式**                  | `com.lxt.foqos.*`          | `com.lxt.ZenBound.*`                        | 不同的 Bundle ID               |

---

## 二、ZenBound 相对 Foqos 缺少的关键配置

### 1. 🔴 缺少的 Entitlements

| 项目        | Foqos 主 App                                         | ZenBound 主 App     | 影响                      |
| ----------- | ---------------------------------------------------- | ------------------- | ------------------------- |
| NFC 读取    | ✅ `com.apple.developer.nfc.readersession.formats`    | ❌ 缺少              | NFC 解锁功能无法使用      |
| 关联域      | ✅ `com.apple.developer.associated-domains`           | ❌ 缺少              | Universal Links 无法工作  |
| App Sandbox | ✅ `com.apple.security.app-sandbox`                   | ❌ 缺少              | App Store 审核可能有问题  |
| 文件访问    | ✅ `com.apple.security.files.user-selected.read-only` | ❌ 缺少              | 无法读取用户选择的文件    |
| APS 环境    | ❌ 无                                                 | ✅ `aps-environment` | ZenBound 多了推送通知配置 |

### 2. 🔴 缺少的 Info.plist 配置

| 配置                                          | Foqos          | ZenBound |
| --------------------------------------------- | -------------- | -------- |
| `INFOPLIST_KEY_NFCReaderUsageDescription`     | ✅              | ❌        |
| `INFOPLIST_KEY_NSCameraUsageDescription`      | ✅              | ❌        |
| `INFOPLIST_KEY_NSSupportsLiveActivities`      | ✅              | ❌        |
| `INFOPLIST_KEY_LSApplicationCategoryType`     | ✅ productivity | ❌        |
| `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` | ✅ NO           | ❌        |

### 3. 🔴 缺少的第三方依赖

```
Foqos:
├── CodeScanner (用于 QR 扫描)
└── StoreKit.framework (用于应用内购买/订阅)

ZenBound:
└── (无外部依赖)
```

### 4. 🔴 缺少的源文件共享配置

| 共享文件                                | Foqos Widget | Foqos DeviceMonitor | ZenBound Widget | ZenBound Monitor |
| --------------------------------------- | ------------ | ------------------- | --------------- | ---------------- |
| Shared.swift                            | ✅            | ✅                   | ✅               | ✅                |
| Models/Schedule.swift                   | ✅            | ✅                   | ✅               | ✅                |
| Utils/AppBlockerUtil.swift              | ✅            | ✅                   | ✅               | ✅                |
| Models/Timers/*.swift                   | ❌            | ✅                   | ❌               | ❌                |
| Utils/ThemeManager.swift (ShieldConfig) | N/A          | N/A                 | ❌               | N/A              |

**ZenBound 的 DeviceMonitor 缺少 Timer 相关文件共享！**

---

## 三、场景影响分析

### 场景 1️⃣：NFC 解锁功能

```
用户操作：使用 NFC 标签解锁被屏蔽的 App

Foqos: ✅ 正常工作
├── foqos.entitlements 包含 NFC 权限
├── Info.plist 包含使用说明
└── 依赖 CodeScanner 库支持

ZenBound: ❌ 完全无法使用
├── 缺少 NFC entitlement → 系统拒绝 NFC 访问
├── 缺少 NFCReaderUsageDescription → App Store 审核失败
└── 无 CodeScanner 依赖 → 编译时缺少 NFC 扫描 UI
```

**影响**：NFC 策略 (`PhysicalUnblockStrategy`) 在 ZenBound 上无法运行

---

### 场景 2️⃣：QR Code 解锁功能

```
用户操作：扫描 QR Code 解锁 Profile

Foqos: ✅ 正常工作
├── 使用 CodeScanner 第三方库
└── 有相机权限说明

ZenBound: ❌ 编译失败
├── 缺少 CodeScanner 依赖 → import CodeScanner 编译错误
└── 缺少 NSCameraUsageDescription → 即使修复也无法请求相机
```

**影响**：QR 策略无法编译，需要添加 SPM 依赖

---

### 场景 3️⃣：Live Activity（实时活动）

```
用户操作：开启专注模式，查看锁屏上的计时器

Foqos: ✅ 正常工作
├── NSSupportsLiveActivities = YES
├── FoqosWidgetLiveActivity.swift 编译到主 App
└── Timer 文件共享到 DeviceMonitor

ZenBound: ⚠️ 部分缺失
├── 缺少 NSSupportsLiveActivities 配置
├── DeviceMonitor 缺少 Timer 文件共享
└── 可能导致后台计时不准确
```

**影响**：Live Activity 功能可能不显示或计时异常

---

### 场景 4️⃣：跨扩展数据共享

```
数据流：主 App 保存 Profile → Widget 显示状态

Foqos: ✅ 正常
├── App Group: group.com.lxt.foqos.data
├── Shared.swift 共享到 Widget、Monitor、ShieldConfig
└── SharedData.profileSnapshots 可读写

ZenBound: ⚠️ 可能正常但需验证
├── App Group: group.com.zenbound.data (不同！)
├── Shared.swift 中的 suiteName 需要匹配
└── 如果 Shared.swift 硬编码了 foqos 的 group，数据将无法共享
```

**关键问题**：检查 Shared.swift 中的 `suiteName` 是否已更新

---

### 场景 5️⃣：App Store 提交

```
审核要求检查

Foqos: ✅ 准备就绪
├── ITSAppUsesNonExemptEncryption = NO (免加密审核)
├── LSApplicationCategoryType = productivity
├── 所有隐私权限说明完整
└── App Sandbox 已启用

ZenBound: ❌ 审核可能失败
├── 缺少加密声明 → 可能触发导出合规问题
├── 缺少分类 → App Store 分类不明
├── 缺少隐私说明 → 使用相机/NFC 时被拒
└── 缺少 App Sandbox → 可能被拒
```

---

### 场景 6️⃣：Swift 6 并发迁移

```
Swift 并发模式对比

Foqos: 传统模式
├── 无 SWIFT_DEFAULT_ACTOR_ISOLATION
├── 无 SWIFT_APPROACHABLE_CONCURRENCY
└── 需要显式标记 @MainActor

ZenBound: Swift 6 完全并发
├── SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
├── SWIFT_APPROACHABLE_CONCURRENCY = YES
├── SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES
└── 所有类型默认在 MainActor 上

潜在问题：
如果直接复制 Foqos 代码到 ZenBound，可能出现并发警告/错误
因为 ZenBound 的严格并发检查会标记更多问题
```

---

## 四、修复建议优先级

### 🔴 高优先级（阻塞性问题）

1. **添加 CodeScanner SPM 依赖** - 否则 QR 功能无法编译
2. **更新 Shared.swift 的 App Group** - 否则扩展数据共享失败
3. **添加 NFC Entitlement** - 否则 NFC 功能无法使用

### 🟡 中优先级（功能缺失）

4. **添加 StoreKit.framework** - 订阅功能需要
5. **添加 Live Activity 支持** - 锁屏计时器需要
6. **共享 Timer 文件到 DeviceMonitor** - 后台计时需要

### 🟢 低优先级（App Store 准备）

7. **添加 Info.plist 隐私说明**
8. **添加加密声明**
9. **添加 App 分类**
10. **启用 App Sandbox**

---

## 五、一键查看差异命令

如需详细 diff，可运行：

```bash
diff -u foqos.xcodeproj/project.pbxproj ZenBound/ZenBound.xcodeproj/project.pbxproj | head -200
