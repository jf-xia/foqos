# Foqos 项目核心流程图

## 1. 会话启动流程（手动/NFC/QR）

```
┌─────────────────────────────────────────────────────────────────────┐
│                     用户交互入口                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Dashboard 中点击按钮              NFC 扫描                QR 扫描    │
│  (ManualBlockingStrategy)    (NFCBlockingStrategy)   (QRBlockingStrategy)
│          ↓                           ↓                      ↓
│
└─────────────────────────────────────────────────────────────────────┘
        
        ║ 所有入口汇聚到 StrategyManager
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  StrategyManager.toggleBlocking(context, profile)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. 判断是否已有活跃会话                                              │
│     ├─ 有: 调用 stopSession()                                       │
│     └─ 无: 调用 startSession()                                      │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  StrategyManager.startSession(context, profile)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. 从 SwiftData 创建 BlockedProfileSession                          │
│     session = BlockedProfileSession(tag, profile)                    │
│     context.insert(session)                                          │
│                                                                       │
│  2. 更新 StrategyManager 状态                                         │
│     @Published activeSession = session                               │
│     @Published activeProfileId = profile.id                          │
│     @Published isBreakActive = false                                 │
│                                                                       │
│  3. 启动计时器（如果策略支持）                                       │
│     timer = Timer.scheduledTimer(...)                                │
│     @Published elapsedTime 每秒更新                                  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Strategy.startBlocking(context, profile) [并行执行多个步骤]        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─ 1. 准备屏蔽配置快照 ─┐                                            │
│  │   snapshot = SharedData.createProfileSnapshot(profile)            │
│  │   session.snapshot = snapshot                                    │
│  └────────────────────┘                                             │
│          ↓                                                           │
│  ┌─ 2. 激活系统限制 ──────────────────┐                              │
│  │   appBlocker.activateRestrictions(snapshot)                      │
│  │   ↓                                                              │
│  │   ManagedSettingsStore.shield.applications = tokens             │
│  │   ManagedSettingsStore.shield.webDomains = tokens               │
│  │   ManagedSettingsStore.application.denyAppRemoval = strict      │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 3. 更新共享数据到 App Group ─────┐                              │
│  │   SharedData.saveActiveSession(snapshot)                         │
│  │   (供 Extensions / Widget 使用)                                  │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 4. 启动 Live Activity ────────────┐                              │
│  │   liveActivityManager.startSessionActivity(session)              │
│  │   → ActivityKit 启动 Live Activity                               │
│  │   → 显示在动态岛/锁屏                                             │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 5. 刷新 Widget ──────────────────┐                              │
│  │   WidgetCenter.shared.reloadAllTimelines()                       │
│  │   → 主屏 Widget 更新显示活跃 Profile                              │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 6. 注册计时监控（如需要）────────┐                              │
│  │   if let timer = strategy.getDuration() {                        │
│  │     DeviceActivityCenterUtil.startStrategyTimerActivity(profile) │
│  │     → 设定 timer 时间后自动停止                                   │
│  │   }                                                              │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 7. 调用策略特定的启动逻辑 ───────┐                              │
│  │   if strategy is NFCBlockingStrategy {                           │
│  │     // 需要原 NFC 标签才能停止                                    │
│  │     validateNFCTag()                                             │
│  │   }                                                              │
│  └────────────────────────────────────┘                             │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  策略回调：onSessionCreation 事件发出                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  strategy.onSessionCreation?(.started(session))                      │
│                                                                       │
│  UI 订阅此事件：                                                      │
│  - 显示"会话已启动"提示                                               │
│  - 更新 Dashboard 显示                                               │
│  - 显示 Timer 倒计时                                                  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        会话运行中状态                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  • 用户无法打开被屏蔽的应用（显示 Shield UI）                        │
│  • 无法访问被屏蔽的网站                                               │
│  • 如启用严格模式，无法卸载应用                                       │
│  • Timer 倒计时显示                                                   │
│  • Live Activity 显示在动态岛                                         │
│  • Widget 显示活跃 Profile                                            │
│                                                                       │
│  用户可以：                                                           │
│  ├─ 点击"休息"按钮（如启用）                                          │
│  ├─ 手动停止（如策略允许）                                            │
│  └─ 扫描 NFC/QR 解锁（如配置）                                        │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. 日程触发流程（Schedule）

```
┌─────────────────────────────────────────────────────────────────────┐
│  用户在 App 中设置日程                                               │
│  例如："周一到周五，每晚10点到早6点屏蔽 YouTube"                     │
├─────────────────────────────────────────────────────────────────────┤
│  BlockedProfileView 中点击"保存"                                     │
│  ↓                                                                   │
│  profile.schedule = BlockedProfileSchedule(                          │
│    days: [.monday, .tuesday, .wednesday, .thursday, .friday],       │
│    startHour: 22,  // 10 PM                                         │
│    endHour: 6,     // 6 AM                                          │
│    startMinute: 0,                                                  │
│    endMinute: 0                                                     │
│  )                                                                  │
│  ↓                                                                   │
│  modelContext.insert(profile)  // 保存到 SwiftData                  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  StrategyManager 接收到更新                                          │
│  → 触发 updateProfileSchedule(profile)                               │
├─────────────────────────────────────────────────────────────────────┤
│  ↓                                                                   │
│  DeviceActivityCenterUtil.scheduleTimerActivity(profile)             │
│  ↓                                                                   │
│  构建 DeviceActivitySchedule：                                       │
│  - repeatRule = .daily 或指定的 .weekday                             │
│  - intervalStart = 22:00                                            │
│  - intervalEnd = 06:00                                              │
│  - 作用范围 = 一周的指定日期                                          │
│  ↓                                                                   │
│  DeviceActivityCenter.startMonitoring(                               │
│    for: .scheduleTimerActivity_<profileId>,                         │
│    during: schedule                                                 │
│  )                                                                  │
│  ↓                                                                   │
│  向系统注册日程监控                                                   │
│  (系统会在后台持续监控时间)                                            │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
        [App 可以被杀死，系统会在后台继续监控]
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  系统检测：当前时间是否匹配日程？                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  例如：今天是周一晚上 22:00                                          │
│  ✓ 周一在 days 列表中                                               │
│  ✓ 当前时间 >= startHour (22:00)                                    │
│  ✓ 当前时间 < endHour (06:00)                                       │
│                                                                       │
│  → 系统决定："是的，应该启动屏蔽"                                     │
│  → 唤醒 FoqosDeviceMonitor Extension 进程                            │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  FoqosDeviceMonitor Extension 被唤醒                                 │
│  (仅当日程触发时，其他时间不占用资源)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  DeviceActivityMonitorExtension.intervalDidStart(                    │
│    for: .scheduleTimerActivity_<profileId>                          │
│  )                                                                  │
│  ↓                                                                   │
│  TimerActivityUtil.startTimerActivity(for: activity)                │
│  ↓                                                                   │
│  1. 从 activity 名称解析 profileId                                  │
│  2. 从 SharedData 读取 ProfileSnapshot                              │
│  3. AppBlockerUtil.activateRestrictions(snapshot)                   │
│     → ManagedSettingsStore 应用限制                                 │
│  4. SharedData.saveActiveSession(SessionSnapshot)                   │
│  5. 记录到 OSLog                                                     │
│                                                                       │
│  [此时 App 仍未启动，Extension 在后台快速完成]                       │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  限制现已生效                                                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  • 用户无法打开被屏蔽应用                                             │
│  • 如果 App 在后台，下次打开时会通过 AppGroup 检测到活跃会话          │
│  • Widget 可能检测到并刷新显示（如果启用）                            │
│  • 如果配置了 Live Activity，但当前 App 未启动，LA 不会显示           │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
        [继续运行直到 intervalEnd 时间到达]
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  系统检测：是否应该结束日程？                                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  例如：早上 06:00 到达                                              │
│  ✓ 当前时间 >= endHour (06:00)                                      │
│                                                                       │
│  → 系统决定：是的，停止屏蔽                                           │
│  → 再次唤醒 FoqosDeviceMonitor Extension                             │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  DeviceActivityMonitorExtension.intervalDidEnd(                      │
│    for: .scheduleTimerActivity_<profileId>                          │
│  )                                                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  TimerActivityUtil.stopTimerActivity(for: activity)                 │
│  ↓                                                                   │
│  1. 从 activity 名称解析 profileId                                  │
│  2. AppBlockerUtil.deactivateRestrictions()                         │
│     → ManagedSettingsStore 清空所有限制                             │
│  3. SharedData.clearActiveSession()                                 │
│  4. 记录到 OSLog                                                     │
│                                                                       │
│  [限制已完全解除]                                                     │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  [日程循环继续]                                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  系统继续监控直到用户禁用此日程：                                     │
│  user.schedule.isActive = false                                     │
│  → DeviceActivityCenterUtil.removeScheduleTimerActivities()         │
│  → DeviceActivityCenter.stopMonitoring()                            │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. 会话停止流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                        停止会话的多种方式                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─ 1. 用户手动停止                                                  │
│  │    Dashboard → 点击"停止"按钮                                      │
│  │                                                                    │
│  ├─ 2. 计时器到期                                                    │
│  │    Timer.scheduledTimer 倒数到 0                                  │
│  │    或 DeviceActivityCenter 的 intervalDidEnd 触发                  │
│  │                                                                    │
│  ├─ 3. 扫描 NFC/QR 解锁                                              │
│  │    NFCBlockingStrategy.stopBlocking()                            │
│  │    或 QRCodeBlockingStrategy.stopBlocking()                      │
│  │                                                                    │
│  ├─ 4. App Intent 停止                                              │
│  │    Shortcuts / Siri 调用 StopProfileIntent                        │
│  │                                                                    │
│  └─ 5. 紧急解锁                                                      │
│       StrategyManager.emergencyUnblock()                            │
│       (扣除一次配额，用户有限的紧急次数)                              │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ║ 所有停止方式汇聚到 StrategyManager
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  StrategyManager.stopSession(context, session)                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. 停止计时器                                                        │
│     timer?.invalidate()                                             │
│     @Published elapsedTime = 0                                      │
│                                                                       │
│  2. 验证停止权限（如果需要）                                          │
│     if strategy.requiresUnlockToStop() {                            │
│       // 例如 NFC 策略需要原标签验证                                 │
│       guard validateUnlock() else { return }                        │
│     }                                                               │
│                                                                       │
│  3. 标记会话结束时间                                                  │
│     session.endTime = Date()                                        │
│     try? modelContext.save()  // 持久化                             │
│                                                                       │
│  4. 更新 StrategyManager 状态                                        │
│     @Published activeSession = nil                                  │
│     @Published activeProfileId = nil                                │
│     @Published isBreakActive = false                                │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Strategy.stopBlocking(context, session) [并行执行多个步骤]        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─ 1. 解除系统限制 ──────────────────┐                              │
│  │   appBlocker.deactivateRestrictions()                            │
│  │   ↓                                                              │
│  │   ManagedSettingsStore.shield.applications = nil                │
│  │   ManagedSettingsStore.shield.webDomains = nil                  │
│  │   ManagedSettingsStore.application.denyAppRemoval = false       │
│  │   ManagedSettingsStore.clearAllSettings()                       │
│  └────────────────────────────────────┘                             │
│          ↓ [限制立即解除]                                             │
│  ┌─ 2. 清空共享数据 ──────────────────┐                              │
│  │   SharedData.clearActiveSession()                                │
│  │   (告诉 Extensions/Widget：没有活跃会话了)                        │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 3. 取消计时监控 ──────────────────┐                              │
│  │   if let timerActivity = strategy.getTimerActivity() {           │
│  │     DeviceActivityCenter.stopMonitoring(for: timerActivity)      │
│  │     (停止自动倒计时)                                              │
│  │   }                                                              │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 4. 结束 Live Activity ────────────┐                              │
│  │   liveActivityManager.endSessionActivity()                       │
│  │   → ActivityKit 结束活动                                          │
│  │   → 动态岛/锁屏计时器消失                                          │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 5. 刷新 Widget ──────────────────┐                              │
│  │   WidgetCenter.shared.reloadAllTimelines()                       │
│  │   → Widget 更新显示"无活跃会话"                                    │
│  └────────────────────────────────────┘                             │
│          ↓                                                           │
│  ┌─ 6. 发送完成通知（可选）──────────┐                              │
│  │   if session.duration > threshold {                              │
│  │     TimersUtil.scheduleNotification(                             │
│  │       title: "屏蔽完成",                                          │
│  │       body: "已成功屏蔽 X 分钟"                                    │
│  │     )                                                            │
│  │   }                                                              │
│  └────────────────────────────────────┘                             │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  策略回调：onSessionCreation 事件发出                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  strategy.onSessionCreation?(.ended(profile))                        │
│                                                                       │
│  UI 订阅此事件：                                                      │
│  - 显示"会话已结束"提示                                               │
│  - 显示会话统计（持续时间、屏蔽的应用等）                              │
│  - 返回 Dashboard 主视图                                              │
│  - 清空计时器显示                                                     │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    会话完全停止，恢复正常状态                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  • 用户可以打开之前被屏蔽的应用                                       │
│  • 可以访问被屏蔽的网站                                               │
│  • 可以卸载应用（如之前启用了严格模式）                                │
│  • Widget 显示"开始新会话"选项                                        │
│  • Live Activity 消失                                                │
│                                                                       │
│  [下一次用户可以启动新的会话]                                          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. 跨进程通信架构

```
┌──────────────────────────────────────┐
│        Main App (foqos)              │
├──────────────────────────────────────┤
│                                       │
│  SwiftData:                          │
│  ├─ BlockedProfiles                  │
│  ├─ BlockedProfileSession            │
│  └─ [完整对象，包含关系和方法]        │
│                                       │
│  ↓ [需要共享给 Extensions]           │
│                                       │
│  SharedData (创建快照)               │
│  ├─ ProfileSnapshot                  │
│  │  ├─ id, name                      │
│  │  ├─ selectedActivity              │
│  │  ├─ domains, strategy...          │
│  │  └─ [可序列化 JSON 字符串]         │
│  │                                    │
│  └─ SessionSnapshot                  │
│     ├─ id, blockedProfileId          │
│     ├─ startTime, endTime            │
│     └─ [可序列化 JSON 字符串]         │
│                                       │
│  ↓ [存储到 App Group]                │
│                                       │
│  App Group UserDefaults              │
│  Suite: "group.com.lxt.foqos.data"  │
│  ├─ Key: "profileSnapshots"          │
│  │  Value: JSON 数组                  │
│  │                                    │
│  ├─ Key: "activeScheduleSession"     │
│  │  Value: JSON 对象                  │
│  │                                    │
│  └─ Key: "completedScheduleSessions" │
│     Value: JSON 数组                  │
│                                       │
└──────────────────────────────────────┘
           ║
           ║ [IPC: App Group 共享]
           ↓
┌──────────────────────────────────────┐
│  FoqosDeviceMonitor Extension        │
├──────────────────────────────────────┤
│                                       │
│  在后台被系统唤醒时：                │
│  DeviceActivityMonitorExtension       │
│    .intervalDidStart()               │
│    ↓                                  │
│  1. 读取 App Group UserDefaults      │
│     profileSnapshots = read()         │
│                                       │
│  2. 从 activity 名称解析 profileId   │
│                                       │
│  3. 获取对应的 ProfileSnapshot       │
│     snapshot = profileSnapshots[id]   │
│                                       │
│  4. 调用 AppBlockerUtil               │
│     appBlocker.activateRestrictions(snapshot)
│                                       │
│  5. 更新 App Group (SessionSnapshot) │
│     UserDefaults.set(sessionSnapshot) │
│                                       │
└──────────────────────────────────────┘
           ║
           ║ [IPC: App Group 共享]
           ↓
┌──────────────────────────────────────┐
│  FoqosWidget Extension               │
├──────────────────────────────────────┤
│                                       │
│  定期刷新 Widget 时：                │
│  ProfileControlProvider              │
│    .getTimeline()                    │
│    ↓                                  │
│  1. 读取 App Group UserDefaults      │
│     profileSnapshots = read()         │
│     activeSession = read()            │
│                                       │
│  2. 获取当前活跃的 Profile 快照      │
│     if activeSession != nil {         │
│       profile = profileSnapshots[id]  │
│     }                                 │
│                                       │
│  3. 渲染 Widget 内容                  │
│     显示活跃 Profile 的信息            │
│                                       │
│  4. 生成 Deep Link (可选)             │
│     https://foqos.app/profile/<id>   │
│     当用户点击 Widget 时打开 App      │
│                                       │
└──────────────────────────────────────┘
           ║
           ║ [IPC: App Group 共享]
           ↓
┌──────────────────────────────────────┐
│  ShieldConfiguration Extension       │
├──────────────────────────────────────┤
│                                       │
│  当用户点击被屏蔽应用时：             │
│  ShieldConfigurationExtension        │
│    .configuration()                  │
│    ↓                                  │
│  1. 读取 App Group 数据（可选）      │
│     ThemeManager 的色彩配置           │
│                                       │
│  2. 生成自定义 ShieldConfiguration   │
│     包含品牌色、提示文案、表情图标    │
│                                       │
│  3. 返回给系统                       │
│     系统显示这个 Shield UI             │
│                                       │
└──────────────────────────────────────┘
```

---

## 5. App Intent / Shortcuts 流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                      用户通过 Shortcuts 触发                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Shortcuts App / Siri 显示：                                         │
│  "开始 Foqos Profile"                                               │
│           ↓ [用户选择一个 Profile，可选输入持续时间]                  │
│                                                                       │
│  Shortcuts 调用：                                                    │
│  StartProfileIntent(profile: BlockedProfileEntity)                  │
│                                                                       │
│  或：                                                                │
│  StopProfileIntent(profile: BlockedProfileEntity)                   │
│                                                                       │
│  或：                                                                │
│  CheckSessionActiveIntent() → 返回 true/false                       │
│                                                                       │
│  或：                                                                │
│  CheckProfileStatusIntent(profile: BlockedProfileEntity) → true/false
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  StartProfileIntent.perform()                                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  @MainActor                                                         │
│  func perform() async throws -> some IntentResult {                 │
│    // 1. 从 DI 容器获取 ModelContainer                              │
│    let modelContainer = AppDependencyManager.shared                 │
│      .resolve("ModelContainer") as ModelContainer                   │
│                                                                       │
│    let modelContext = modelContainer.mainContext                    │
│                                                                       │
│    // 2. 调用 StrategyManager 的后台启动方法                        │
│    StrategyManager.shared.startSessionFromBackground(               │
│      profile.id,                                                    │
│      context: modelContext,                                         │
│      durationInMinutes: durationInMinutes                          │
│    )                                                                │
│                                                                       │
│    // 3. 返回结果                                                    │
│    return .result()  // 或 .result(value: returnValue)              │
│  }                                                                  │
│                                                                       │
│  [流程完全同 startSession()，只是在后台执行]                        │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓ [同 会话启动流程]
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  会话启动（与手动启动完全相同）                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  • 创建 BlockedProfileSession                                       │
│  • 应用限制                                                          │
│  • 启动 Live Activity (App 可能不在前台)                            │
│  • 注册计时                                                          │
│                                                                       │
│  特点：                                                              │
│  - 不会自动打开 App (openAppWhenRun = false)                       │
│  - 用户可能感觉不到任何 UI 变化，但限制已生效                        │
│  - 可以与其他 Shortcuts 操作组合                                     │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Shortcuts 继续执行后续操作（可选）                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  示例 Shortcut 脚本：                                                │
│                                                                       │
│  1️⃣ 运行 "Start Foqos Profile" (选择 YouTube)                      │
│  2️⃣ 等待 5 分钟 (使用系统 "Wait" 操作)                             │
│  3️⃣ 设置屏幕亮度为 10%                                              │
│  4️⃣ 启用静音模式                                                    │
│  5️⃣ 显示通知："专注模式已启动，享受无干扰时间"                       │
│                                                                       │
│  [更高级的自动化场景]                                                │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. 休息模式流程

```
┌─────────────────────────────────────────────────────────────────────┐
│  会话进行中                                                         │
│  ↓                                                                   │
│  StrategyManager.activeSession != nil                               │
│  && profile.enableBreaks == true                                    │
│                                                                       │
│  → UI 显示"休息 X 分钟"按钮                                          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  用户点击"休息"按钮                                                  │
│  ↓                                                                   │
│  StrategyManager.toggleBreak(context: modelContext)                 │
│                                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. 标记休息开始时间                                                 │
│     activeSession.breakStartTime = Date()                           │
│     @Published isBreakActive = true                                 │
│                                                                       │
│  2. 临时解除限制                                                     │
│     appBlocker.deactivateRestrictions()                             │
│     [用户现在可以使用被屏蔽的应用]                                    │
│                                                                       │
│  3. 注册休息时长计时                                                │
│     breakDurationMinutes = profile.breakTimeInMinutes (默认 15)     │
│     DeviceActivityCenterUtil.startBreakTimerActivity()              │
│     [注册一个 15 分钟后的定时器]                                     │
│                                                                       │
│  4. 更新 Live Activity                                              │
│     liveActivityManager.updateBreakState(session)                   │
│     → Live Activity 显示"休息中，剩余 15 分钟"                       │
│                                                                       │
│  5. 更新 Widget                                                      │
│     WidgetCenter.shared.reloadAllTimelines()                        │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  休息期间 (用户可自由使用被屏蔽应用)                                │
│                                                                       │
│  倒计时选项：                                                        │
│  ┌─ A. 15 分钟到期后自动恢复屏蔽                                     │
│  │    DeviceActivityMonitorExtension.intervalDidEnd()               │
│  │    → 自动应用限制                                                 │
│  │                                                                    │
│  ├─ B. 用户手动点击"结束休息"                                        │
│  │    StrategyManager.toggleBreak()                                 │
│  │    → 立即应用限制                                                 │
│  │                                                                    │
│  └─ C. 用户停止整个会话                                              │
│       StrategyManager.stopSession()                                 │
│       → 限制完全解除（休息被忽略）                                    │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
        ↓
        [选项 A 或 B: 休息结束]
        ↓
┌─────────────────────────────────────────────────────────────────────┐
│  休息结束，恢复屏蔽                                                  │
│                                                                       │
│  1. 标记休息结束时间                                                 │
│     activeSession.breakEndTime = Date()                             │
│     @Published isBreakActive = false                                │
│                                                                       │
│  2. 重新应用限制                                                     │
│     appBlocker.activateRestrictions(snapshot)                       │
│     [被屏蔽的应用再次无法使用]                                       │
│                                                                       │
│  3. 取消休息计时                                                     │
│     DeviceActivityCenter.stopMonitoring()                           │
│                                                                       │
│  4. 更新 Live Activity                                              │
│     liveActivityManager.updateBreakState(session)                   │
│     → Live Activity 重新显示屏蔽倒计时                               │
│                                                                       │
│  5. 更新 Widget                                                      │
│     WidgetCenter.shared.reloadAllTimelines()                        │
│                                                                       │
│  [会话继续进行，直到手动停止或定时器到期]                             │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. 数据层次及同步

```
┌─────────────────────────────────────────┐
│         数据层级                         │
├─────────────────────────────────────────┤
│                                          │
│  L1. 系统状态 (ManagedSettingsStore)    │
│      ↑
│      │ [设置限制时写入]
│      │ [读取状态用于验证]
│      │
│  L2. SwiftData (App 本地数据库)        │
│      ├─ BlockedProfiles (配置)         │
│      ├─ BlockedProfileSession (会话)   │
│      └─ [关系完整，含对象和方法]         │
│      ↑
│      │ [创建快照时读取]
│      │ [会话状态更新时写入]
│      │
│  L3. SharedData 快照 (跨进程)           │
│      ├─ ProfileSnapshot (可序列化)      │
│      └─ SessionSnapshot (可序列化)      │
│      ↑
│      │ [存储到 UserDefaults]
│      │
│  L4. App Group UserDefaults             │
│      Suite: "group.com.lxt.foqos.data" │
│      ├─ profileSnapshots (JSON)         │
│      ├─ activeScheduleSession (JSON)    │
│      └─ completedScheduleSessions (JSON)│
│      ↑
│      │ [Extensions 读取]
│      │
│  L5. 系统限制执行 (ManagedSettings)     │
│      └─ [用户设备体验: 应用屏蔽等]      │
│                                          │
└─────────────────────────────────────────┘


同步关键点：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【启动会话】
SwiftData ← 创建 Session 对象
    ↓
    ↓ [创建快照]
SharedData
    ↓
    ↓ [保存到 App Group]
App Group UserDefaults
    ↓
    ↓ [Extension 读取]
AppBlockerUtil
    ↓
ManagedSettingsStore [系统执行限制]

【停止会话】
SwiftData ← 标记 Session.endTime
    ↓
    ↓ [清空快照]
SharedData
    ↓
    ↓ [清空 App Group]
App Group UserDefaults
    ↓
    ↓ [Extension 读取并执行]
AppBlockerUtil
    ↓
ManagedSettingsStore [系统解除限制]

【日程触发】(App 可能未运行)
App Group UserDefaults [Extension 启动时读取]
    ↓
AppBlockerUtil
    ↓
ManagedSettingsStore [系统执行限制]

【Widget 刷新】(App 可能未运行)
App Group UserDefaults [Widget 刷新时读取]
    ↓
ProfileControlProvider [生成 Widget 内容]
    ↓
[Widget UI 更新]
```

---

## 关键同步规则

| 场景           | 数据源          | 写入方          | 读取方              | 同步时机        |
| -------------- | --------------- | --------------- | ------------------- | --------------- |
| 启动会话       | SwiftData       | App             | App/StrategyManager | 即时            |
| 创建快照       | BlockedProfiles | StrategyManager | SharedData          | 启动会话时      |
| 共享配置       | SharedData      | App             | Extension           | App 写入后      |
| Extension 执行 | SharedData      | Extension       | AppBlockerUtil      | 触发时          |
| 会话结束       | SwiftData       | App             | App                 | 即时            |
| 清空快照       | SharedData      | App             | Extension           | 停止会话后      |
| Widget 刷新    | SharedData      | 不修改          | Widget              | 定期 + 事件驱动 |
| Live Activity  | StrategyManager | App             | ActivityKit         | 会话状态变化时  |

---

## 故障排除流程图

```
问题：应用没有被屏蔽
    ↓
检查清单：
    ├─ ✓ 是否已授权 FamilyControls?
    │   └─ 否 → RequestAuthorizer.requestAuthorization()
    │
    ├─ ✓ 会话是否已启动?
    │   │   StrategyManager.activeSession != nil
    │   └─ 否 → 手动启动会话
    │
    ├─ ✓ ManagedSettingsStore 状态?
    │   │   AppBlockerUtil.store.shield.applications != nil
    │   └─ 否 → 调用 activateRestrictions()
    │
    ├─ ✓ 应用是否在 selectedActivity 中?
    │   │   profile.selectedActivity.applicationTokens
    │   └─ 否 → 重新选择应用
    │
    └─ ✓ SharedData 是否同步?
        │   SharedData.getActiveSharedSession()
        └─ 否 → 检查 App Group 权限


问题：日程没有触发
    ↓
检查清单：
    ├─ ✓ 日程是否启用?
    │   │   profile.schedule.isActive == true
    │   └─ 否 → 启用日程
    │
    ├─ ✓ 当前日期时间是否匹配?
    │   │   weekday in days && time in range
    │   └─ 否 → 调整时间或日期
    │
    ├─ ✓ DeviceActivityCenter 是否已注册?
    │   │   DeviceActivityCenterUtil.scheduleTimerActivity()
    │   └─ 否 → 手动注册
    │
    ├─ ✓ Extension 是否被系统唤醒?
    │   │   查看 OSLog 日志
    │   └─ 否 → 检查系统设置和电池模式
    │
    └─ ✓ 权限是否被撤销?
        │   设置 > 屏幕使用时间
        └─ 是 → 重新授权


问题：Widget 没有更新
    ↓
检查清单：
    ├─ ✓ Widget 是否已添加到主屏?
    │   └─ 否 → 添加 Widget
    │
    ├─ ✓ SharedData 中是否有有效数据?
    │   │   SharedData.profileSnapshots
    │   └─ 否 → 检查 App Group 权限
    │
    ├─ ✓ Widget Extension entitlements?
    │   │   App Group 一致
    │   └─ 否 → 检查 entitlements 配置
    │
    └─ ✓ 手动刷新 Widget
        │   长按 Widget → 编辑 → 完成
        └─ 如仍无效 → 重启设备
```

