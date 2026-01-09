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

class StrategyManager: ObservableObject {
  static var shared = StrategyManager()

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

  @Published var elapsedTime: TimeInterval = 0
  @Published var timer: Timer?
  @Published var activeSession: BlockedProfileSession?

  @Published var showCustomStrategyView: Bool = false
  @Published var customStrategyView: (any View)? = nil

  @Published var errorMessage: String?

  @AppStorage("emergencyUnblocksRemaining") private var emergencyUnblocksRemaining: Int = 3
  @AppStorage("emergencyUnblocksResetPeriodInWeeks") private
    var emergencyUnblocksResetPeriodInWeeks: Int = 4
  @AppStorage("lastEmergencyUnblocksResetDate") private var lastEmergencyUnblocksResetDateTimestamp:
    Double = 0

  private let liveActivityManager = LiveActivityManager.shared

  private let timersUtil = TimersUtil()
  private let appBlocker = AppBlockerUtil()

  var isBlocking: Bool {
    return activeSession?.isActive == true
  }

  var isBreakActive: Bool {
    return activeSession?.isBreakActive == true
  }

  var isBreakAvailable: Bool {
    return activeSession?.isBreakAvailable ?? false
  }

  func defaultReminderMessage(forProfile profile: BlockedProfiles?) -> String {
    let baseMessage = "Get back to productivity"
    guard let profile else {
      return baseMessage
    }
    return baseMessage + " by enabling \(profile.name)"
  }

  func loadActiveSession(context: ModelContext) {
    activeSession = getActiveSession(context: context)

    if activeSession?.isActive == true {
      startTimer()

      // Start live activity for existing session if one exists
      // live activities can only be started when the app is in the foreground
      if let session = activeSession {
        liveActivityManager.startSessionActivity(session: session)
      }
    } else {
      // Close live activity if no session is active and a scheduled session might have ended
      liveActivityManager.endSessionActivity()
    }
  }

  func toggleBlocking(context: ModelContext, activeProfile: BlockedProfiles?) {
    if isBlocking {
      stopBlocking(context: context)
    } else {
      startBlocking(context: context, activeProfile: activeProfile)
    }
  }

  func toggleBreak(context: ModelContext) {
    guard let session = activeSession else {
      print("active session does not exist")
      return
    }

    if session.isBreakActive {
      stopBreak(context: context)
    } else {
      startBreak(context: context)
    }
  }

  func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      guard let session = self.activeSession else { return }

      if session.isBreakActive {
        // Calculate break time remaining (countdown)
        guard let breakStartTime = session.breakStartTime else { return }
        let timeSinceBreakStart = Date().timeIntervalSince(breakStartTime)
        let breakDurationInSeconds = TimeInterval(session.blockedProfile.breakTimeInMinutes * 60)
        self.elapsedTime = max(0, breakDurationInSeconds - timeSinceBreakStart)
      } else {
        // Calculate session elapsed time
        let rawElapsedTime = Date().timeIntervalSince(session.startTime)
        let breakDuration = self.calculateBreakDuration()
        self.elapsedTime = rawElapsedTime - breakDuration
      }
    }
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func calculateBreakDuration() -> TimeInterval {
    guard let session = activeSession else {
      return 0
    }

    guard let breakStartTime = session.breakStartTime else {
      return 0
    }

    if let breakEndTime = session.breakEndTime {
      return breakEndTime.timeIntervalSince(breakStartTime)
    }

    return 0
  }

  func toggleSessionFromDeeplink(
    _ profileId: String,
    url: URL,
    context: ModelContext
  ) {
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

    // Stop the active session using the manual strategy, by passes any other strategy in view
    let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)
    _ = manualStrategy.stopBlocking(
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
    // Before fetching the active session, sync any schedule sessions
    syncScheduleSessions(context: context)

    return
      BlockedProfileSession
      .mostRecentActiveSession(in: context)
  }

  private func syncScheduleSessions(context: ModelContext) {
    // Process any active scheduled sessions
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
    }
  }

  private func stopBlocking(context: ModelContext) {
    guard let session = activeSession else {
      print(
        "No active session found, calling stop blocking with no session"
      )
      return
    }

    if let strategyId = session.blockedProfile.blockingStrategyId {
      let strategy = getStrategy(id: strategyId)
      let view = strategy.stopBlocking(context: context, session: session)

      if let customView = view {
        showCustomStrategyView = true
        customStrategyView = customView
      }
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

    // Schedule a reminder to let the user know that the break is about to end
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
            DeviceActivityCenterUtil.removeScheduleTimerActivities(for: profile)
          } else {
            print("Profile '\(profile.name)' has schedule - activity is valid ✅")
          }
        } else {
          // Profile truly doesn't exist in database
          print("No profile found for activity \(rawValue). Removing orphaned schedule...")
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
