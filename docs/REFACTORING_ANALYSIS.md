# Foqos 项目重构分析报告

## 📋 目录
1. [项目整体架构分析](#项目整体架构分析)
2. [核心数据流](#核心数据流)
3. [关键组件分析](#关键组件分析)
4. [代码文件详细说明](#代码文件详细说明)
5. [发现的问题与改进空间](#发现的问题与改进空间)
6. [重构计划](#重构计划)

---

## 项目整体架构分析

### 🎯 项目概述
**Foqos** 是一个 iOS 专注力/屏幕时间控制应用，利用 Apple 的 Screen Time API (`FamilyControls`、`ManagedSettings`、`DeviceActivity`) 为用户提供：
- 📱 **应用屏蔽**：支持多种策略（手动、NFC、QR码、定时器、日程）
- 🔐 **加密限制**：支持严格模式、白名单/黑名单、网页过滤
- ⏱️ **灵活计时**：支持一次性倒计时、休息间隔、自动日程
- 📡 **物理解锁**：NFC标签和二维码触发
- 🎯 **跨平台同步**：App、Extensions、Widget、Shortcuts 通过 App Group 共享状态

### 📐 架构模式

```
┌─────────────────────────────────────────────────────┐
│           iOS App + Extensions 架构                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │  Main App (foqos)                            │  │
│  ├──────────────────────────────────────────────┤  │
│  │ • foqosApp.swift - DI & 环境对象注入         │  │
│  │ • HomeView / Dashboard - UI 主界面           │  │
│  │ • StrategyManager - 会话协调器               │  │
│  │ • RequestAuthorizer - 权限管理               │  │
│  │ • Models (SwiftData) - 数据持久化            │  │
│  │ • Utils - 业务逻辑工具类                     │  │
│  │ • Intents - Shortcuts 支持                   │  │
│  └──────────────────────────────────────────────┘  │
│                        ↕                            │
│  ┌──────────────────────────────────────────────┐  │
│  │  Extensions                                   │  │
│  ├──────────────────────────────────────────────┤  │
│  │ • FoqosDeviceMonitor - 日程触发              │  │
│  │ • FoqosShieldConfig - Shield UI 定制         │  │
│  │ • FoqosWidgetExtension - Widget & LA         │  │
│  └──────────────────────────────────────────────┘  │
│                        ↕                            │
│  ┌──────────────────────────────────────────────┐  │
│  │  Shared Data (App Group UserDefaults)        │  │
│  ├──────────────────────────────────────────────┤  │
│  │ • ProfileSnapshot - 配置文件快照             │  │
│  │ • SessionSnapshot - 会话状态快照             │  │
│  │ • SharedData - 跨进程通信                    │  │
│  └──────────────────────────────────────────────┘  │
│                        ↕                            │
│  ┌──────────────────────────────────────────────┐  │
│  │  Apple System Frameworks                      │  │
│  ├──────────────────────────────────────────────┤  │
│  │ • FamilyControls - 授权 & API 访问           │  │
│  │ • ManagedSettings - 屏蔽/限制执行            │  │
│  │ • DeviceActivity - 日程监控                  │  │
│  │ • ManagedSettingsUI - Shield UI              │  │
│  │ • CoreNFC - NFC 读写                         │  │
│  │ • WidgetKit & ActivityKit - Live Activity    │  │
│  │ • BackgroundTasks - 后台任务                 │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 核心数据流

### 1️⃣ 会话启动流程（Manual / NFC / QR / Timer）

```
用户交互（按钮/NFC/二维码）
        ↓
    StrategyManager.toggleBlocking()
        ↓
    BlockingStrategy.startBlocking()  (选择合适的策略)
        ↓
    创建 BlockedProfileSession (SwiftData)
        ↓
    AppBlockerUtil.activateRestrictions()
        ↓
    ManagedSettingsStore 应用限制
        ↓
    SharedData 同步快照到 App Group
        ↓
    LiveActivityManager 启动 Live Activity
        ↓
    WidgetKit 刷新 Widget
        ↓
    DeviceActivityCenter 注册定时器 (如果有)
        ↓
    Extension 接收 intervalDidStart 回调
```

### 2️⃣ 日程触发流程（Schedule）

```
用户设定 Schedule (如 每晚10点-早6点)
        ↓
    DeviceActivityCenterUtil.scheduleTimerActivity()
        ↓
    DeviceActivitySchedule 被注册到系统
        ↓
    [系统后台监控，到达触发时间]
        ↓
    FoqosDeviceMonitor Extension 唤醒
        ↓
    DeviceActivityMonitorExtension.intervalDidStart()
        ↓
    TimerActivityUtil.startTimerActivity()
        ↓
    从 SharedData 读取 ProfileSnapshot
        ↓
    AppBlockerUtil.activateRestrictions() 应用限制
        ↓
    SharedData.SessionSnapshot 更新状态
```

### 3️⃣ 会话停止流程

```
用户点击停止 或 定时器到期
        ↓
    StrategyManager.stopSession() / Extension.intervalDidEnd()
        ↓
    验证解锁方式 (如需要 NFC/QR)
        ↓
    AppBlockerUtil.deactivateRestrictions()
        ↓
    ManagedSettingsStore 清空所有限制
        ↓
    BlockedProfileSession.endTime 标记
        ↓
    SharedData 更新为无活跃会话
        ↓
    LiveActivityManager.endSessionActivity()
        ↓
    WidgetKit 刷新 Widget
```

### 4️⃣ App Intent / Shortcuts 流程

```
用户通过 Shortcuts / Siri 触发 Intent
        ↓
    StartProfileIntent / StopProfileIntent
        ↓
    依赖注入获取 ModelContainer
        ↓
    StrategyManager.startSessionFromBackground()
        ↓
    [同 会话启动流程]
```

---

## 关键组件分析

### 📦 核心 Managers (单例 + ObservableObject)

#### 1. StrategyManager.swift
**职责**：会话生命周期协调、策略选择与调度
- `activeSession` - 当前活跃会话
- `startSession()` / `stopSession()` - 会话控制
- `toggleBlocking()` - UI 切换入口
- `toggleBreak()` - 休息模式管理
- `loadActiveSession()` - 从 SharedData 恢复会话
- 发布事件供 UI 响应

**问题**：
- 文件过大 (963 行)
- 职责过多 (策略协调 + 计时管理 + UI 状态)
- 测试困难

#### 2. RequestAuthorizer.swift
**职责**：Family Controls 授权管理
- `requestAuthorization()` - 触发授权请求
- `getAuthorizationStatus()` - 读取授权状态
- 发布 `@Published isAuthorized` 供 UI 观察

#### 3. LiveActivityManager.swift
**职责**：Live Activity 生命周期管理
- `startSessionActivity()` - 启动 Live Activity
- `updateBreakState()` - 更新休息状态
- `endSessionActivity()` - 结束活动
- 检查设备支持性

#### 4. NavigationManager.swift
**职责**：深链接和应用导航
- `handleLink()` - 处理 Universal Link
- `handleProfileDeepLink()` - 触发 Profile 切换

#### 5. TipManager.swift
**职责**：StoreKit 打赏管理

#### 6. ThemeManager.swift
**职责**：主题/颜色管理

### 🔧 工具类 (静态方法 or 单例)

#### 1. AppBlockerUtil.swift
**职责**：ManagedSettings 限制执行
- `activateRestrictions()` - 应用屏蔽配置
- `deactivateRestrictions()` - 清除所有限制
- 支持应用屏蔽、网页过滤、严格模式

#### 2. DeviceActivityCenterUtil.swift
**职责**：DeviceActivity 监控注册
- `scheduleTimerActivity()` - 注册日程监控
- `startStrategyTimerActivity()` - 一次性计时启动
- `startBreakTimerActivity()` - 休息计时启动
- 取消和管理监控任务

#### 3. TimersUtil.swift
**职责**：后台任务与通知
- `registerBackgroundTasks()` - 注册 BGTaskScheduler
- `scheduleBackgroundProcessing()` - 调度后台任务
- `scheduleNotification()` - 发送用户通知
- 处理定时提醒逻辑

#### 4. NFCScannerUtil.swift
**职责**：NFC 标签读取
- `scan()` - 启动 NFC 扫描会话
- 支持 NDEF URL 读取

#### 5. NFCWriter.swift
**职责**：NFC 标签写入
- `writeURL()` - 写入 Deep Link 到 NFC 标签

#### 6. RequestAuthorizer.swift
**职责**：权限授权
- `requestAuthorization()` - Family Controls 授权

#### 其他工具类
- `DateFormatters.swift` - 日期格式化
- `DocumentsUtil.swift` - 文件操作
- `DataExporter.swift` - 数据导出
- `ProfileInsightsUtil.swift` - 使用统计
- `RatingManager.swift` - 应用评分提示
- `FamilyActivityUtil.swift` - Family Activities 选择
- `PhysicalReader.swift` - NFC 物理解锁验证
- `FocusMessages.swift` - 提示文案

### 📊 数据模型

#### SwiftData Models

1. **BlockedProfiles.swift** (429 行)
   - `@Model class BlockedProfiles`
   - 包含: 配置名称、活动选择、策略数据、日程、限制设置
   - 关系: 1-to-Many 关系到 `BlockedProfileSession`
   - 计算属性: `activeScheduleTimerActivity`, `scheduleIsOutOfSync`

2. **BlockedProfileSession.swift** (187 行)
   - `@Model class BlockedProfileSession`
   - 包含: 开始/结束时间、休息时间、关联 Profile
   - 计算属性: `isActive`, `isBreakActive`, `duration`

3. **Schedule.swift** (88 行)
   - `Weekday` 枚举 (Sunday-Saturday)
   - `BlockedProfileSchedule` 结构体 (时间范围 + 选中日期)

4. **Shared.swift** (172 行)
   - `SharedData` 枚举 (App Group UserDefaults 管理)
   - `ProfileSnapshot` 结构体 (可序列化的 Profile 快照)
   - `SessionSnapshot` 结构体 (可序列化的 Session 快照)
   - 用于跨进程 (App ↔ Extensions) 通信

#### 策略模型 (Strategies/)

1. **BlockingStrategy.swift** - 协议定义
   ```swift
   protocol BlockingStrategy {
       var id: String { get }
       var name: String { get }
       var description: String { get }
       
       func startBlocking(context: ModelContext, profile: BlockedProfiles)
       func stopBlocking(context: ModelContext, session: BlockedProfileSession)
   }
   ```

2. 具体实现
   - `ManualBlockingStrategy` - 手动启停
   - `NFCBlockingStrategy` - NFC 读卡启停 (需要原卡解锁)
   - `QRCodeBlockingStrategy` - 二维码启停
   - `TimerBlockingStrategy` (Mixed variants) - 计时启停
   - `NFCManualBlockingStrategy` - NFC + 手动混合
   - `ShortcutTimerBlockingStrategy` - 快捷指令 + 计时

#### Timers/ 目录
- 各种计时活动的 DeviceActivityName 生成与管理

### 🎨 UI 组件

#### Components 目录结构
```
Components/
├── BlockedProfileCards/      # 配置卡片展示
├── BlockedProfileView/       # 配置编辑视图
├── Common/                   # 公共组件 (按钮、输入框等)
├── Dashboard/                # 主仪表板
├── Debug/                    # 调试工具
├── Intro/                    # 引导屏幕
├── Sessions/                 # 活跃会话展示
└── Strategy/                 # 策略选择 UI
```

### 📱 Extensions

#### 1. FoqosDeviceMonitor (DeviceActivityMonitor)
```swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName)
    override func intervalDidEnd(for activity: DeviceActivityName)
}
```
- 被系统在后台唤醒
- 调用 `TimerActivityUtil` 处理会话启停

#### 2. FoqosShieldConfig (ManagedSettingsUI)
```swift
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration
}
```
- 自定义 Shield UI 外观
- 集成主题管理和提示文案

#### 3. FoqosWidgetExtension (WidgetKit + ActivityKit)
```swift
struct FoqosWidgetBundle: WidgetBundle {
    var body: some Widget {
        ProfileControlWidget()
        FoqosWidgetLiveActivity()
    }
}
```
- 主屏幕 Widget 显示活跃 Profile
- Live Activity 用于动态岛/锁屏显示
- 支持 Quick Actions 启停会话

### 🔌 App Intents (Shortcuts Support)

1. **StartProfileIntent** - 启动指定 Profile
2. **StopProfileIntent** - 停止指定 Profile
3. **CheckSessionActiveIntent** - 检查是否有活跃会话
4. **CheckProfileStatusIntent** - 检查特定 Profile 是否活跃
5. **BlockedProfileEntity** - Profile 实体 (供 Shortcuts 选择)

---

## 代码文件详细说明

### 📄 foqosApp.swift
**行数**: 70+ 行 | **类型**: App 入口

**功能**:
- 创建 SwiftData `ModelContainer` (BlockedProfiles, BlockedProfileSession)
- 向 `AppDependencyManager` 注册 ModelContainer (供 App Intents 使用)
- 注册后台任务 (`TimersUtil.registerBackgroundTasks()`)
- 初始化所有单例 Manager 并注入为 EnvironmentObject
- 处理 Universal Link (`onOpenURL`, `onContinueUserActivity`)

**关键对象**:
```swift
@StateObject private var requestAuthorizer = RequestAuthorizer()
@StateObject private var donationManager = TipManager()
@StateObject private var navigationManager = NavigationManager()
@StateObject private var nfcWriter = NFCWriter()
@StateObject private var startegyManager = StrategyManager.shared
@StateObject private var liveActivityManager = LiveActivityManager.shared
@StateObject private var themeManager = ThemeManager.shared
```

**改进空间**:
1. AppDependencyManager 的用法有些冗余
2. 可使用 Swift Dependency 或其他 DI 框架统一管理

---

### 📄 StrategyManager.swift
**行数**: 963 行 | **类型**: 核心会话协调器

**功能**:
- 维护 `@Published activeSession` (当前活跃会话)
- 维护 `activeProfileId` (当前配置 ID)
- 维护 `isBreakActive` / `isBreakAvailable` 状态
- 提供 `toggleBlocking()` / `startSession()` / `stopSession()`
- 管理计时器与通知
- 处理紧急解锁
- 从 SharedData 同步和恢复会话

**核心方法**:
- `startSession(context, profile)` - 启动会话
- `stopSession(context, session)` - 停止会话
- `toggleBlocking(context, profile)` - 切换屏蔽状态
- `toggleBreak(context)` - 切换休息模式
- `loadActiveSession(context)` - 从 SharedData 恢复活跃会话
- `startSessionFromBackground(profileId, context)` - App Intent 入口

**状态机**:
```
Idle
  ↓ [startSession]
Active (Running)
  ├─ [toggleBreak] → Breaking
  │  ↓ [toggleBreak] → Active (Running)
  └─ [stopSession] → Idle
```

**问题**:
1. 文件太大 (963 行), 职责复杂
2. 混合了会话管理、计时管理、UI 状态
3. 缺乏单元测试
4. 与 BlockingStrategy 的交互复杂

---

### 📄 AppBlockerUtil.swift
**行数**: 110 行 | **类型**: 屏蔽执行层

**功能**:
- 包装 `ManagedSettingsStore`
- 根据 `SharedData.ProfileSnapshot` 应用限制
- 支持多种限制模式:
  - 应用屏蔽 (白名单/黑名单)
  - 网页过滤 (白名单/黑名单)
  - 严格模式 (防应用卸载)

**核心方法**:
```swift
func activateRestrictions(for profile: SharedData.ProfileSnapshot)
func deactivateRestrictions()
```

**实现细节**:
- 使用 `FamilyActivitySelection` 中的 token (appTokens, categoryTokens, webTokens)
- 根据 `enableAllowMode` 切换白名单/黑名单
- 根据 `enableStrictMode` 设置 `denyAppRemoval`

---

### 📄 RequestAuthorizer.swift
**行数**: 237 行 | **类型**: 权限管理

**功能**:
- 请求 Family Controls 授权 (Scope: .individual)
- 发布 `@Published isAuthorized` 状态
- 获取系统授权状态 (`getAuthorizationStatus()`)
- 处理授权请求的异步逻辑

**核心方法**:
```swift
func requestAuthorization() async
func getAuthorizationStatus() -> AuthorizationCenter.AuthorizationStatus
```

---

### 📄 DeviceActivityMonitorExtension.swift
**行数**: 40 行 | **类型**: 系统 Extension

**功能**:
- 被系统在后台唤醒 (到达 DeviceActivitySchedule 边界)
- 调用 `TimerActivityUtil.startTimerActivity()` / `stopTimerActivity()`
- 记录日志

**回调**:
```swift
override func intervalDidStart(for activity: DeviceActivityName)
override func intervalDidEnd(for activity: DeviceActivityName)
```

---

### 📄 DeviceActivityCenterUtil.swift
**行数**: 239 行 | **类型**: 日程管理

**功能**:
- 注册 DeviceActivitySchedule (日期 + 时间范围)
- 注册一次性计时 (Timer, Break)
- 取消和管理监控任务
- 获取活跃的计时活动

**核心方法**:
```swift
static func scheduleTimerActivity(for profile: BlockedProfiles)
static func startStrategyTimerActivity(for profile: BlockedProfiles)
static func startBreakTimerActivity(for profile: BlockedProfiles)
static func stopActivities(for names: [DeviceActivityName])
```

---

### 📄 TimersUtil.swift
**行数**: 264 行 | **类型**: 后台任务与通知

**功能**:
- 注册 BGTaskScheduler 后台任务
- 调度和执行后台通知
- 管理提醒与回调
- 支持重复提醒

**核心方法**:
```swift
static func registerBackgroundTasks()
func scheduleBackgroundProcessing(taskId: String, executionTime: Date)
func scheduleNotification(title: String, body: String, delayInSeconds: TimeInterval)
```

---

### 📄 LiveActivityManager.swift
**行数**: 232 行 | **类型**: Live Activity 管理

**功能**:
- 启动、更新、结束 Live Activity
- 存储 Activity ID 到 AppStorage 用于恢复
- 检查设备和系统支持
- 更新 Break 状态

**核心方法**:
```swift
func startSessionActivity(session: BlockedProfileSession)
func updateBreakState(session: BlockedProfileSession)
func endSessionActivity()
```

---

### 📄 NFCScannerUtil.swift
**行数**: ? | **类型**: NFC 读取

**功能**:
- 启动 CoreNFC 扫描会话
- 读取 NDEF URL 记录
- 验证 URL 格式 (foqos.app 域名)
- 错误处理

---

### 📄 NFCWriter.swift
**行数**: ? | **类型**: NFC 写入

**功能**:
- 写入 Deep Link 到 NFC 标签
- 支持 NDEF URL 格式
- 错误处理

---

### 📄 NavigationManager.swift
**行数**: ? | **类型**: 导航与深链接

**功能**:
- 处理 Universal Link
- 解析 Profile 深链接 (`/profile/<id>`, `/navigate/<id>`)
- 驱动 UI 导航状态

---

### 📄 BlockedProfiles.swift
**行数**: 429 行 | **类型**: 核心数据模型

**结构**:
```swift
@Model
class BlockedProfiles {
    @Attribute(.unique) var id: UUID
    var name: String
    var selectedActivity: FamilyActivitySelection
    
    // 策略配置
    var blockingStrategyId: String?
    var strategyData: Data?
    
    // 功能开关
    var enableLiveActivity: Bool
    var enableBreaks: Bool
    var enableStrictMode: Bool
    var enableAllowMode: Bool
    var enableAllowModeDomains: Bool
    var enableSafariBlocking: Bool
    
    // 限制设置
    var reminderTimeInSeconds: UInt32?
    var customReminderMessage: String?
    var breakTimeInMinutes: Int = 15
    var domains: [String]?
    
    // 物理解锁
    var physicalUnblockNFCTagId: String?
    var physicalUnblockQRCodeId: String?
    
    // 日程
    var schedule: BlockedProfileSchedule?
    
    // 关系
    @Relationship var sessions: [BlockedProfileSession] = []
}
```

**问题**:
1. 属性过多 (22+ 个), 职责不清晰
2. 混合了配置、策略、功能开关
3. 可能导致初始化参数过多

---

### 📄 BlockedProfileSession.swift
**行数**: 187 行 | **类型**: 会话数据模型

**结构**:
```swift
@Model
class BlockedProfileSession {
    @Attribute(.unique) var id: String
    var tag: String
    @Relationship var blockedProfile: BlockedProfiles
    
    var startTime: Date
    var endTime: Date?
    var breakStartTime: Date?
    var breakEndTime: Date?
    var forceStarted: Bool = false
    
    // 计算属性
    var isActive: Bool
    var isBreakAvailable: Bool
    var isBreakActive: Bool
    var duration: TimeInterval
}
```

---

### 📄 Shared.swift
**行数**: 172 行 | **类型**: 跨进程通信

**核心**:
```swift
enum SharedData {
    private static let suite = UserDefaults(
        suiteName: "group.com.lxt.foqos.data"
    )
    
    struct ProfileSnapshot: Codable {
        // 可序列化的 Profile 数据 (无 Session 关系)
    }
    
    struct SessionSnapshot: Codable {
        // 可序列化的 Session 数据 (无 Profile 对象)
    }
}
```

**职责**:
- App ↔ Extensions 通过 App Group UserDefaults 共享数据
- 快照设计避免 SwiftData 对象跨进程序列化问题

---

### 📄 Schedule.swift
**行数**: 88 行 | **类型**: 日程数据模型

**结构**:
```swift
enum Weekday: Int, CaseIterable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

struct BlockedProfileSchedule: Codable {
    var days: [Weekday]
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isActive: Bool { !days.isEmpty }
}
```

---

### 📄 BlockingStrategy.swift
**行数**: 30+ 行 | **类型**: 策略协议

```swift
protocol BlockingStrategy {
    static var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconType: String { get }
    var color: Color { get }
    var hidden: Bool { get }
    
    var onSessionCreation: ((SessionStatus) -> Void)? { get set }
    var onErrorMessage: ((String) -> Void)? { get set }
    
    func getIdentifier() -> String
    func startBlocking(context: ModelContext, profile: BlockedProfiles) -> (any View)?
    func stopBlocking(context: ModelContext, session: BlockedProfileSession) -> (any View)?
}
```

**具体实现**:
- `ManualBlockingStrategy` - 简单启停
- `NFCBlockingStrategy` - 需要 NFC 卡启停
- `QRCodeBlockingStrategy` - 需要二维码启停
- `TimerBlockingStrategy` - 计时自动停止
- 混合策略 (NFC+Manual, QR+Manual, 等)

---

### 📄 IntentFiles (Foqos/Intents/)

#### StartProfileIntent.swift
```swift
struct StartProfileIntent: AppIntent {
    @Dependency(key: "ModelContainer") var modelContainer
    @Parameter(title: "Profile") var profile: BlockedProfileEntity
    @Parameter(title: "Duration minutes") var durationInMinutes: Int?
    
    func perform() async throws -> some IntentResult {
        StrategyManager.shared.startSessionFromBackground(
            profile.id, context: modelContext, durationInMinutes: durationInMinutes
        )
        return .result()
    }
}
```

#### StopProfileIntent.swift
```swift
struct StopProfileIntent: AppIntent {
    @Dependency(key: "ModelContainer") var modelContainer
    @Parameter(title: "Profile") var profile: BlockedProfileEntity
    
    func perform() async throws -> some IntentResult {
        StrategyManager.shared.stopSessionFromBackground(profile.id, context: modelContext)
        return .result()
    }
}
```

#### CheckSessionActiveIntent.swift
```swift
struct CheckSessionActiveIntent: AppIntent {
    @Dependency(key: "ModelContainer") var modelContainer
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        strategyManager.loadActiveSession(context: modelContext)
        let isActive = strategyManager.isBlocking
        return .result(value: isActive)
    }
}
```

#### CheckProfileStatusIntent.swift
```swift
struct CheckProfileStatusIntent: AppIntent {
    @Dependency(key: "ModelContainer") var modelContainer
    @Parameter(title: "Profile") var profile: BlockedProfileEntity
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        strategyManager.loadActiveSession(context: modelContext)
        let isActive = strategyManager.activeSession?.blockedProfile.id == profile.id
        return .result(value: isActive)
    }
}
```

#### BlockedProfileEntity.swift
```swift
struct BlockedProfileEntity: AppEntity {
    let id: UUID
    let name: String
    
    static var defaultQuery = BlockedProfileQuery()
    // ... 提供 Profile 的 Shortcuts 选择列表
}
```

---

## 发现的问题与改进空间

### 🔴 高优先级问题

#### 1. **StrategyManager 文件过大且职责复杂**
- **现状**: 963 行, 混合了会话管理、计时、UI 状态、策略协调
- **影响**: 难以维护、测试、重用
- **建议**: 拆分为:
  - `SessionManager` - 会话 CRUD
  - `TimerCoordinator` - 计时逻辑
  - `BreakManager` - 休息模式
  - `EmergencyUnlock` - 紧急解锁

#### 2. **BlockedProfiles 属性过多 (22+)**
- **现状**: 包含配置、策略、功能开关、限制设置
- **影响**: 初始化复杂、维护困难
- **建议**: 拆分为:
  - `Profile` (基础配置)
  - `RestrictionConfig` (限制设置)
  - `StrategyConfig` (策略配置)
  - `BreakSettings` (休息设置)

#### 3. **缺乏清晰的依赖注入**
- **现状**: 混合使用 EnvironmentObject、单例、AppDependencyManager
- **影响**: 测试困难、依赖不清晰
- **建议**: 统一使用 Swift Dependency 或其他 DI 框架

#### 4. **SharedData 与 SwiftData 同步策略不明确**
- **现状**: 快照设计用于跨进程, 但同步时机和冲突解决方案不清楚
- **影响**: 可能数据不一致
- **建议**: 清晰定义同步规则和冲突处理

#### 5. **缺乏单元测试和集成测试**
- **现状**: 几乎没有看到测试代码
- **影响**: 重构风险高、回归风险大
- **建议**: 建立单元测试框架 (StrategyManager, AppBlockerUtil 等)

### 🟡 中优先级问题

#### 6. **错误处理不一致**
- **现状**: 混合使用 print()、OSLog、错误回调
- **影响**: 难以跟踪和调试
- **建议**: 统一日志和错误处理策略

#### 7. **UI Components 结构杂乱**
- **现状**: Components/ 下有多个子目录, 但层级和职责不清晰
- **影响**: 难以查找和维护
- **建议**: 重新组织为:
  - `Screens/` (整页视图)
  - `Features/` (功能模块)
  - `Shared/` (共用组件)

#### 8. **计时逻辑分散**
- **现状**: DeviceActivityCenterUtil, TimersUtil, StrategyManager 各自处理计时
- **影响**: 计时逻辑难以追踪
- **建议**: 统一为 `TimerService` or `SchedulingService`

#### 9. **策略模式使用不充分**
- **现状**: 虽然有 BlockingStrategy 协议, 但策略选择和管理逻辑分散
- **影响**: 添加新策略困难
- **建议**: 创建 `StrategyFactory` 和 `StrategyRegistry`

#### 10. **缺乏操作审计和用户活动日志**
- **现状**: 无法追踪用户的屏蔽启停历史
- **影响**: 无法分析使用模式
- **建议**: 添加 `AuditLog` 模型和服务

---

## 重构计划

### 📋 Phase 1: 代码分析与注释 (第1-2周)

#### Step 1.1: 为现有代码添加详细注释
**目标文件**:
- [x] foqosApp.swift
- [ ] StrategyManager.swift (分块注释)
- [ ] AppBlockerUtil.swift
- [ ] RequestAuthorizer.swift
- [ ] DeviceActivityMonitorExtension.swift
- [ ] DeviceActivityCenterUtil.swift
- [ ] TimersUtil.swift
- [ ] LiveActivityManager.swift
- [ ] BlockedProfiles.swift
- [ ] BlockedProfileSession.swift
- [ ] Shared.swift
- [ ] BlockingStrategy.swift 及所有实现类

**注释内容**:
1. 模块功能概述 (Purpose)
2. 职责说明 (Responsibilities)
3. 关键方法说明 (Key Methods)
4. 项目内用法示例 (Usage Examples)
5. 数据流说明 (Data Flow)
6. 异常情况处理 (Error Handling)

#### Step 1.2: 创建项目流程图
**输出物**:
- [ ] 完整的会话启动/停止流程图
- [ ] 日程触发流程图
- [ ] App Intent 流程图
- [ ] 跨进程通信流程图
- [ ] 模块依赖关系图

#### Step 1.3: 创建架构文档
**输出物**: 更新 docs/hlbpa/ARCHITECTURE_OVERVIEW.md
- [ ] 模块清单
- [ ] 数据流详解
- [ ] API 边界定义
- [ ] 扩展性建议

---

### 📋 Phase 2: 提取和重构核心模块 (第3-6周)

#### Step 2.1: 拆分 StrategyManager
**目标**: 从 963 行拆分为 5 个专注的类

```
StrategyManager (协调器)
├── SessionManager (会话 CRUD)
├── TimerCoordinator (计时协调)
├── BreakManager (休息管理)
├── EmergencyUnlock (紧急解锁)
└── StrategyFactory (策略工厂)
```

**步骤**:
1. [ ] 创建 `SessionManager` 提取会话管理逻辑
2. [ ] 创建 `TimerCoordinator` 提取计时逻辑
3. [ ] 创建 `BreakManager` 提取休息逻辑
4. [ ] 创建 `EmergencyUnlock` 提取紧急解锁
5. [ ] 创建 `StrategyFactory` 提取策略创建
6. [ ] 更新 `StrategyManager` 为协调器
7. [ ] 运行现有功能测试确保无回归

#### Step 2.2: 优化数据模型
**目标**: 简化 BlockedProfiles 和相关模型

```
现状:
  BlockedProfiles (22+ 属性)

目标:
  Profile (基础配置)
  ├── RestrictionConfig (屏蔽设置)
  ├── BreakConfig (休息设置)
  └── ScheduleConfig (日程设置)
```

**步骤**:
1. [ ] 创建 `RestrictionConfig` 数据模型
2. [ ] 创建 `BreakConfig` 数据模型
3. [ ] 创建 `ScheduleConfig` 数据模型
4. [ ] 迁移 BlockedProfiles 属性
5. [ ] 更新数据访问层
6. [ ] 更新 SwiftData 模型关系
7. [ ] 数据迁移脚本

#### Step 2.3: 建立统一的依赖注入
**目标**: 使用 Swift Dependency 框架

```swift
// 定义
enum AppDependencies {
    @Dependency(\.strategyManager) var strategyManager
    @Dependency(\.appBlocker) var appBlocker
    @Dependency(\.modelContext) var modelContext
}

// 使用
struct SomeView: View {
    @Dependency(\.strategyManager) var strategyManager
}
```

**步骤**:
1. [ ] 添加 Swift Dependency 包依赖
2. [ ] 定义 AppDependencies 枚举
3. [ ] 为核心服务创建 Dependency keys
4. [ ] 迁移现有 EnvironmentObject 到 Dependency
5. [ ] 更新 foqosApp.swift
6. [ ] 逐个视图更新

#### Step 2.4: 统一计时逻辑
**目标**: 创建单一的 `TimingService`

```
现状分散:
  - DeviceActivityCenterUtil (日程注册)
  - TimersUtil (后台通知)
  - StrategyManager (计时状态)

目标统一:
  TimingService
  ├── scheduleActivity() (日程)
  ├── scheduleNotification() (通知)
  ├── startCountdown() (倒计时)
  ├── cancelTiming() (取消)
  └── getActiveTimings() (查询)
```

**步骤**:
1. [ ] 创建 `TimingService` 协议定义
2. [ ] 创建 `DeviceActivityTimingService` (日程)
3. [ ] 创建 `NotificationTimingService` (通知)
4. [ ] 创建 `TimingCoordinator` 统一调度
5. [ ] 迁移现有逻辑
6. [ ] 添加计时日志和追踪

---

### 📋 Phase 3: 改进架构和最佳实践 (第7-10周)

#### Step 3.1: 建立测试框架
**目标**: 为核心模块添加单元测试

```
Tests/
├── SessionManagerTests
├── AppBlockerUtilTests
├── TimerCoordinatorTests
├── BreakManagerTests
├── EmergencyUnlockTests
└── IntegrationTests
```

**步骤**:
1. [ ] 配置 XCTest 框架
2. [ ] 为 SessionManager 编写测试
3. [ ] 为 AppBlockerUtil 编写测试
4. [ ] 为 TimerCoordinator 编写测试
5. [ ] 添加集成测试
6. [ ] 配置 CI/CD 自动化测试

#### Step 3.2: 改进错误处理和日志
**目标**: 统一的日志和错误处理

```swift
enum LogLevel { case debug, info, warning, error, critical }

class Logger {
    func log(_ message: String, level: LogLevel, file: String, line: Int)
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ error: Error)
}

// 使用
Logger.shared.info("Session started")
Logger.shared.error(error, context: "startSession")
```

**步骤**:
1. [ ] 创建 Logger 类
2. [ ] 定义日志分类和级别
3. [ ] 统一替换所有 print() 和 OSLog
4. [ ] 添加错误追踪上下文
5. [ ] 配置日志输出 (Console / 文件 / 远程)

#### Step 3.3: 优化 UI 组件结构
**目标**: 清晰的组件分层

```
Views/
├── Screens/
│   ├── HomeScreen.swift
│   ├── ProfileEditScreen.swift
│   ├── SessionScreen.swift
│   └── SettingsScreen.swift
├── Features/
│   ├── ProfileManagement/
│   ├── SessionControl/
│   ├── StrategySelection/
│   └── Scheduling/
└── Shared/
    ├── Buttons/
    ├── Cards/
    ├── Forms/
    └── Modifiers/
```

**步骤**:
1. [ ] 重新组织 Components 为 Views
2. [ ] 提取 Shared 组件
3. [ ] 更新导入路径
4. [ ] 统一组件命名规范
5. [ ] 创建组件库文档

#### Step 3.4: 添加操作审计日志
**目标**: 追踪用户行为

```swift
@Model
class AuditLog {
    var timestamp: Date
    var action: String
    var userId: String?
    var details: [String: String]?
    var status: AuditStatus
}

enum AuditStatus { case success, failed }

// 使用
AuditLogger.shared.log(
    action: "session_started",
    details: ["profile_id": profileId]
)
```

**步骤**:
1. [ ] 创建 AuditLog 数据模型
2. [ ] 创建 AuditLogger 服务
3. [ ] 在关键点添加审计记录
4. [ ] 创建审计日志查看器 UI
5. [ ] 添加导出功能

---

### 📋 Phase 4: 扩展性和维护性改进 (第11-14周)

#### Step 4.1: 策略模式完善
**目标**: 简化策略的添加和管理

```swift
protocol BlockingStrategyFactory {
    func createStrategy(for type: StrategyType) -> BlockingStrategy
}

class DefaultStrategyFactory: BlockingStrategyFactory {
    func createStrategy(for type: StrategyType) -> BlockingStrategy {
        switch type {
        case .manual: return ManualBlockingStrategy()
        case .nfc: return NFCBlockingStrategy()
        // ...
        }
    }
}
```

**步骤**:
1. [ ] 创建 StrategyFactory 协议
2. [ ] 实现 DefaultStrategyFactory
3. [ ] 创建 StrategyRegistry
4. [ ] 简化策略的注册和发现
5. [ ] 编写添加新策略的指南

#### Step 4.2: 数据同步和冲突解决
**目标**: 明确 SharedData ↔ SwiftData 的同步规则

```swift
protocol SyncStrategy {
    func sync(local: LocalData, remote: RemoteData) -> SyncResult
}

class LastWriteWinsSyncStrategy: SyncStrategy { }
class LocalPriorityStrategy: SyncStrategy { }
```

**步骤**:
1. [ ] 分析当前同步流程
2. [ ] 记录所有同步触发点
3. [ ] 定义冲突解决策略
4. [ ] 实现 SyncManager
5. [ ] 添加同步日志和监控
6. [ ] 编写文档

#### Step 4.3: 插件系统 (可选)
**目标**: 支持三方扩展

```swift
protocol FoqosPlugin {
    var id: String { get }
    func initialize(context: AppContext)
    func onSessionStart(session: BlockedProfileSession)
    func onSessionEnd(session: BlockedProfileSession)
}
```

**步骤**:
1. [ ] 定义插件接口
2. [ ] 创建插件管理器
3. [ ] 支持动态加载和卸载
4. [ ] 编写示例插件
5. [ ] 创建插件开发指南

#### Step 4.4: 性能优化
**目标**: 优化关键路径性能

**优化项**:
- [ ] StrategyManager 初始化时间
- [ ] 会话启动/停止响应时间
- [ ] SwiftData 查询优化
- [ ] Widget 刷新频率
- [ ] Live Activity 更新频率
- [ ] 内存使用优化

**步骤**:
1. [ ] 使用 Instruments 分析性能
2. [ ] 识别热点代码
3. [ ] 优化数据库查询
4. [ ] 异步处理非关键操作
5. [ ] 缓存策略优化

---

### 📋 Phase 5: 完成和文档 (第15-16周)

#### Step 5.1: 完整的代码注释
- [ ] 为所有重构的文件添加注释
- [ ] 创建代码示例文档
- [ ] 编写 API 参考

#### Step 5.2: 项目文档更新
- [ ] 更新架构文档
- [ ] 创建开发者指南
- [ ] 编写贡献指南
- [ ] 创建常见问题 FAQ

#### Step 5.3: 用户文档更新
- [ ] 更新功能说明
- [ ] 创建故障排除指南
- [ ] 记录已知问题
- [ ] 创建更新日志

#### Step 5.4: 最终测试和验证
- [ ] 全面的功能测试
- [ ] 回归测试
- [ ] 性能测试
- [ ] 用户验收测试

---

## 重构优先级矩阵

| 优先级 | 模块                 | 复杂度 | 影响力 | 时间  | 周期 |
| ------ | -------------------- | ------ | ------ | ----- | ---- |
| 🔴 P0   | StrategyManager 拆分 | 高     | 高     | 2周   | 3-4  |
| 🔴 P0   | 建立 DI 框架         | 中     | 高     | 1.5周 | 2-3  |
| 🔴 P0   | 数据模型优化         | 中     | 高     | 2周   | 3-4  |
| 🟡 P1   | 统一计时逻辑         | 中     | 中     | 1.5周 | 2-3  |
| 🟡 P1   | 单元测试框架         | 中     | 高     | 2周   | 3-4  |
| 🟡 P1   | 日志和错误处理       | 低     | 中     | 1周   | 2    |
| 🟢 P2   | UI 组件重组          | 低     | 中     | 1周   | 2    |
| 🟢 P2   | 审计日志             | 低     | 低     | 1周   | 2    |

---

## 下一步行动

1. **立即开始**: 
   - [ ] 为关键文件添加详细注释 (Phase 1.1)
   - [ ] 制作流程图 (Phase 1.2)

2. **近期 (1-2周内)**:
   - [ ] 完成项目分析文档
   - [ ] 创建流程图和依赖关系图
   - [ ] 识别关键风险点

3. **计划 (2-4周)**:
   - [ ] 建立测试框架基础
   - [ ] 开始 StrategyManager 拆分
   - [ ] 建立代码审查流程

---

## 参考文档

- [项目架构概览](ARCHITECTURE_OVERVIEW.md)
- [项目地图](docs/study/00-project-map.md)
- [目标和能力](docs/study/01-targets-and-capabilities.md)
- [模块地图](docs/study/03-module-map.md)

