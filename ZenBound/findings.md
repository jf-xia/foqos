# Findings & Decisions - Foqos 重构项目

## Requirements (用户需求)

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

---
