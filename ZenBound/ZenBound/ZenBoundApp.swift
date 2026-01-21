//
//  ZenBoundApp.swift
//  ZenBound
//
//  屏幕时间管理应用 - 宠物猫养成 + 番茄钟 + 任务系统
//

import BackgroundTasks
import SwiftData
import SwiftUI

// MARK: - Model Container
private let container: ModelContainer = {
    do {
        return try ModelContainer(
            for: BlockedProfileSession.self,
            BlockedProfiles.self
        )
    } catch {
        fatalError("Couldn't create ModelContainer: \(error)")
    }
}()

@main
struct ZenBoundApp: App {
  @StateObject private var requestAuthorizer = RequestAuthorizer()
  @StateObject private var startegyManager = StrategyManager.shared
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
  }
    var body: some Scene {
        WindowGroup {
            // todo
            .environmentObject(requestAuthorizer)      // 权限管理 / Authorization
            .environmentObject(startegyManager)        // 策略管理 / Strategy (核心)
        }
        .modelContainer(container)
    }
    
}
