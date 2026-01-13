# Findings & Decisions - Foqos 重构项目

## Requirements (用户需求)

**主要目标**:
- 对整个 Foqos 项目进行全面重构
- 逐个分析每个代码文件的流程和作用
- 为每个代码文件添加详细注释（中英文）
- 完全理解整个项目后，制定重构计划
- 一步步设计和分析重构计划

**约束条件**:
- 必须保持应用功能完整性
- 重构需要考虑 iOS Extensions 的特殊性
- 需要保持与 Apple Screen Time API 的兼容性
- 数据迁移需要平滑过渡

## Research Findings (研究发现)

### 项目规模和复杂度

**代码统计** (基于工作区结构):
- **主应用**: Foqos/ - 包含 Models, Views, Components, Utils, Intents
- **Extensions**: 3 个（DeviceMonitor, ShieldConfig, Widget）
- **关键组件数量**:
  - 9 种 BlockingStrategy 实现
  - 15+ Utils 工具类
  - 5 个 App Intents
  - 多个 SwiftData Models

**已知的大型文件** (来自现有文档):
- `StrategyManager.swift`: 963 行 ⚠️
- `BlockedProfiles.swift`: 429 行 ⚠️
- 多个超过 200 行的工具类

### 现有文档资产

**高质量文档已存在**:
1. **docs/hlbpa/ARCHITECTURE_OVERVIEW.md** - 架构总览，包含 Mermaid 图
2. **ANALYSIS_EXECUTIVE_SUMMARY.md** - 执行总结，包含关键问题
3. **docs/REFACTORING_ANALYSIS.md** - 1268 行的详细分析
4. **docs/PROCESS_FLOWS.md** - 7 个详细流程图
5. **docs/CODE_ANNOTATION_GUIDE.md** - 注释指南

**文档覆盖内容**:
- ✅ 系统架构图和上下文
- ✅ 数据流分析
- ✅ 已识别的 P0/P1/P2 问题
- ✅ 5 阶段重构计划框架
- ⚠️ 缺少：每个文件的行级注释

### 代码深度分析新发现 (2026-01-12)

#### foqosApp.swift 分析结果

**✅ 架构优点**:
- 清晰的依赖注入模式（通过 .environmentObject）
- 正确使用 SwiftData ModelContainer
- AppDependencyManager 为 App Intents 提供容器访问
- Universal Links 处理集中化

**⚠️ 发现的问题**:
1. **Singleton + @StateObject 混用**
   - `StrategyManager.shared`, `LiveActivityManager.shared`, `ThemeManager.shared` 
   - 问题：既是 Singleton 又包装在 @StateObject 中，有些冗余
   - 建议：要么纯 Singleton，要么纯 DI，不要混合

2. **ModelContainer 错误处理**
   - 使用 `fatalError()` 当容器创建失败
   - 问题：应用会直接崩溃，没有降级策略
   - 建议：提供错误恢复机制或用户友好的错误页面

3. **缺少环境对象文档**
   - 8 个 environmentObject 注入，没有注释说明各自用途
   - 已添加：详细的中英文注释

#### StrategyManager.swift 分析结果 (部分完成)

**📊 复杂度指标**:
- 文件行数：963 行
- 职责数量：至少 6 个主要职责
- 依赖数量：3 个直接依赖 + 8 种策略
- @Published 属性：7 个
- @AppStorage 属性：3 个

**🔍 职责分解** (当前混在一起):
1. **策略注册表**：管理 8 种 BlockingStrategy
2. **会话生命周期**：startBlocking, stopBlocking, activeSession
3. **计时器管理**：timer, elapsedTime, startTimer, stopTimer
4. **休息模式管理**：startBreak, stopBreak, isBreakActive
5. **紧急解锁管理**：emergencyUnblock, 配额追踪
6. **跨组件协调**：Widget 刷新、Live Activity 更新、通知调度
7. **深度链接处理**：toggleSessionFromDeeplink
8. **后台会话管理**：startSessionFromBackground, stopSessionFromBackground

**⚠️ 架构问题**:
1. **God Object 反模式**
   - 963 行单一类，职责过多
   - 违反单一职责原则 (SRP)
   - 建议拆分为：SessionCoordinator, TimerManager, StrategyRegistry, EmergencyManager

2. **策略回调注入方式复杂**
   - `onSessionCreation` 和 `onErrorMessage` 通过闭包动态注入
   - 每次 `getStrategy()` 都重新设置回调
   - 可能存在内存泄漏风险（闭包捕获 self）

3. **状态同步逻辑分散**
   - Widget 刷新：在多个地方调用 `WidgetCenter.shared.reloadTimelines`
   - Live Activity：通过 liveActivityManager 单独管理
   - SharedData：在 strategy 回调中更新
   - 建议：统一的状态同步协调器

4. **错误处理不一致**
   - 有的地方用 `print()`
   - 有的地方设置 `errorMessage`
   - 有的地方直接 return
   - 建议：统一错误处理策略

**✅ 优点**:
- 详细的文档注释（前 100 行）
- Strategy Pattern 的正确实现
- 计时器逻辑清晰（区分会话时间和休息倒计时）

**📝 已添加的注释**:
- 类级别文档和职责说明
- 所有属性的详细注释
- 数据流和使用场景说明

#### BlockedProfiles.swift 分析结果

**📊 复杂度指标**:
- 属性：22+，混合配置/功能开关/物理解锁/网页过滤/日程
- 初始化参数：20+，可选项极多
- 方法：15+ 静态方法（CRUD + Snapshot + Domain 管理）
- 文件行数：429 行

**⚠️ 架构问题**:
1. 数据模型承担过多职责（配置 + 设置 + UI 排序 + 物理解锁 + 网页过滤 + 日程）
2. 初始化/更新函数参数过长，易出错，难以维护
3. 与 SharedData.ProfileSnapshot 数据重复，双写同步成本高
4. 业务逻辑混入模型（生成深链、更新/删除 snapshot）

**✅ 优点**:
- 正确使用 `@Model` 与 `@Relationship`
- 提供清晰的 CRUD 静态方法
- Snapshot 机制解决 Extension 读数据的问题

**🛠️ 重构建议**:
- 拆分子模型：ProfileSettings、PhysicalUnlockConfig、WebFilterConfig
- 引入 Builder/DTO 以简化构造与更新
- 抽取 Snapshot 处理到 ProfileService 统一管理

#### AppBlockerUtil.swift 分析结果

**角色**: Screen Time API 封装层，负责把 SharedData.ProfileSnapshot 转为 ManagedSettings 限制。

**优点**:
- 接口简单：activateRestrictions / deactivateRestrictions / getWebDomains
- 面向 Snapshot 设计，兼容 App Group 场景

**发现**:
- allow-only 模式与默认 block 列表模式分支清晰，但依赖 caller 正确填充 tokens/domains
- Safari/web filter 由两个开关 (enableAllowModeDomains/enableSafariBlocking) 组合，需调用方保障一致性

**建议**:
- 添加入参验证（空 tokens/空 domains 时的行为定义）
- 提供幂等保护或“已激活”状态标记，避免重复设置

#### DeviceActivityCenterUtil.swift 分析结果

**角色**: DeviceActivityCenter 封装，注册/取消三类监控：日程（重复）、休息（一次性）、策略计时（一次性）。

**优点**:
- 静态方法，调用简单；ActivityName 由 profile.id 派生，支持多 profile 并行
- start 前先 stop，避免重复监控

**发现**:
- getTimeIntervalStartAndEnd 将 intervalStart 固定为 00:00；一次性计时依赖 start/end 组件表达“现在到 T”，需要确认与扩展侧解析一致性
- 打印日志但无错误上报通道

**建议**:
- 对 minutes 上限/下限做校验（与 StrategyManager 校验一致）
- 将 stopActivities 返回的状态或错误向上抛/记录，便于调试

#### TimersUtil.swift 分析结果

**角色**: 本地通知 + BGTask 冗余调度器，确保 App 被杀时仍能触发提醒。

**优点**:
- scheduleNotification 同时注册 UNNotification + BGProcessingTask，提升可靠性
- 任务持久化在 UserDefaults，重启后可恢复

**发现**:
- 无 iOS 约束校验（BGProcessingTask 的最短/最早时间、授权失败兜底）
- handleBackgroundProcessingTask 仅发通知事件，不做失败重试/退避

**建议**:
- 为空的 pending 任务直接取消 BG 请求；对授权失败/submit 失败增加日志与上报
- 合并 duplicate notificationId 的去重逻辑，避免重复提醒

### 架构模式识别

**设计模式使用**:
- **Strategy Pattern**: 9 种 BlockingStrategy 实现不同的屏蔽策略
- **Singleton Pattern**: StrategyManager, RequestAuthorizer 等使用 shared instance
- **Observer Pattern**: 通过 @Published 和 ObservableObject
- **Dependency Injection**: 通过 .environmentObject() 和 AppDependencyManager
- **Repository Pattern**: SharedData 作为跨进程数据仓库

**数据架构**:
- **SwiftData**: 主应用的持久化（BlockedProfiles, BlockedProfileSession）
- **App Group UserDefaults**: Extension 通信（SharedData.ProfileSnapshot）
- **双写模式**: 同时更新 SwiftData 和 SharedData

### Apple Frameworks 集成

**核心依赖**:
- FamilyControls - 授权和 API 访问
- ManagedSettings - 实际屏蔽执行
- DeviceActivity - 系统触发的日程监控
- ManagedSettingsUI - Shield 界面定制
- CoreNFC - NFC 标签读写
- WidgetKit + ActivityKit - Widget 和 Live Activity
- BackgroundTasks - 后台任务调度

**系统限制**:
- Extensions 有内存和执行时间限制
- SwiftData ModelContainer 在 Extension 中需要独立初始化
- App Group 是唯一可靠的跨进程通信方式

## Technical Decisions (技术决策)

| 决策                                                 | 理由                                                | 备选方案         | 风险                   |
| ---------------------------------------------------- | --------------------------------------------------- | ---------------- | ---------------------- |
| 使用 planning-with-files 方法论                      | 项目复杂，需要持久化的分析过程；避免上下文窗口限制  | 直接开始重构     | 无                     |
| 优先分析核心组件（StrategyManager, BlockedProfiles） | 这些是系统的心脏，理解它们是理解整个系统的关键      | 从 UI 层开始     | 可能过早陷入细节       |
| 为代码添加中英文双语注释                             | 提高国际协作能力，同时保持中文团队的理解成本低      | 仅英文或仅中文   | 注释维护成本增加       |
| 保留现有文档，创建互补的 task_plan.md                | 现有文档质量高，不应重复；task_plan.md 用于追踪进度 | 合并到一个大文档 | 文档管理复杂度         |
| 分 7 个 Phase 执行分析和重构                         | 每个 Phase 有明确的交付物和验收标准                 | 一次性大规模重构 | Phase 划分可能需要调整 |

## Issues Encountered (已知问题)

### 从现有文档中提取的 P0 问题

| 问题                     | 严重性 | 文件                             | 影响                 | 解决方案方向     |
| ------------------------ | ------ | -------------------------------- | -------------------- | ---------------- |
| StrategyManager 过大     | 🔴 P0   | StrategyManager.swift (963行)    | 难以维护、测试、理解 | 拆分为多个协调器 |
| BlockedProfiles 属性过多 | 🔴 P0   | BlockedProfiles.swift (22+ 属性) | 初始化复杂、职责不清 | 拆分为多个子模型 |
| 缺乏统一依赖注入         | 🔴 P0   | 全项目                           | 测试困难、耦合高     | 引入 DI 容器     |
| 缺乏单元测试             | 🟡 P1   | 全项目                           | 重构风险高、回归风险 | 建立测试基础设施 |
| 错误处理不统一           | 🟡 P1   | 全项目                           | 调试困难、用户体验差 | 统一错误处理策略 |

### 需要进一步调查的问题

- [ ] Extensions 的性能瓶颈在哪里？
- [ ] SwiftData 的迁移策略是什么？
- [ ] 是否有循环依赖？
- [ ] 内存泄漏风险评估
- [ ] 并发安全性检查

## Architecture Insights (架构洞察)

### 数据流路径

**会话启动流程** (来自 ARCHITECTURE_OVERVIEW.md):
```
用户交互 → StrategyManager → BlockingStrategy 
→ SwiftData (Session) → AppBlockerUtil 
→ ManagedSettingsStore → SharedData (Snapshot) 
→ Extensions 刷新
```

**系统触发流程** (日程/计时):
```
DeviceActivityCenter → DeviceActivityMonitorExtension
→ SharedData.snapshot() → TimerActivityUtil 
→ AppBlockerUtil → ManagedSettingsStore
```

### 组件职责划分

**Clear Responsibilities** (职责清晰):
- ✅ `AppBlockerUtil`: 纯粹的 ManagedSettings 包装器
- ✅ `RequestAuthorizer`: 专注权限管理
- ✅ `SharedData`: 专注跨进程通信

**Unclear Responsibilities** (职责模糊):
- ⚠️ `StrategyManager`: 既管理策略，又管理会话，又管理计时器
- ⚠️ `BlockedProfiles`: 既是配置，又包含 UI 状态，又包含统计数据

## Code Quality Observations (代码质量观察)

### 良好实践

- ✅ 使用 SwiftUI 和现代 Swift 特性
- ✅ Strategy Pattern 的合理应用
- ✅ Extension 的正确使用（分离关注点）
- ✅ 使用 App Group 进行跨进程通信

### 需要改进

- ⚠️ 缺少单元测试
- ⚠️ 大型类和方法（God Object 反模式）
- ⚠️ 注释稀缺（需要添加详细注释）
- ⚠️ 错误处理不一致（有的用 print，有的抛出异常）
- ⚠️ Magic Numbers 和 Strings（如 "group.dev.ambitionsoftware.foqos"）

## Next Research Areas (下一步研究方向)

1. **Phase 2 重点**:
   - [ ] foqosApp.swift 的依赖注入机制
   - [ ] StrategyManager 的状态机逻辑
   - [ ] BlockingStrategy 协议的契约设计

2. **Phase 3 重点**:
   - [ ] Extension 的生命周期和限制
   - [ ] SharedData 的数据一致性保证
   - [ ] DeviceActivity 的触发时机和可靠性

3. **Phase 4 重点**:
   - [ ] SwiftUI Views 的状态管理
   - [ ] Utils 之间的依赖关系
   - [ ] 性能瓶颈识别

## Resources (资源链接)

- Apple Documentation:
  - [Screen Time API](https://developer.apple.com/documentation/familycontrols)
  - [App Extensions](https://developer.apple.com/app-extensions/)
  - [SwiftData](https://developer.apple.com/xcode/swiftdata/)

- 项目内部文档:
  - [ARCHITECTURE_OVERVIEW.md](docs/hlbpa/ARCHITECTURE_OVERVIEW.md)
  - [REFACTORING_ANALYSIS.md](docs/REFACTORING_ANALYSIS.md)
  - [PROCESS_FLOWS.md](docs/PROCESS_FLOWS.md)

### 2026-01-13 (17:00) - 數據模型層完整分析

**Context:**
完成對 Models/ 目錄下所有 19 個文件的深度分析，理解了項目的數據架構和 Strategy Pattern 實現。

**What I found:**

#### 📊 數據模型完整結構圖

```
┌─────────────────────────────────────────────────────────────┐
│                    SwiftData Layer (主 App)                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  BlockedProfiles (配置)              BlockedProfileSession   │
│  ├─ 22+ 屬性                         ├─ id, tag             │
│  ├─ @Relationship → sessions         ├─ startTime, endTime  │
│  ├─ blockingStrategyId               ├─ breakStartTime/End  │
│  ├─ strategyData: Data?              ├─ @Relationship       │
│  ├─ enableLiveActivity               │   → blockedProfile   │
│  ├─ physicalUnlockNFCTagId           └─ toSnapshot()        │
│  ├─ domains: [String]?                                      │
│  ├─ schedule: BlockedProfileSchedule?                       │
│  └─ 靜態方法：CRUD + Snapshot 管理                          │
│                                                               │
│  BlockedProfileSchedule (日程)                               │
│  ├─ days: [Weekday]                                         │
│  ├─ startHour/Minute, endHour/Minute                        │
│  └─ isTodayScheduled(), olderThan15Minutes()               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                            ↕ 雙寫同步
┌─────────────────────────────────────────────────────────────┐
│              SharedData Layer (App Group)                    │
│              UserDefaults(suiteName: "group...")             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ProfileSnapshot (配置快照)                                  │
│  ├─ 與 BlockedProfiles 屬性相同                             │
│  ├─ 但不包含 sessions 關係                                  │
│  └─ Codable，可序列化                                       │
│                                                               │
│  SessionSnapshot (會話快照)                                  │
│  ├─ id, tag, blockedProfileId                               │
│  ├─ startTime, endTime                                      │
│  ├─ breakStartTime, breakEndTime                            │
│  └─ Codable，可序列化                                       │
│                                                               │
│  存儲位置：                                                  │
│  ├─ profileSnapshots: [String: ProfileSnapshot]             │
│  ├─ activeSharedSession: SessionSnapshot?                   │
│  └─ completedSessionsInSchedular: [SessionSnapshot]         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                            ↓ 被讀取
┌─────────────────────────────────────────────────────────────┐
│                  Extensions (獨立進程)                       │
│  ├─ DeviceActivityMonitor                                   │
│  ├─ ShieldConfiguration                                     │
│  └─ FoqosWidget                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 🎯 Strategy Pattern 完整實現

**協議定義** (`BlockingStrategy.swift`):
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
  
  func startBlocking(context: ModelContext, profile: BlockedProfiles, forceStart: Bool?) -> (any View)?
  func stopBlocking(context: ModelContext, session: BlockedProfileSession) -> (any View)?
}
```

**9 種策略實現**:

| 策略類 | ID | 特點 | View 返回 | 行數 |
|--------|----|----|----------|------|
| ManualBlockingStrategy | Manual | 純手動開關 | nil | ~57 |
| NFCBlockingStrategy | NFC | NFC 掃描啟動/停止 | nil | ~70 |
| NFCManualBlockingStrategy | NFC+Manual | NFC 啟動，手動停止 | nil | ~60 |
| NFCTimerBlockingStrategy | NFC+Timer | 計時器啟動，NFC 停止 | TimerDurationView | ~80 |
| QRCodeBlockingStrategy | QR | QR 掃描啟動/停止 | nil | ~75 |
| QRManualBlockingStrategy | QR+Manual | QR 啟動，手動停止 | nil | ~65 |
| QRTimerBlockingStrategy | QR+Timer | 計時器啟動，QR 停止 | TimerDurationView | ~82 |
| ShortcutTimerBlockingStrategy | Shortcut+Timer | 後台計時器專用 | nil | ~55 |

**策略調用流程**:
```
1. 用戶點擊 Profile 卡片
   ↓
2. StrategyManager.toggleBlocking(profile)
   ↓
3. StrategyManager.getStrategy(profile.blockingStrategyId)
   ├─ 根據 ID 返回對應策略實例
   ├─ 注入回調：onSessionCreation, onErrorMessage
   └─ 返回 Strategy
   ↓
4. strategy.startBlocking(context, profile, forceStart)
   ├─ 可能返回 View（如 TimerDurationView）
   ├─ 調用 AppBlockerUtil.activateRestrictions()
   ├─ 創建 BlockedProfileSession
   └─ 觸發 onSessionCreation(.started(session))
   ↓
5. StrategyManager 在回調中：
   ├─ 更新 activeSession
   ├─ 啟動計時器（如果有）
   ├─ 同步 SharedData
   ├─ 刷新 Widget
   ├─ 啟動 Live Activity
   └─ 安排提醒通知
```

#### 🔍 關鍵發現

**1. 雙寫模式的複雜性**
- **為什麼需要**：Extensions 運行在獨立進程中，無法訪問主 App 的 SwiftData
- **如何實現**：
  - BlockedProfiles.updateSnapshot() - 每次更新 Profile 時同步
  - BlockedProfileSession.toSnapshot() - 將會話轉為快照
  - SharedData.setSnapshot() - 寫入 App Group UserDefaults
- **同步點**：
  1. Profile 創建/更新/刪除
  2. Session 啟動/停止
  3. 休息模式啟動/停止
  4. 策略數據更新
- **風險**：
  - 手動同步，容易遺漏
  - 無事務保證，可能不一致
  - 建議：引入 SyncCoordinator 統一管理

**2. BlockedProfiles 的職責過重**

當前 BlockedProfiles 包含：
- ✅ 基礎信息：id, name, createdAt, updatedAt, order
- ✅ 策略配置：blockingStrategyId, strategyData
- ✅ 功能開關：enableLiveActivity, enableBreaks, enableStrictMode, enableAllowMode
- ✅ 提醒設置：reminderTimeInSeconds, customReminderMessage
- ✅ 物理解鎖：physicalUnblockNFCTagId, physicalUnblockQRCodeId
- ✅ 網頁過濾：domains, enableAllowModeDomains, enableSafariBlocking
- ✅ 日程配置：schedule: BlockedProfileSchedule?
- ✅ 應用選擇：selectedActivity: FamilyActivitySelection
- ✅ 會話關係：sessions: [BlockedProfileSession]
- ✅ 業務邏輯：CRUD 靜態方法、Snapshot 管理、DeviceActivity 清理

**建議拆分**：
```swift
// 核心模型
@Model class BlockedProfile {
  var id: UUID
  var name: String
  var order: Int
  var createdAt: Date
  var updatedAt: Date
  var strategy: ProfileStrategy  // 關聯
  var settings: ProfileSettings  // 關聯
  @Relationship var sessions: [BlockedProfileSession]
}

// 策略配置
@Model class ProfileStrategy {
  var strategyId: String
  var strategyData: Data?
  var physicalUnlock: PhysicalUnlockConfig?  // 關聯
}

// 功能設置
@Model class ProfileSettings {
  var enableLiveActivity: Bool
  var enableBreaks: Bool
  var breakTimeInMinutes: Int
  var enableStrictMode: Bool
  var reminderConfig: ReminderConfig?  // 關聯
  var webFilter: WebFilterConfig?  // 關聯
  var schedule: BlockedProfileSchedule?
}

// 物理解鎖配置
@Model class PhysicalUnlockConfig {
  var nfcTagId: String?
  var qrCodeId: String?
}

// 網頁過濾配置
@Model class WebFilterConfig {
  var domains: [String]
  var enableAllowMode: Bool
  var enableSafariBlocking: Bool
}

// 提醒配置
@Model class ReminderConfig {
  var timeInSeconds: UInt32
  var customMessage: String?
}
```

**3. Strategy Pattern 的回調問題**

當前實現：
```swift
// StrategyManager.getStrategy()
func getStrategy(_ strategyId: String) -> any BlockingStrategy {
  var strategy = strategies.first { $0.getIdentifier() == strategyId }!
  
  // 每次都重新注入回調
  strategy.onSessionCreation = { [weak self] status in
    // ... 處理會話創建
  }
  strategy.onErrorMessage = { [weak self] message in
    // ... 處理錯誤
  }
  
  return strategy
}
```

**問題**：
- 每次調用都重新設置回調
- 協議中 `var onSessionCreation` 不應該是 var，應該是 func
- 閉包可能捕獲 self，需要 [weak self]

**建議改進**：
```swift
// 方案 1: Delegate 模式
protocol BlockingStrategyDelegate: AnyObject {
  func strategyDidStart(_ strategy: BlockingStrategy, session: BlockedProfileSession)
  func strategyDidEnd(_ strategy: BlockingStrategy, profile: BlockedProfiles)
  func strategyDidError(_ strategy: BlockingStrategy, message: String)
}

protocol BlockingStrategy {
  weak var delegate: BlockingStrategyDelegate? { get set }
  // ...
}

// 方案 2: Combine Publisher
protocol BlockingStrategy {
  var sessionEvents: PassthroughSubject<SessionStatus, Never> { get }
  var errorEvents: PassthroughSubject<String, Never> { get }
  // ...
}
```

**4. StrategyManager 職責詳細拆解**

當前 StrategyManager（1265 行）實際包含：

| 職責 | 代碼行數估算 | 應獨立為 |
|------|-------------|----------|
| 策略註冊表管理 | ~50 | StrategyRegistry |
| 會話生命週期協調 | ~300 | SessionCoordinator |
| 計時器管理 | ~150 | TimerManager |
| 休息模式管理 | ~100 | BreakManager |
| 緊急解鎖管理 | ~80 | EmergencyUnlockManager |
| Widget/LiveActivity 同步 | ~100 | StateSyncCoordinator |
| 深度鏈接處理 | ~50 | DeepLinkHandler |
| 後台會話管理 | ~150 | BackgroundSessionManager |
| 錯誤處理和日誌 | ~100 | ErrorHandler |
| UI 狀態管理 | ~185 | SessionViewModel |

**建議重構架構**：
```
┌──────────────────────────────────────────┐
│         SessionCoordinator               │  (主協調器)
│  - toggleBlocking()                      │
│  - startSession() / endSession()         │
│  - 協調所有子管理器                      │
└──────────────────────────────────────────┘
         ↓ 使用
┌──────────────────────────────────────────┐
│  StrategyRegistry                        │  (策略註冊)
│  - register(strategy)                    │
│  - getStrategy(id)                       │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│  TimerManager                            │  (計時器)
│  - startTimer() / stopTimer()            │
│  - elapsedTime                           │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│  BreakManager                            │  (休息模式)
│  - startBreak() / endBreak()             │
│  - scheduleBreakReminder()               │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│  StateSyncCoordinator                    │  (狀態同步)
│  - syncToWidget()                        │
│  - syncToLiveActivity()                  │
│  - syncToSharedData()                    │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│  EmergencyUnlockManager                  │  (緊急解鎖)
│  - canUnlock() / emergencyUnlock()       │
│  - trackQuota()                          │
└──────────────────────────────────────────┘
```

**Why it matters:**

1. **數據架構理解是重構的基礎**
   - 現在完全理解了 SwiftData ↔ SharedData 的雙寫機制
   - 知道了哪些地方需要同步，哪些是同步風險點

2. **Strategy Pattern 實現良好但有改進空間**
   - 策略本身設計清晰，每個策略職責單一
   - 但策略與 StrategyManager 的耦合方式可以優化

3. **BlockedProfiles 是第二大重構目標**
   - 僅次於 StrategyManager
   - 需要拆分為多個子模型，降低複雜度

4. **重構優先級已明確**
   - P0: StrategyManager（1265 行，職責過多）
   - P0: BlockedProfiles（429 行，屬性過多）
   - P1: Strategy 回調機制（內存泄漏風險）
   - P1: 雙寫同步機制（一致性風險）

**Next steps:**

1. ✅ 數據模型層分析完成
2. 下一步：分析 Extensions（DeviceActivityMonitor, ShieldConfig, Widget）
3. 理解系統觸發流程
4. 分析 App Intents 和 Shortcuts 集成
5. 之後：整理完整的重構計劃

---

### 2026-01-13 (18:00) - Extensions 層調研與重構計劃完成

**Context:**
完成對 Extensions（3個）和 App Intents（5個）的快速調研，基於完整項目理解制定了詳細的重構計劃。

**What I found:**

#### 🔌 Extensions 層架構

**1. DeviceActivityMonitorExtension**（~55行）

職責：作為系統與主 App 之間的橋樑，響應定時事件。

```swift
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  override func intervalDidStart(for activity: DeviceActivityName) {
    TimerActivityUtil.startTimerActivity(for: activity)
  }
  
  override func intervalDidEnd(for activity: DeviceActivityName) {
    TimerActivityUtil.stopTimerActivity(for: activity)
  }
}
```

**優點**：
- ✅ 極簡設計，只做必要的事
- ✅ 委託給 TimerActivityUtil 處理邏輯
- ✅ 正確使用 OSLog 記錄
- ✅ 已有詳細的中英文注釋

**無需重構**，設計已經很好。

---

**2. ShieldConfigurationExtension**（~186行）

職責：自定義被屏蔽 App/網站的 Shield UI。

**亮點設計**：
- 🎨 17 條勵志文案庫（emoji + 標題 + 副標題 + 按鈕文字）
- 🎲 基於日期 + 標題的穩定隨機選擇（同一天同一個 App 看到相同文案）
- 🎯 訪問 ThemeManager 獲取用戶主題色
- 📐 動態生成 emoji 圖標

示例文案：
```
("🧠", "Brain check", "Do you actually want Twitter… or was it autopilot?", "Return")
("🎯", "Stay on target", "One small step toward your goal first. Then decide on Twitter.", "Continue")
```

**優點**：
- ✅ 創意設計，提升用戶體驗
- ✅ FNV-1a 哈希算法保證穩定性
- ✅ 已有詳細注釋

**潛在改進**：
- 📝 文案庫可以外部配置化（JSON/Plist）
- 🌍 支持多語言本地化

---

**3. FoqosWidget**（7個文件）

結構：
```
FoqosWidget/
├── FoqosWidgetBundle.swift          # 入口
├── Providers/
│   └── ProfileControlProvider.swift # Timeline Provider
├── Models/
│   └── ProfileWidgetEntry.swift     # Entry 數據
├── Views/
│   └── ProfileWidgetEntryView.swift # UI
├── Widgets/
│   ├── ProfileControlWidget.swift   # 主 Widget
│   └── FoqosWidgetLiveActivity.swift # 動態島
└── ProfileSelectionIntent.swift     # Widget 配置
```

**數據流**：
```
SharedData (App Group)
    ↓
ProfileControlProvider.timeline()
    ↓
ProfileWidgetEntry
    ↓
ProfileWidgetEntryView
    ↓
Widget UI
```

**操作觸發**：
```
Widget 按鈕點擊
    ↓
App Intent (StartProfileIntent/StopProfileIntent)
    ↓
StrategyManager.startSessionFromBackground()
    ↓
更新 SharedData
    ↓
WidgetCenter.reloadTimelines()
```

**優點**：
- ✅ 標準 Widget 架構
- ✅ 正確使用 App Group 共享數據
- ✅ 通過 App Intents 觸發操作

**無需大規模重構**，但需要確保主 App 的狀態同步可靠。

---

#### 📱 App Intents 集成

**5 個 Intents**：

| Intent | 參數 | 作用 | 調用點 |
|--------|------|------|--------|
| StartProfileIntent | profile, durationInMinutes? | 啟動會話 | Shortcuts, Widget |
| StopProfileIntent | profile | 停止會話 | Shortcuts, Widget |
| CheckProfileStatusIntent | profile | 查詢狀態 | Shortcuts |
| CheckSessionActiveIntent | - | 查詢是否有活躍會話 | Shortcuts |
| BlockedProfileEntity | - | Profile 實體定義 | 被其他 Intents 引用 |

**實現模式**（統一）：
```swift
struct StartProfileIntent: AppIntent {
  @Dependency(key: "ModelContainer")
  private var modelContainer: ModelContainer
  
  @MainActor
  func perform() async throws -> some IntentResult {
    StrategyManager.shared.startSessionFromBackground(
      profile.id,
      context: modelContainer.mainContext,
      durationInMinutes: durationInMinutes
    )
    return .result()
  }
}
```

**發現**：
1. ✅ 正確使用 @Dependency 獲取 ModelContainer
2. ✅ 所有邏輯委託給 StrategyManager
3. ⚠️ 直接依賴 StrategyManager.shared，重構時需要保持兼容
4. ⚠️ 錯誤處理簡單（只有 throws，無具體錯誤類型）

**重構後的 Intents**：
```swift
struct StartProfileIntent: AppIntent {
  @Dependency(key: "SessionCoordinator")  // 新的協調器
  private var coordinator: SessionCoordinator
  
  @MainActor
  func perform() async throws -> some IntentResult {
    do {
      try coordinator.startSessionFromBackground(
        profileId: profile.id,
        durationInMinutes: durationInMinutes
      )
      return .result()
    } catch let error as FoqosError {
      // 統一錯誤處理
      throw error
    }
  }
}
```

---

#### 📋 完整重構計劃

**已創建**：`REFACTORING_PLAN.md`（完整設計文檔）

**6 個階段，7-10 週時間表**：

```
┌─────────────────────────────────────────────────────────┐
│ 階段 1：建立測試基礎 (1-2週)                             │
│ - 創建 Unit Test Target                                 │
│ - 設置 Mock 框架                                        │
│ - 編寫核心功能集成測試                                   │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 階段 2：拆分 StrategyManager (2-3週) ⭐ 最大工作量       │
│ - 設計新架構（6個獨立管理器）                            │
│ - 逐步遷移調用方                                        │
│ - 保持向後兼容                                          │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 階段 3：重構 BlockedProfiles (1-2週)                    │
│ - 拆分為 7 個子模型                                     │
│ - 數據遷移腳本                                          │
│ - 引入 Builder Pattern                                 │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 階段 4-6：優化細節 (3週)                                │
│ - Strategy 回調改用 Delegate                           │
│ - 統一狀態同步機制                                      │
│ - 統一錯誤處理和日誌                                    │
└─────────────────────────────────────────────────────────┘
```

**新架構設計**（階段2的核心）：

```
SessionCoordinator (主協調器)
    ├── StrategyRegistry (策略註冊表)
    ├── TimerManager (計時器)
    ├── BreakManager (休息模式)
    ├── StateSyncCoordinator (狀態同步)
    ├── EmergencyUnlockManager (緊急解鎖)
    └── BackgroundSessionManager (後台會話)
```

**數據模型重構**（階段3的核心）：

```
BlockedProfile (核心)
    ├── ProfileStrategy (策略配置)
    │   └── PhysicalUnlockConfig (物理解鎖)
    └── ProfileSettings (功能設置)
        ├── ReminderConfig (提醒)
        ├── WebFilterConfig (網頁過濾)
        └── BlockedProfileSchedule (日程)
```

---

#### 🎯 重構優先級矩陣

| 問題 | 複雜度 | 影響面 | 優先級 | 階段 |
|------|--------|--------|--------|------|
| StrategyManager 職責過多 | 極高 | 全局 | 🔴 P0 | 2 |
| BlockedProfiles 屬性過多 | 高 | 數據層 | 🔴 P0 | 3 |
| 缺乏測試基礎 | 中 | 重構風險 | 🔴 P0 | 1 |
| 雙寫同步機制脆弱 | 中 | 數據一致性 | 🟡 P1 | 5 |
| Strategy 回調風險 | 低 | 內存 | 🟡 P1 | 4 |
| 錯誤處理不統一 | 低 | 可維護性 | 🟢 P2 | 6 |

**如果時間緊張，可以只做階段 1-3（P0 問題），約 4-7 週。**

---

**Why it matters:**

1. **完整項目理解已建立**
   - 數據層（Models）✅
   - 業務邏輯層（Utils）✅
   - 系統集成層（Extensions）✅
   - UI層（Views/Components）- 可選
   - 現在可以自信地開始重構

2. **重構計劃務實且可執行**
   - 分階段交付，每階段有驗收標準
   - 小步快跑，降低風險
   - 向後兼容，不破壞現有功能
   - 測試先行，保證質量

3. **Extensions 層設計良好**
   - 不需要重構，節省時間
   - 驗證了主 App 的架構問題確實存在
   - 證明簡潔設計是可行的

4. **時間估算保守且合理**
   - 7-10週適合這個規模
   - 留有緩衝空間
   - 可根據實際情況調整

**Next steps:**

1. ✅ 項目分析完成（Phase 1-3）
2. ✅ 重構計劃制定完成（Phase 4-5）
3. ⏭️ 與用戶討論計劃（Phase 6）
4. ⏭️ 根據反饋調整（Phase 6）
5. ⏭️ 開始執行重構（Phase 7）

---
