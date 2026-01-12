//
//  foqosApp.swift
//  foqos
//
//  Created by Ali Waseem on 2024-10-06.
//

import AppIntents
import BackgroundTasks
import SwiftData
import SwiftUI

private let container: ModelContainer = {
  do {
    return try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self
    )
  } catch {
    fatalError("Couldn’t create ModelContainer: \(error)")
  }
}()

// MARK: - Main App Structure
// 主应用结构 / Main App Structure
@main
struct foqosApp: App {
  
  // MARK: - Environment Objects (Per-Instance)
  // 每个实例独立的环境对象 / Per-Instance Environment Objects
  // 这些对象在每次应用启动时创建新实例
  // These objects create new instances on each app launch
  
  /// 权限授权管理器 / Authorization Manager
  /// 负责处理 FamilyControls 权限请求和状态管理
  /// Handles FamilyControls permission requests and state management
  @StateObject private var requestAuthorizer = RequestAuthorizer()
  
  /// 打赏/内购管理器 / Tip/IAP Manager
  /// 处理应用内购买和打赏功能
  /// Manages in-app purchases and tips
  @StateObject private var donationManager = TipManager()
  
  /// 导航管理器 / Navigation Manager
  /// 处理 Universal Links 和应用内导航
  /// Handles Universal Links and in-app navigation
  @StateObject private var navigationManager = NavigationManager()
  
  /// NFC 写入工具 / NFC Writer Utility
  /// 处理 NFC 标签写入操作（用于创建物理解锁标签）
  /// Handles NFC tag writing operations (for creating physical unlock tags)
  @StateObject private var nfcWriter = NFCWriter()
  
  /// 评分管理器 / Rating Manager
  /// 管理应用评分请求时机和状态
  /// Manages app rating request timing and state
  @StateObject private var ratingManager = RatingManager()

  // MARK: - Global Singletons
  // 全局单例对象 / Global Singleton Objects
  // 这些对象在整个应用生命周期中保持唯一实例
  // These objects maintain a single instance throughout the app lifecycle
  // 
  // ⚠️ 注意 / Note: 使用 @StateObject 包装 Singleton 是为了让 SwiftUI 监听其变化
  // Using @StateObject wrapper allows SwiftUI to observe their changes
  
  /// 策略管理器 (Singleton) / Strategy Manager (Singleton)
  /// 核心业务逻辑：管理所有屏蔽会话和策略
  /// Core business logic: Manages all blocking sessions and strategies
  /// ⚠️ 963 行，需要重构 / 963 lines, needs refactoring
  @StateObject private var startegyManager = StrategyManager.shared
  
  /// Live Activity 管理器 (Singleton) / Live Activity Manager (Singleton)
  /// 管理动态岛显示和更新
  /// Manages Dynamic Island display and updates
  @StateObject private var liveActivityManager = LiveActivityManager.shared
  
  /// 主题管理器 (Singleton) / Theme Manager (Singleton)
  /// 管理应用主题和外观设置
  /// Manages app theme and appearance settings
  @StateObject private var themeManager = ThemeManager.shared

  // MARK: - Initialization
  // 应用初始化 / App Initialization
  /// 在应用启动时执行的初始化逻辑
  /// Initialization logic executed at app launch
  ///
  /// 📋 初始化顺序 / Initialization Order:
  /// 1. 注册后台任务（用于计时器通知）
  /// 2. 注册 ModelContainer 到全局依赖管理器（供 App Intents 使用）
  ///
  /// 🔍 为什么需要 AppDependencyManager? / Why AppDependencyManager?
  /// - App Intents 运行在独立进程中，无法直接访问 App 的 @StateObject
  /// - 通过全局依赖管理器，App Intents 可以获取到相同的 ModelContainer
  /// - 保证数据层的一致性
  /// 
  /// App Intents run in separate processes and can't directly access App's @StateObject
  /// Through global dependency manager, App Intents can access the same ModelContainer
  /// Ensures data layer consistency
  init() {
    // 注册后台任务标识符，用于计时器结束后的通知
    // Register background task identifiers for timer completion notifications
    // 📍 相关配置：Info.plist -> BGTaskSchedulerPermittedIdentifiers
    TimersUtil.registerBackgroundTasks()

    // 创建异步依赖闭包，返回 ModelContainer
    // Create async dependency closure that returns ModelContainer
    // @Sendable: 闭包可以在并发上下文中安全传递
    // @MainActor: 确保 container 访问在主线程
    let asyncDependency: @Sendable () async -> (ModelContainer) = {
      @MainActor in
      return container
    }
    
    // 将 ModelContainer 注册到全局依赖管理器
    // Register ModelContainer to global dependency manager
    // 🔑 Key: "ModelContainer" - App Intents 通过此 key 获取容器
    // Key: "ModelContainer" - App Intents retrieve container via this key
    AppDependencyManager.shared.add(
      key: "ModelContainer",
      dependency: asyncDependency
    )
  }

  // MARK: - Scene Configuration
  // 场景配置 / Scene Configuration
  var body: some Scene {
    WindowGroup {
      // 根视图：HomeView 作为应用的入口界面
      // Root View: HomeView serves as the app's entry interface
      HomeView()
        // 处理 URL Scheme 和 Universal Links
        // Handle URL Schemes and Universal Links
        // 📍 触发场景：从其他 App 或网页跳转到本 App
        // Trigger: When jumping to this app from other apps or web
        .onOpenURL { url in
          handleUniversalLink(url)
        }
        // 处理 Web 浏览活动延续（Handoff）
        // Handle web browsing activity continuation (Handoff)
        // 📍 触发场景：从 Safari 或其他设备跳转过来
        // Trigger: When jumping from Safari or other devices
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
          userActivity in
          guard let url = userActivity.webpageURL else {
            return
          }
          handleUniversalLink(url)
        }
        // MARK: - Environment Object Injection
        // 环境对象注入 / Environment Object Injection
        // 将所有管理器注入到 SwiftUI 环境中，供子视图使用
        // Inject all managers into SwiftUI environment for child views
        // 
        // 📌 使用方式 / Usage in Child Views:
        // @EnvironmentObject var strategyManager: StrategyManager
        .environmentObject(requestAuthorizer)      // 权限管理 / Authorization
        .environmentObject(donationManager)        // 打赏管理 / Donations
        .environmentObject(startegyManager)        // 策略管理 / Strategy (核心)
        .environmentObject(navigationManager)      // 导航管理 / Navigation
        .environmentObject(nfcWriter)              // NFC 写入 / NFC Writing
        .environmentObject(ratingManager)          // 评分管理 / Rating
        .environmentObject(liveActivityManager)    // Live Activity / Dynamic Island
        .environmentObject(themeManager)           // 主题管理 / Theme
    }
    // 将 SwiftData 容器附加到场景
    // Attach SwiftData container to the scene
    // 这使得所有视图都可以通过 @Environment(\.modelContext) 访问数据库
    // This allows all views to access database via @Environment(\.modelContext)
    .modelContainer(container)
  }

  // MARK: - Universal Link Handling
  // Universal Link 处理 / Universal Link Handling
  /// 处理通用链接（Universal Links）
  /// Handle Universal Links
  ///
  /// - Parameter url: 传入的 URL（可能是 foqos:// scheme 或 https://foqos.app 域名）
  /// - Parameter url: Incoming URL (could be foqos:// scheme or https://foqos.app domain)
  ///
  /// 📍 使用场景 / Use Cases:
  /// - 从网页启动应用并导航到特定功能
  /// - 从其他应用深度链接到本应用
  /// - Shortcuts/自动化触发特定操作
  ///
  /// 🔄 处理流程 / Processing Flow:
  /// URL -> handleUniversalLink() -> NavigationManager.handleLink() -> 具体导航逻辑
  /// URL -> handleUniversalLink() -> NavigationManager.handleLink() -> Specific navigation logic
  private func handleUniversalLink(_ url: URL) {
    navigationManager.handleLink(url)
  }
}
