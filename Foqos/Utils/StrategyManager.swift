import SwiftData
import SwiftUI
import WidgetKit

/**
 # 会话管理协调器(Session Coordination Manager)
 
 ## 1️⃣ 作用与核心功能
 
 本管理类为专注力/阻止应用(Focus/Blocking App)提供会话生命周期的统一协调层。主要功能包括:
 
 ### 输入 → 处理 → 输出示例:
 
 - **启动会话**: 接收 `BlockedProfiles` (阻止配置) → 调用对应策略(Strategy) → 创建 `BlockedProfileSession` → 更新 `activeSession`、启动计时器、同步 Widget & Live Activity
 - **停止会话**: 传入当前活动会话 → 调用策略停止逻辑 → 清理计时器、取消通知、刷新 Widget & Live Activity
 - **切换休息**: 检测 `activeSession.isBreakAvailable` → 启动/停止 DeviceActivity 休息计时器 → 安排回归提醒
 - **紧急解锁**: 验证剩余次数 → 强制终止会话(绕过策略限制) → 消耗一次紧急解锁配额(默认3次/4周)
 
 ---
 
 ## 2️⃣ 项目内用法与相关功能
 
 ### 🎯 用法 1: App 入口注入(Singleton + EnvironmentObject)
 **关联流程**: App 初始化 → 注入为环境对象 → 全局可访问
 
 ```swift
 @main
 struct FocusApp: App {
   @StateObject private var strategyManager = StrategyManager.shared
   
   var body: some Scene {
     WindowGroup {
       <RootView>()
         .environmentObject(strategyManager)
     }
     .modelContainer(container)
   }
 }
 ```
 
 ### 🎯 用法 2: 主界面切换阻止状态(UI Toggle)
 **关联流程**: 用户点击配置卡片 → 调用 `toggleBlocking` → 自动判断开始/停止 → UI 自动刷新
 
 ```swift
 struct <DashboardView>: View {
   @EnvironmentObject var strategyManager: StrategyManager
   @Environment(\.modelContext) private var context
   
   var body: some View {
     Button("Toggle Focus") {
       strategyManager.toggleBlocking(
         context: context,
         activeProfile: selectedProfile
       )
     }
   }
 }
 ```
 
 ### 🎯 用法 3: 休息模式切换(Break Management)
 **关联流程**: 会话进行中 → 用户请求休息 → 临时解除限制 → 倒计时结束自动恢复
 
 ```swift
 struct <SessionControlPanel>: View {
   @EnvironmentObject var strategyManager: StrategyManager
   
   var body: some View {
     if strategyManager.isBreakAvailable {
       Button(strategyManager.isBreakActive ? "End Break" : "Take Break") {
         strategyManager.toggleBreak(context: context)
       }
     }
   }
 }
 ```
 
 ### 🎯 用法 4: App Intent 后台启动(Background Trigger)
 **关联流程**: Shortcuts/Siri/Widget → 调用 App Intent → 静默启动会话
 
 ```swift
 struct <StartSessionIntent>: AppIntent {
   @MainActor
   func perform() async throws -> some IntentResult {
     StrategyManager.shared.startSessionFromBackground(
       profileId,
       context: modelContext,
       durationInMinutes: 60
     )
     return .result()
   }
 }
 ```
 
 ### 🎯 用法 5: 紧急解锁(Emergency Override)
 **关联流程**: 设置页 → 用户触发紧急解锁 → 扣除配额 → 强制停止当前会话
 
 ```swift
 struct <EmergencyView>: View {
   @EnvironmentObject var strategyManager: StrategyManager
   
   private func performEmergencyUnblock() {
     guard strategyManager.getRemainingEmergencyUnblocks() > 0 else { return }
     strategyManager.emergencyUnblock(context: context)
     // 会话立即终止,Widget 同步刷新
   }
 }
 ```
 
 ### 🎯 用法 6: 计时器状态展示(Timer Display)
 **关联流程**: 会话运行中 → 订阅 `@Published elapsedTime` → UI 实时显示倒计时/已用时长
 
 ```swift
 struct <SessionTimerView>: View {
   @EnvironmentObject var strategyManager: StrategyManager
   
   var body: some View {
     Text(strategyManager.elapsedTime.formatMMSS)
       .onAppear {
         // strategyManager.startTimer() 在会话创建时自动调用
       }
   }
 }
 ```
 
 ---
 
 ## 3️⃣ GitHub 公开仓库常见模式
 
 基于对 Swift 生态的分析,类似的单例管理模式在以下场景中广泛使用:
 
 ### 🌍 模式 1: `@StateObject` + `.shared` Singleton Pattern
 **典型应用**: 全局状态管理器(如主题、网络、音频播放器)
 
 ```swift
 class <GlobalStateManager>: ObservableObject {
   static let shared = <GlobalStateManager>()
   @Published var currentState: <State> = .idle
   
   func updateState(to newState: <State>) {
     currentState = newState
   }
 }
 
 @main
 struct <App>: App {
   @StateObject private var stateManager = <GlobalStateManager>.shared
   
   var body: some Scene {
     WindowGroup {
       <ContentView>()
         .environmentObject(stateManager)
     }
   }
 }
 ```
 
 ### 🌍 模式 2: Session-Based Architecture with Timer
 **典型应用**: Pomodoro 计时器、健身追踪、媒体播放器
 
 ```swift
 class <SessionCoordinator>: ObservableObject {
   @Published var activeSession: <Session>?
   @Published var elapsedTime: TimeInterval = 0
   private var timer: Timer?
   
   func startSession(config: <Configuration>) {
     let session = <Session>(config: config, startTime: Date())
     activeSession = session
     
     timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
       self.elapsedTime = Date().timeIntervalSince(session.startTime)
     }
   }
   
   func stopSession() {
     timer?.invalidate()
     timer = nil
     activeSession = nil
     elapsedTime = 0
   }
 }
 ```
 
 ### 🌍 模式 3: Strategy Pattern with Dynamic View Injection
 **典型应用**: 支付网关选择、认证方式切换、主题引擎
 
 ```swift
 protocol <ExecutionStrategy> {
   func execute(context: <Context>) -> (any View)?
 }
 
 class <StrategyCoordinator>: ObservableObject {
   static let availableStrategies: [<ExecutionStrategy>] = [
     <StrategyA>(), <StrategyB>(), <StrategyC>()
   ]
   
   @Published var customView: (any View)? = nil
   
   func getStrategy(id: String) -> <ExecutionStrategy> {
     let strategy = Self.availableStrategies.first { $0.identifier == id } ?? <DefaultStrategy>()
     
     // 注入回调以便策略可以展示自定义 UI
     strategy.onViewRequired = { view in
       self.customView = view
     }
     
     return strategy
   }
 }
 ```
 
 ### 🌍 模式 4: Emergency Override with Quota Management
 **典型应用**: 试用次数限制、跳过广告配额、快速登录令牌
 
 ```swift
 class <QuotaManager>: ObservableObject {
   @AppStorage("remainingCredits") private var credits: Int = 3
   @AppStorage("resetPeriodWeeks") private var resetWeeks: Int = 4
   @AppStorage("lastResetTimestamp") private var lastReset: Double = 0
   
   func consumeCredit() {
     guard credits > 0 else { return }
     credits -= 1
   }
   
   func checkAndResetIfNeeded() {
     let elapsed = Date().timeIntervalSince(Date(timeIntervalSinceReferenceDate: lastReset))
     let periodInSeconds = TimeInterval(resetWeeks * 7 * 24 * 60 * 60)
     
     if elapsed >= periodInSeconds {
       credits = 3
       lastReset = Date().timeIntervalSinceReferenceDate
     }
   }
 }
 ```
 
 ### 🌍 模式 5: Cross-Extension State Sync (App Groups + Snapshots)
 **典型应用**: Widget 数据同步、Extension 状态共享、剪贴板扩展
 
 ```swift
 class <SyncCoordinator>: ObservableObject {
   @Published var activeSession: <Session>?
   
   func syncToExtensions() {
     // 将状态序列化到 App Group Shared Container
     if let snapshot = activeSession?.toSnapshot() {
       <SharedDataStore>.save(snapshot, to: "active_session")
     }
     
     // 通知 Widget 刷新
     WidgetCenter.shared.reloadTimelines(ofKind: "<WidgetKind>")
   }
   
   func loadFromExtensions() {
     if let snapshot = <SharedDataStore>.load(from: "active_session") {
       activeSession = <Session>.fromSnapshot(snapshot)
     }
   }
 }
 ```
 
 ---
 
 ## ⚠️ 注意事项与平台差异
 
 ### 线程安全(Thread Safety)
 - 所有 `@Published` 属性变更会自动派发到主线程(Main Thread)
 - Timer 在 `startTimer()` 中使用 `scheduledTimer`,默认运行在主运行循环(Main RunLoop)
 - 策略回调(`onSessionCreation`, `onErrorMessage`)应确保在主线程更新 UI
 
 ### 真机 vs 模拟器差异
 - **FamilyControls(Screen Time API)**: 模拟器无法测试,必须在真机运行(需要配置 entitlements)
 - **NFC/QR 策略**: 部分硬件特性仅真机可用
 - **App Groups**: 在调试时需确保所有 Target(App + Extensions)使用相同的 App Group ID
 
 ### SwiftData 并发模型
 - `ModelContext` 是线程绑定的(Thread-bound)
 - 必须在同一线程/Actor 内使用同一个 `ModelContext` 实例
 - App Intent 通过 `AppDependencyManager` 异步获取共享的 `ModelContainer`
 
 ### Entitlements 前置条件
 - **Family Controls**: 需在 `*.entitlements` 中启用 Screen Time API
 - **App Groups**: 用于主 App 与 Extension 间共享数据
 - **NFC**: 需要 NFC Tag Reading entitlement(部分策略依赖)
 
 ---
 
 ## 📖 相关系统类型
 
 - `BlockedProfiles`: 阻止配置的主数据模型(SwiftData)
 - `BlockedProfileSession`: 单次会话记录,包含开始时间、结束时间、休息状态等
 - `BlockingStrategy`: 策略协议,定义 `startBlocking` / `stopBlocking` 行为
 - `LiveActivityManager`: 管理 iOS 16+ Dynamic Island / Lock Screen 实时活动
 - `DeviceActivityCenterUtil`: 封装 DeviceActivity 框架(Schedule 定时、Break 休息)
 - `AppBlockerUtil`: 包装 `ManagedSettingsStore`,实际执行 App/Website 限制
 */

// MARK: - StrategyManager Implementation
// StrategyManager 实现 / StrategyManager Implementation
/// 
/// ⚠️ 架构问题 / Architecture Issue: 
/// 此类承担了过多职责（God Object 反模式），应该拆分为：
/// This class has too many responsibilities (God Object anti-pattern), should be split into:
/// - SessionCoordinator: 会话生命周期管理 / Session lifecycle management
/// - TimerManager: 计时器管理 / Timer management  
/// - StrategyRegistry: 策略注册和获取 / Strategy registration and retrieval
/// - EmergencyManager: 紧急解锁配额管理 / Emergency unlock quota management
/// 
/// 📊 文件统计 / File Statistics: 963 行 / 963 lines (P0 重构目标 / P0 refactoring target)
///
/// 🔄 状态同步统一入口（计划）/ Unified State Sync Gateway (Planned)
/// 为了避免在多个方法中重复更新 Widget、Live Activity、App Group 快照，建议收敛到单一网关：
/// `syncState(profile: BlockedProfiles?, session: BlockedProfileSession?, reason: StateChangeReason)`。
///
/// - 触发时机：任何开始/停止/休息切换/计时策略变更/策略自定义视图完成后。
/// - 执行内容：
///   1) 更新 AppBlockerUtil 状态（若需要），
///   2) 刷新 SharedData 快照（ProfileSnapshot / SessionSnapshot），
///   3) 通知 WidgetCenter.reloadTimelines，
///   4) 刷新/结束 LiveActivity（ActivityKit）。
/// - 收敛收益：消除分散的副作用调用，降低遗漏与一致性风险，便于测试与回滚。
class StrategyManager: ObservableObject {
  
  // MARK: - Singleton Instance
  // 全局单例实例 / Global Singleton Instance
  /// 整个应用共享同一个 StrategyManager 实例
  /// The entire app shares the same StrategyManager instance
  /// 
  /// ⚠️ 注意 / Note: Singleton 模式使测试困难，重构时考虑依赖注入
  /// Singleton pattern makes testing difficult, consider DI during refactoring
  static var shared = StrategyManager()

  // MARK: - Strategy Registry
  // 策略注册表 / Strategy Registry
  /// 所有可用的屏蔽策略列表（共 8 种）
  /// List of all available blocking strategies (8 total)
  /// 
  /// 📌 策略类型 / Strategy Types:
  /// - Manual: 手动开始/停止 / Manual start/stop
  /// - NFC: 需要扫描 NFC 标签才能停止 / Requires NFC tag scan to stop
  /// - NFCManual: NFC + 手动停止 / NFC + manual stop
  /// - NFCTimer: NFC + 定时自动停止 / NFC + timer auto-stop
  /// - QRCode: 需要扫描二维码才能停止 / Requires QR code scan to stop
  /// - QRManual: QR + 手动停止 / QR + manual stop
  /// - QRTimer: QR + 定时自动停止 / QR + timer auto-stop
  /// - ShortcutTimer: 通过 Shortcuts 启动的定时会话 / Timer session via Shortcuts
  /// 
  /// 🔄 策略选择流程 / Strategy Selection Flow:
  /// BlockedProfiles.blockingStrategyId -> getStrategy(id:) -> 返回对应策略实例
  /// BlockedProfiles.blockingStrategyId -> getStrategy(id:) -> Returns strategy instance
  static let availableStrategies: [BlockingStrategy] = [
    ManualBlockingStrategy(),
    NFCBlockingStrategy(),
    NFCManualBlockingStrategy(),
    NFCTimerBlockingStrategy(),
    QRCodeBlockingStrategy(),
    QRManualBlockingStrategy(),
    QRTimerBlockingStrategy(),
    ShortcutTimerBlockingStrategy(),
  ]

  // MARK: - Published Properties (UI Observable State)
  // 发布属性（UI 可观察状态）/ Published Properties (UI Observable State)
  
  /// 已过时间（会话模式）或剩余时间（休息模式）
  /// Elapsed time (session mode) or remaining time (break mode)
  /// 
  /// 📊 更新频率 / Update Frequency: 每秒更新 / Updated every second
  /// 🔄 数据流 / Data Flow: timer -> elapsedTime -> UI (Text/ProgressView)
  @Published var elapsedTime: TimeInterval = 0
  
  /// 计时器实例（每秒触发一次）
  /// Timer instance (fires every second)
  /// 
  /// ⚠️ 生命周期 / Lifecycle: 会话开始时创建，结束时销毁
  /// Created when session starts, invalidated when session ends
  @Published var timer: Timer?
  
  /// 当前活动会话（如果存在）
  /// Current active session (if exists)
  /// 
  /// 🔑 关键属性 / Key Property: 整个应用的核心状态
  /// Core state of the entire app
  /// - nil: 无活动会话 / No active session
  /// - BlockedProfileSession: 有活动会话 / Has active session
  /// 
  /// 📍 使用位置 / Used In:
  /// - Dashboard: 显示会话状态 / Display session status
  /// - SessionView: 显示会话详情 / Display session details
  /// - Widget: 同步到 Widget / Sync to Widget
  /// - Live Activity: 同步到动态岛 / Sync to Dynamic Island
  @Published var activeSession: BlockedProfileSession?

  /// 是否显示策略自定义视图（如 NFC 扫描界面）
  /// Whether to show strategy custom view (e.g., NFC scan UI)
  /// 
  /// 🎯 用途 / Purpose: 某些策略需要显示特殊 UI（如 NFC/QR 扫描）
  /// Some strategies need to show special UI (e.g., NFC/QR scanning)
  @Published var showCustomStrategyView: Bool = false
  
  /// 策略自定义视图内容（类型擦除的 View）
  /// Strategy custom view content (type-erased View)
  /// 
  /// 💡 实现方式 / Implementation: 使用 `any View` 实现动态视图注入
  /// Uses `any View` for dynamic view injection
  @Published var customStrategyView: (any View)? = nil

  /// 错误消息（显示在 UI 顶部）
  /// Error message (displayed at top of UI)
  /// 
  /// 🔄 数据流 / Data Flow: 策略回调 -> errorMessage -> Alert/Toast
  @Published var errorMessage: String?

  // MARK: - Persistent Storage (Emergency Unlocks)
  // 持久化存储（紧急解锁配额）/ Persistent Storage (Emergency Unlocks)
  
  /// 剩余紧急解锁次数（默认 3 次）
  /// Remaining emergency unlock count (default: 3)
  /// 
  /// 💰 配额机制 / Quota Mechanism:
  /// - 初始值：3 次 / Initial: 3 times
  /// - 每次紧急解锁消耗 1 次 / Each emergency unlock consumes 1
  /// - 定期重置（默认 4 周）/ Resets periodically (default: 4 weeks)
  /// 
  /// 🔐 使用场景 / Use Case: 用户真正需要但无法通过正常方式停止会话时
  /// When user genuinely needs to stop session but can't through normal means
  @AppStorage("emergencyUnblocksRemaining") private var emergencyUnblocksRemaining: Int = 3
  
  /// 紧急解锁重置周期（周数，默认 4 周）
  /// Emergency unlock reset period (in weeks, default: 4)
  @AppStorage("emergencyUnblocksResetPeriodInWeeks") private
    var emergencyUnblocksResetPeriodInWeeks: Int = 4
  
  /// 上次重置紧急解锁的时间戳
  /// Timestamp of last emergency unlock reset
  /// 
  /// 📅 格式 / Format: TimeInterval since reference date (Double)
  @AppStorage("lastEmergencyUnblocksResetDate") private var lastEmergencyUnblocksResetDateTimestamp:
    Double = 0

  // MARK: - Private Dependencies
  // 私有依赖 / Private Dependencies
  
  /// Live Activity 管理器（管理动态岛显示）
  /// Live Activity manager (manages Dynamic Island display)
  private let liveActivityManager = LiveActivityManager.shared

  /// 计时器工具（后台任务和通知）
  /// Timer utility (background tasks and notifications)
  private let timersUtil = TimersUtil()
  
  /// App 屏蔽工具（执行实际的 App/Website 限制）
  /// App blocker utility (executes actual App/Website restrictions)
  private let appBlocker = AppBlockerUtil()

  // MARK: - Computed Properties
  // 计算属性 / Computed Properties
  
  /// 是否正在屏蔽（是否有活动会话）
  /// Whether currently blocking (has active session)
  /// 
  /// 🔄 数据流 / Data Flow: activeSession?.isActive -> UI enable/disable logic
  /// 📍 使用位置 / Used In: Dashboard 按钮状态、Widget 显示
  var isBlocking: Bool {
    return activeSession?.isActive == true
  }

  /// 休息模式是否激活
  /// Whether break mode is active
  /// 
  /// 📊 判断逻辑 / Logic: 
  /// - true: 用户正在休息，限制已临时解除
  /// - false: 正常会话或无会话
  var isBreakActive: Bool {
    return activeSession?.isBreakActive == true
  }

  /// 休息模式是否可用
  /// Whether break mode is available
  /// 
  /// 📋 可用条件 / Available When:
  /// - 有活动会话 AND
  /// - 配置文件启用了休息功能 (breakTimeInMinutes > 0)
  var isBreakAvailable: Bool {
    return activeSession?.isBreakAvailable ?? false
  }

  // MARK: - Public Methods - Reminder
  // 公开方法 - 提醒 / Public Methods - Reminder
  
  /// 生成默认的提醒消息
  /// Generate default reminder message
  /// 
  /// - Parameter profile: 配置文件（可选）
  /// - Returns: 提醒消息文本
  /// 
  /// 📝 消息格式 / Message Format:
  /// - 有 profile: "Get back to productivity by enabling {profileName}"
  /// - 无 profile: "Get back to productivity"
  /// 
  /// 🎯 使用场景 / Use Case: 会话结束后提醒用户重新开始
  func defaultReminderMessage(forProfile profile: BlockedProfiles?) -> String {
    let baseMessage = "Get back to productivity"
    guard let profile else {
      return baseMessage
    }
    return baseMessage + " by enabling \(profile.name)"
  }

  // MARK: - Public Methods - Session Lifecycle
  // 公开方法 - 会话生命周期 / Public Methods - Session Lifecycle
  
  /// 加载活动会话（从数据库和 SharedData 同步）
  /// Load active session (sync from database and SharedData)
  /// 
  /// - Parameter context: SwiftData ModelContext
  /// 
  /// 🔄 执行流程 / Execution Flow:
  /// 1. 从数据库获取最新的活动会话
  /// 2. 如果会话活动，启动 UI 计时器
  /// 3. 启动 Live Activity（仅前台）
  /// 4. 如果无活动会话，关闭 Live Activity
  /// 
  /// 📍 调用时机 / Called When:
  /// - App 启动时（在 HomeView.onAppear）
  /// - 从后台返回前台时
  /// - 会话状态可能在 Extension 中被修改后
  /// 
  /// ⚠️ 注意 / Note: 
  /// - Live Activity 只能在前台启动
  /// - 需要处理 Extension 在后台修改的会话
  func loadActiveSession(context: ModelContext) {
    // 获取活动会话（内部会先同步 schedule sessions）
    // Get active session (internally syncs schedule sessions first)
    activeSession = getActiveSession(context: context)

    if activeSession?.isActive == true {
      // 会话活动：启动 UI 计时器
      // Session active: start UI timer
      startTimer()

      // 启动 Live Activity（动态岛）
      // Start live activity for existing session if one exists
      // ⚠️ Live activities can only be started when the app is in the foreground
      if let session = activeSession {
        liveActivityManager.startSessionActivity(session: session)
      }
    } else {
      // 无活动会话：关闭 Live Activity
      // No active session: close live activity
      // 处理场景：scheduled session 可能在后台结束
      // Handles case: scheduled session might have ended in background
      liveActivityManager.endSessionActivity()
    }
  }

  /// 切换屏蔽状态（智能开关）
  /// Toggle blocking state (smart switch)
  /// 
  /// - Parameters:
  ///   - context: SwiftData ModelContext
  ///   - activeProfile: 要激活的配置文件（开始时需要，停止时可选）
  /// 
  /// 🎯 智能判断逻辑 / Smart Logic:
  /// - 如果正在屏蔽 -> 调用 stopBlocking()
  /// - 如果未屏蔽 -> 调用 startBlocking()
  /// 
  /// 📍 使用位置 / Used In:
  /// - Dashboard 的主切换按钮
  /// - Profile Card 的快速切换
  /// 
  /// 💡 设计优势 / Design Benefit: UI 只需要一个按钮，逻辑自动判断
  func toggleBlocking(context: ModelContext, activeProfile: BlockedProfiles?) {
    // State Sync 注记：该入口仅路由到 start/stop；副作用更新应统一在网关中处理（见上方“统一入口”）。
    if isBlocking {
      stopBlocking(context: context)
    } else {
      startBlocking(context: context, activeProfile: activeProfile)
    }
  }

  /// 切换休息状态
  /// Toggle break state
  /// 
  /// - Parameter context: SwiftData ModelContext
  /// 
  /// 🔄 执行逻辑 / Execution Logic:
  /// - 如果正在休息 -> 调用 stopBreak()（重新开始屏蔽）
  /// - 如果未休息 -> 调用 startBreak()（暂停屏蔽）
  /// 
  /// ⚠️ 前置条件 / Precondition:
  /// - 必须有活动会话
  /// - 配置文件必须启用休息功能
  /// 
  /// 📍 使用位置 / Used In: SessionView 的休息按钮
  func toggleBreak(context: ModelContext) {
    guard let session = activeSession else {
      print("active session does not exist")
      return
    }

    // State Sync 注记：startBreak()/stopBreak() 完成后统一调用同步网关，确保 Widget/LiveActivity/SharedData 一致。
    if session.isBreakActive {
      stopBreak(context: context)
    } else {
      startBreak(context: context)
    }
  }

  // MARK: - Public Methods - Timer Management
  // 公开方法 - 计时器管理 / Public Methods - Timer Management
  
  /// 启动 UI 计时器（每秒更新一次）
  /// Start UI timer (updates every second)
  /// 
  /// 🔄 更新逻辑 / Update Logic:
  /// - **休息模式**: 显示剩余休息时间（倒计时）
  ///   - 计算方式: 休息时长 - (当前时间 - 休息开始时间)
  ///   - 例：10 分钟休息，已过 3 分钟 -> 显示 7 分钟
  /// 
  /// - **正常会话**: 显示已用时间（正计时）
  ///   - 计算方式: (当前时间 - 会话开始时间) - 总休息时长
  ///   - 例：会话 1 小时，休息了 10 分钟 -> 显示 50 分钟
  /// 
  /// 📊 时间精度 / Time Precision: 秒级更新 / Second-level updates
  /// 
  /// 🎯 UI 绑定 / UI Binding:
  /// @Published elapsedTime -> Text/ProgressView 自动刷新
  /// 
  /// ⚠️ 内存管理 / Memory Management:
  /// - Timer 强引用 self，需在 stopTimer 中 invalidate
  /// - 使用 [weak self] 可能导致计时器提前释放
  func startTimer() {
    // 仅更新本地 UI 计时显示；不负责状态同步到扩展。
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      guard let session = self.activeSession else { return }

      if session.isBreakActive {
        // 休息模式：显示剩余时间（倒计时）
        // Break mode: display remaining time (countdown)
        guard let breakStartTime = session.breakStartTime else { return }
        let timeSinceBreakStart = Date().timeIntervalSince(breakStartTime)
        let breakDurationInSeconds = TimeInterval(session.blockedProfile.breakTimeInMinutes * 60)
        // max(0, ...) 确保不会显示负数
        // max(0, ...) ensures we don't display negative time
        self.elapsedTime = max(0, breakDurationInSeconds - timeSinceBreakStart)
      } else {
        // 正常会话：显示已用时间（正计时）
        // Normal session: display elapsed time (count up)
        let rawElapsedTime = Date().timeIntervalSince(session.startTime)
        let breakDuration = self.calculateBreakDuration()
        // 减去休息时长，得到净工作时间
        // Subtract break duration to get net work time
        self.elapsedTime = rawElapsedTime - breakDuration
      }
    }
  }

  /// 停止 UI 计时器并清理
  /// Stop UI timer and cleanup
  /// 
  /// ⚠️ 重要 / Important: 必须调用以避免内存泄漏
  /// Must be called to avoid memory leaks
  /// 
  /// 📍 调用时机 / Called When:
  /// - 会话结束
  /// - App 进入后台（可选优化）
  /// - 用户注销
  func stopTimer() {
    // 仅释放 UI 计时资源；状态同步由 start/stop/break 等入口负责。
    timer?.invalidate()
    timer = nil
  }

  /// 计算总休息时长
  /// Calculate total break duration
  /// 
  /// - Returns: 休息时长（秒）/ Break duration in seconds
  /// 
  /// 📊 计算逻辑 / Calculation Logic:
  /// - 如果休息已结束: breakEndTime - breakStartTime
  /// - 如果正在休息: 0（由 startTimer 实时计算）
  /// - 如果从未休息: 0
  /// 
  /// 🎯 用途 / Purpose: 计算会话的净工作时间
  /// Used to calculate session's net work time
  private func calculateBreakDuration() -> TimeInterval {
    guard let session = activeSession else {
      return 0
    }

    guard let breakStartTime = session.breakStartTime else {
      return 0
    }

    if let breakEndTime = session.breakEndTime {
      // 休息已结束，返回实际休息时长
      // Break has ended, return actual break duration
      return breakEndTime.timeIntervalSince(breakStartTime)
    }

    // 正在休息或未记录结束时间，返回 0
    // Currently on break or end time not recorded, return 0
    return 0
  }

  func toggleSessionFromDeeplink(
    _ profileId: String,
    url: URL,
    context: ModelContext
  ) {
    // State Sync 注记：完成启动/停止后应走统一同步网关，避免分支遗漏副作用。
    // 深链入口：从 NFC/QR/URL 启动，智能切换会话
    // Deep link entry: launch from NFC/QR/URL, toggle session smartly
    guard let profileUUID = UUID(uuidString: profileId) else {
      self.errorMessage = "failed to parse profile in tag"
      return
    }

    do {
      guard
        let profile: BlockedProfiles = try BlockedProfiles.findProfile(
          byID: profileUUID,
          in: context
        )
      else {
        self.errorMessage =
          "Failed to find a profile stored locally that matches the tag"
        return
      }

      let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)

      if let localActiveSession = getActiveSession(context: context) {
        // 若当前活跃会话禁止后台停止，拒绝切换
        if localActiveSession.blockedProfile.disableBackgroundStops {
          print(
            "profile: \(localActiveSession.blockedProfile.name) has disable background stops enabled, not stopping it"
          )
          self.errorMessage =
            "profile: \(localActiveSession.blockedProfile.name) has disable background stops enabled, not stopping it"
          return
        }

        _ =
          manualStrategy
          .stopBlocking(
            context: context,
            session: localActiveSession
          )

        if localActiveSession.blockedProfile.id != profile.id {
          print(
            "User is switching sessions from deep link"
          )

          _ = manualStrategy.startBlocking(
            context: context,
            profile: profile,
            forceStart: true
          )
        }
      } else {
        _ = manualStrategy.startBlocking(
          context: context,
          profile: profile,
          forceStart: true
        )
      }
    } catch {
      self.errorMessage = "Something went wrong fetching profile"
    }
  }

  func startSessionFromBackground(
    _ profileId: UUID,
    context: ModelContext,
    durationInMinutes: Int? = nil
  ) {
    // 后台触发（Shortcuts / App Intents / Widget）启动会话
    // State Sync 注记：策略启动完成后统一进行快照刷新 + Widget/Live Activity 更新。
    do {
      guard
        let profile = try BlockedProfiles.findProfile(
          byID: profileId,
          in: context
        )
      else {
        self.errorMessage =
          "Failed to find a profile stored locally that matches the tag"
        return
      }

      if let localActiveSession = getActiveSession(context: context) {
        print(
          "session is already active for profile: \(localActiveSession.blockedProfile.name), not starting a new one"
        )
        return
      }

      if let duration = durationInMinutes {
        // 背景定时会话：校验范围并写入 strategyData 供计时策略使用
        if duration < 15 || duration > 1440 {
          self.errorMessage = "Duration must be between 15 and 1440 minutes"
          return
        }

        if let strategyTimerData = StrategyTimerData.toData(
          from: StrategyTimerData(durationInMinutes: duration)
        ) {
          profile.strategyData = strategyTimerData
          profile.updatedAt = Date()
          BlockedProfiles.updateSnapshot(for: profile)
          try context.save()
        }

        let shortcutTimerStrategy = getStrategy(id: ShortcutTimerBlockingStrategy.id)
        _ = shortcutTimerStrategy.startBlocking(
          context: context,
          profile: profile,
          forceStart: true
        )
      } else {
        // 无时长参数则使用手动策略启动
        let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)
        _ = manualStrategy.startBlocking(
          context: context,
          profile: profile,
          forceStart: true
        )
      }
    } catch {
      self.errorMessage = "Something went wrong fetching profile"
    }
  }

  func stopSessionFromBackground(
    _ profileId: UUID,
    context: ModelContext
  ) {
    // 后台触发停止（Shortcuts / App Intents / Widget）
    // State Sync 注记：策略停止完成后统一进行快照刷新 + Widget/Live Activity 更新。
    do {
      guard
        let profile = try BlockedProfiles.findProfile(
          byID: profileId,
          in: context
        )
      else {
        self.errorMessage =
          "Failed to find a profile stored locally that matches the tag"
        return
      }

      let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)

      guard let localActiveSession = getActiveSession(context: context) else {
        print(
          "session is not active for profile: \(profile.name), not stopping it"
        )
        return
      }

      if localActiveSession.blockedProfile.id != profile.id {
        print(
          "session is not active for profile: \(profile.name), not stopping it"
        )
        self.errorMessage =
          "session is not active for profile: \(profile.name), not stopping it"
        return
      }

      if profile.disableBackgroundStops {
        // 配置禁止后台停止，直接返回
        print(
          "profile: \(profile.name) has disable background stops enabled, not stopping it"
        )
        self.errorMessage =
          "profile: \(profile.name) has disable background stops enabled, not stopping it"
        return
      }

      let _ = manualStrategy.stopBlocking(
        context: context,
        session: localActiveSession
      )
    } catch {
      self.errorMessage = "Something went wrong fetching profile"
    }
  }

  func getRemainingEmergencyUnblocks() -> Int {
    return emergencyUnblocksRemaining
  }

  func emergencyUnblock(context: ModelContext) {
    // Do not allow emergency unblocks if there are no remaining
    if emergencyUnblocksRemaining == 0 {
      return
    }

    // Do not allow emergency unblocks if there is no active session
    guard let activeSession = getActiveSession(context: context) else {
      return
    }

    // 紧急解锁：绕过当前策略，使用手动策略强制结束
    // Stop the active session using the manual strategy, by passes any other strategy in view
    let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)
    _ = manualStrategy.stopBlocking(
      // State Sync 注记：完成后应统一调用同步网关，处理快照/Widget/Live Activity 一致性。
      context: context,
      session: activeSession
    )

    // Do end sections for the profile
    self.liveActivityManager.endSessionActivity()
    self.scheduleReminder(profile: activeSession.blockedProfile)
    self.stopTimer()

    // Decrement the remaining emergency unblocks
    emergencyUnblocksRemaining -= 1

    // Refresh widgets when emergency unblock ends session
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
  }

  func resetEmergencyUnblocks() {
    emergencyUnblocksRemaining = 3
    lastEmergencyUnblocksResetDateTimestamp = Date().timeIntervalSinceReferenceDate
  }

  func checkAndResetEmergencyUnblocks() {
    // Initialize the last reset date if it hasn't been set
    if lastEmergencyUnblocksResetDateTimestamp == 0 {
      lastEmergencyUnblocksResetDateTimestamp = Date().timeIntervalSinceReferenceDate
      return
    }

    let lastResetDate = Date(
      timeIntervalSinceReferenceDate: lastEmergencyUnblocksResetDateTimestamp)
    let weeksInSeconds: TimeInterval = TimeInterval(
      emergencyUnblocksResetPeriodInWeeks * 7 * 24 * 60 * 60)
    let elapsedTime = Date().timeIntervalSince(lastResetDate)

    // Check if the reset period has elapsed
    if elapsedTime >= weeksInSeconds {
      emergencyUnblocksRemaining = 3
      lastEmergencyUnblocksResetDateTimestamp = Date().timeIntervalSinceReferenceDate
    }
  }

  func getNextResetDate() -> Date? {
    guard lastEmergencyUnblocksResetDateTimestamp > 0 else {
      return nil
    }

    let lastResetDate = Date(
      timeIntervalSinceReferenceDate: lastEmergencyUnblocksResetDateTimestamp)
    let calendar = Calendar.current
    return calendar.date(
      byAdding: .weekOfYear,
      value: emergencyUnblocksResetPeriodInWeeks,
      to: lastResetDate
    )
  }

  func getResetPeriodInWeeks() -> Int {
    return emergencyUnblocksResetPeriodInWeeks
  }

  func setResetPeriodInWeeks(_ weeks: Int) {
    emergencyUnblocksResetPeriodInWeeks = weeks
    lastEmergencyUnblocksResetDateTimestamp = Date().timeIntervalSinceReferenceDate
  }

  static func getStrategyFromId(id: String) -> BlockingStrategy {
    if let strategy = availableStrategies.first(
      where: {
        $0.getIdentifier() == id
      })
    {
      return strategy
    } else {
      return NFCBlockingStrategy()
    }
  }

  func getStrategy(id: String) -> BlockingStrategy {
    // 策略工厂：根据 id 取策略，并注入 UI/状态同步回调
    var strategy = StrategyManager.getStrategyFromId(id: id)

    strategy.onSessionCreation = { session in
      self.dismissView()

      // Remove any timers and notifications that were scheduled
      self.timersUtil.cancelAll()

      switch session {
      case .started(let session):
        // Update the snapshot of the profile in case some settings were changed
        BlockedProfiles.updateSnapshot(for: session.blockedProfile)

        self.errorMessage = nil

        self.activeSession = session
        self.startTimer()
        self.liveActivityManager
          .startSessionActivity(session: session)

        // Refresh widgets when session starts
        WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
      case .ended(let endedProfile):
        self.activeSession = nil
        self.liveActivityManager.endSessionActivity()
        self.scheduleReminder(profile: endedProfile)

        self.stopTimer()
        self.elapsedTime = 0

        // Refresh widgets when session ends
        WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")

        // Remove all break timer activities
        DeviceActivityCenterUtil.removeAllBreakTimerActivities()

        // Remove all strategy timer activities
        DeviceActivityCenterUtil.removeAllStrategyTimerActivities()
      }
    }

    strategy.onErrorMessage = { message in
      self.dismissView()

      self.errorMessage = message
    }

    return strategy
  }

  private func startBreak(context: ModelContext) {
    guard let session = activeSession else {
      print("Breaks only available in active session")
      return
    }

    if !session.isBreakAvailable {
      print("Breaks is not availble")
      return
    }

    // Start the break timer activity
    DeviceActivityCenterUtil.startBreakTimerActivity(for: session.blockedProfile)

    // Schedule a reminder to get back to the profile after the break
    scheduleBreakReminder(profile: session.blockedProfile)

    // Refresh widgets when break starts
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")

    // Load the active session since the break start time was set in a different thread
    // 同步 SwiftData 与 DeviceActivity 设置的 break 时间
    loadActiveSession(context: context)

    // Update live activity to show break state
    liveActivityManager.updateBreakState(session: session)
  }

  private func stopBreak(context: ModelContext) {
    guard let session = activeSession else {
      print("Breaks only available in active session")
      return
    }

    if !session.isBreakAvailable {
      print("Breaks is not availble")
      return
    }

    // Remove the break timer activity
    DeviceActivityCenterUtil.removeBreakTimerActivity(for: session.blockedProfile)

    // Cancel all notifications that were scheduled during break
    timersUtil.cancelAllNotifications()

    // Refresh widgets when break ends
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")

    // Load the active session since the break end time was set in a different thread
    // 同步 SwiftData 与 DeviceActivity 设置的 break 结束时间
    loadActiveSession(context: context)

    // Update live activity to show break has ended
    liveActivityManager.updateBreakState(session: session)
  }

  private func dismissView() {
    showCustomStrategyView = false
    customStrategyView = nil
  }

  private func getActiveSession(context: ModelContext)
    -> BlockedProfileSession?
  {
    // 获取前先同步调度会话（来自 Extension 的快照）
    syncScheduleSessions(context: context)

    return
      BlockedProfileSession
      .mostRecentActiveSession(in: context)
  }

  private func syncScheduleSessions(context: ModelContext) {
    // 同步 Extension 写入的 Schedule 会话快照（活跃 + 已完成）
    if let activeScheduledSession = SharedData.getActiveSharedSession() {
      BlockedProfileSession.upsertSessionFromSnapshot(
        in: context,
        withSnapshot: activeScheduledSession
      )
    }

    // Process any completed scheduled sessions
    let completedScheduleSessions = SharedData.getCompletedSessionsForSchedular()
    for completedScheduleSession in completedScheduleSessions {
      BlockedProfileSession.upsertSessionFromSnapshot(
        in: context,
        withSnapshot: completedScheduleSession
      )
    }

    // Flush completed scheduled sessions
    SharedData.flushCompletedSessionsForSchedular()
  }

  private func resultFromURL(_ url: String) -> NFCResult {
    return NFCResult(id: url, url: url, DateScanned: Date())
  }

  private func startBlocking(
    context: ModelContext,
    activeProfile: BlockedProfiles?
  ) {
    guard let definedProfile = activeProfile else {
      print(
        "No active profile found, calling stop blocking with no session"
      )
      return
    }

    // 根据 profile 的 blockingStrategyId 取策略并启动；如策略返回自定义 UI 则显示
    if let strategyId = definedProfile.blockingStrategyId {
      let strategy = getStrategy(id: strategyId)
      let view = strategy.startBlocking(
        context: context,
        profile: definedProfile,
        forceStart: false
      )

      if let customView = view {
        showCustomStrategyView = true
        customStrategyView = customView
      }

      // State Sync 提示：当策略完成启动（包括可能的自定义视图交互后）
      // 应通过统一网关触发快照刷新与 Widget/Live Activity 更新。
    }
  }

  private func stopBlocking(context: ModelContext) {
    guard let session = activeSession else {
      print(
        "No active session found, calling stop blocking with no session"
      )
      return
    }

    // 使用会话上的策略停止；可能弹出自定义 UI（如 NFC/QR 再验证）
    if let strategyId = session.blockedProfile.blockingStrategyId {
      let strategy = getStrategy(id: strategyId)
      let view = strategy.stopBlocking(context: context, session: session)

      if let customView = view {
        showCustomStrategyView = true
        customStrategyView = customView
      }

      // State Sync 提示：当策略完成停止（包括可能的自定义视图交互后）
      // 应通过统一网关触发快照刷新与 Widget/Live Activity 更新。
    }
  }

  private func scheduleReminder(profile: BlockedProfiles) {
    guard let reminderTimeInSeconds = profile.reminderTimeInSeconds else {
      return
    }

    let profileName = profile.name
    let message = profile.customReminderMessage ?? defaultReminderMessage(forProfile: profile)
    timersUtil
      .scheduleNotification(
        title: profileName + " time!",
        message: message,
        seconds: TimeInterval(reminderTimeInSeconds)
      )
  }

  private func scheduleBreakReminder(profile: BlockedProfiles) {
    let profileName = profile.name

    // 提前 1 分钟提醒休息即将结束
    let breakNotificationTimeInSeconds = UInt32((profile.breakTimeInMinutes - 1) * 60)
    if breakNotificationTimeInSeconds > 0 {
      timersUtil.scheduleNotification(
        title: "Break almost over!",
        message: "Hope you enjoyed your break, starting " + profileName + " in a 1 minute.",
        seconds: TimeInterval(breakNotificationTimeInSeconds)
      )
    }
  }

  func cleanUpGhostSchedules(context: ModelContext) {
    let allActivities = DeviceActivityCenterUtil.getDeviceActivities()
    let scheduleTimerActivity = ScheduleTimerActivity()
    let scheduleActivities = scheduleTimerActivity.getAllScheduleTimerActivities(
      from: allActivities)

    print(
      "Found \(scheduleActivities.count) schedule timer activities out of \(allActivities.count) total activities"
    )

    for activity in scheduleActivities {
      let rawValue = activity.rawValue
      guard let profileId = UUID(uuidString: rawValue) else {
        // This shouldn't happen since we filtered above, but print just in case
        print("Unexpected: failed to parse profile id from filtered activity: \(rawValue)")
        continue
      }

      do {
        if let profile = try BlockedProfiles.findProfile(byID: profileId, in: context) {
          if profile.schedule == nil {
            print(
              "Profile '\(profile.name)' has no schedule but has device activity registered. Removing ghost schedule..."
            )
            // 清理不存在 schedule 的残留 DeviceActivity
            DeviceActivityCenterUtil.removeScheduleTimerActivities(for: profile)
          } else {
            print("Profile '\(profile.name)' has schedule - activity is valid ✅")
          }
        } else {
          // Profile truly doesn't exist in database
          print("No profile found for activity \(rawValue). Removing orphaned schedule...")
          // 清理孤儿 DeviceActivity
          DeviceActivityCenterUtil.removeScheduleTimerActivities(for: activity)
        }
      } catch {
        // Database error occurred - do NOT delete the schedule since we don't know the true state
        print(
          "Error fetching profile \(rawValue): \(error.localizedDescription). Skipping cleanup for safety."
        )
      }
    }
  }
}
