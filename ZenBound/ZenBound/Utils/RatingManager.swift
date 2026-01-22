import Combine
import StoreKit
import SwiftUI

/**
 `RatingManager`
 
 位置：StoreKit 评价请求管理工具类（通常位于 Utils/Services 一类目录），由 SwiftUI 通过 `@EnvironmentObject` 注入。
 
 ---
 ## 1) 代码作用与输入输出示例
 
 这个类管理 App Store 应用商店评分请求的触发时机与发送逻辑：
 
 - 输入：App 启动次数（通过 `@AppStorage("launchCount")` 记录）、当前应用版本号
 - 输出：在满足条件时发起 `SKStoreReviewController.requestReview()` 调用，弹起系统原生评分对话框
 
 核心行为：
 - 当启动次数达到 3 次 **且** 从未为当前版本弹过评分请求时，自动触发评分对话框
 - `shouldRequestReview` 标记发生状态变化后，UI 可响应式更新（虽然当前项目没有绑定此状态到 UI）
 
 典型流程：
 ```
 用户启动 App 1 次 → 不弹窗
 启动 2 次 → 不弹窗
 启动 3 次 → 检查"是否为当前版本首次"且"启动次数 >= 3" → 满足条件 → 弹窗请求评分
 升级新版本后，计数器重置，下一轮会在启动 3 次后再次弹窗
 ```
 
 ---
 ## 2) 项目内搜索：引用点与相关流程
 
 项目内发现的用法点：
 
 - **初始化与注入**：在 foqosApp.swift 中通过 `@StateObject private var ratingManager = RatingManager()` 创建单例，并通过 `.environmentObject(ratingManager)` 注入到 HomeView
 - **调用点**：在 HomeView.swift 的 `strategyButtonPress(_:)` 中，当用户按下"启动/停止屏蔽会话"按钮时，调用 `ratingManager.incrementLaunchCount()` 来增加启动计数
 - **相关 UI 流程**：属于"仪表盘/主屏"的一部分，用户每次点击"开始屏蔽"或其他策略按钮时都会触发计数增长
 
 ---
 ## 3) 项目内用法总结与相关代码示例
 
 ### 用法 A：在主屏"策略启动/停止"按钮的回调中增长启动计数
 
 **目的**：追踪用户在应用内的"活跃交互次数"，积累到阈值后自动请求评分。
 
 **关联 UI**：主屏幕的"启动屏蔽会话"按钮（例如 Manual/NFC/QR/Timer 策略的启动按钮）。
 
 **代码示例**（简化版）：
 ```swift
 struct <RootView>: View {
   @EnvironmentObject var ratingManager: RatingManager
   
   var body: some View {
     Button("Start Blocking") {
       // 执行屏蔽会话逻辑
       strategyManager.toggleBlocking(...)
       
       // 增长启动计数（可能触发评分对话框）
       ratingManager.incrementLaunchCount()
     }
   }
 }
 ```
 
 ### 用法 B：版本变更后自动重置评分请求
 
 **目的**：每个新版本发布后，用户可被再次请求评分，避免老版本的评分疲劳。
 
 **实现细节**：内部通过 `@AppStorage("lastVersionPromptedForReview")` 记录上次被提示的版本号，对比 `CFBundleShortVersionString` 决定是否允许再次弹窗。
 
 **代码示例**（内部逻辑）：
 ```swift
 private func checkIfShouldRequestReview() {
   let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
   
   // 只在"版本不同"且"启动次数 >= 阈值"时触发
   guard lastVersionPromptedForReview != currentVersion, launchCount >= 3 else {
     return
   }
   
   // 记录已为该版本提示过
   lastVersionPromptedForReview = currentVersion
   
   // 向系统请求弹窗
   requestReview()
 }
 ```
 
 ---
 ## 4) GitHub 公开仓库常见用法（代码示例基于实际项目模式总结）
 
 在 GitHub 上常见的评分管理包括：
 
 1. **简单版本**（仅追踪启动数）：在每次 app 启动时 `+1`，达到阈值直接请求
 2. **版本感知版本**（本项目采用）：每个版本允许一次请求
 3. **条件化触发**：根据特定用户行为（如购买、完成任务）而非单纯启动次数触发
 4. **带延迟的触发**：在用户执行"核心操作"后延迟 N 秒再触发（优化用户体验）
 5. **可配置阈值**：允许从远程配置 (Firebase/JSON) 更新触发条件
 
 ---
 ## 5) GitHub 常见用法示例（通用模式重新组织）
 
 ### 常见模式 1：启动时自动请求评分（最简形式）
 
 ```swift
 class SimpleRatingManager: ObservableObject {
   @AppStorage("launchCount") var launchCount = 0
   
   func trackLaunch() {
     launchCount += 1
     if launchCount == 3 {
       requestReview()
     }
   }
   
   private func requestReview() {
     guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
       return
     }
     SKStoreReviewController.requestReview(in: scene)
   }
 }
 ```
 
 ### 常见模式 2：条件化触发（带额外检查）
 
 ```swift
 class ConditionalRatingManager: ObservableObject {
   @AppStorage("launchCount") var launchCount = 0
   @AppStorage("lastReviewVersion") var lastReviewVersion: String?
   
   func checkAndPromptReview() {
     let currentVersion = Bundle.main.releaseVersionNumber
     
     // 仅在新版本且启动次数足够时弹窗
     if lastReviewVersion != currentVersion && launchCount >= 5 {
       requestReview()
       lastReviewVersion = currentVersion
     }
   }
 }
 ```
 
 ### 常见模式 3：基于特定用户行为触发（而非启动次数）
 
 ```swift
 class ActionBasedRatingManager: ObservableObject {
   @AppStorage("completedActionsCount") var completedActions = 0
   
   func recordAction() {
     completedActions += 1
     
     // 在用户完成 10 个操作后请求评分
     if completedActions % 10 == 0 {
       requestReview()
     }
   }
 }
 ```
 
 ### 常见模式 4：带防抖与延迟的评分请求
 
 ```swift
 class ThrottledRatingManager: ObservableObject {
   @AppStorage("lastReviewDate") var lastReviewDate: Date?
   
   func requestReviewWithDelay() {
     // 防止频繁弹窗（例如同一用户 7 天内最多一次）
     let calendar = Calendar.current
     if let lastDate = lastReviewDate, 
        calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0 < 7 {
       return
     }
     
     // 延迟弹窗，优化用户体验
     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
       self.requestReview()
       self.lastReviewDate = Date()
     }
   }
 }
 ```
 
 ---
 ## 注意事项
 
 - **@AppStorage 存储位置**：数据存储在应用的默认 UserDefaults 中，与应用卸载一起清除（不跨设备同步）
 - **`@Published shouldRequestReview`**：当前项目定义但未被 UI 绑定使用，可考虑在 Sheet/Alert 中观察此属性以更灵活控制弹窗时机
 - **UIWindowScene 前置条件**：调用 `SKStoreReviewController.requestReview(in:)` 需获取有效的前台场景，否则请求会被忽略
 - **iOS 版本兼容**：StoreKit 评价 API 自 iOS 10.3+ 可用，项目无需额外版本检查
 - **系统限制**：App Store 对评分弹窗频率有限制，同一用户在短期内看到多次弹窗会被降权，设计评分策略时需谨慎
 */
class RatingManager: ObservableObject {
  @AppStorage("launchCount") private var launchCount = 0
  @AppStorage("lastVersionPromptedForReview") private var lastVersionPromptedForReview: String?
  @Published var shouldRequestReview = false

  func incrementLaunchCount() {
    launchCount += 1
    checkIfShouldRequestReview()
  }

  private func checkIfShouldRequestReview() {
    let currentVersion =
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    // Only prompt if we haven't for this version and have enough launches
    guard lastVersionPromptedForReview != currentVersion,
      launchCount >= 3
    else { return }

    shouldRequestReview = true
    lastVersionPromptedForReview = currentVersion
    requestReview()
  }

  private func requestReview() {
    guard
      let scene = UIApplication.shared.connectedScenes.first(
        where: { $0.activationState == .foregroundActive }
      ) as? UIWindowScene
    else {
      return
    }

    SKStoreReviewController.requestReview(in: scene)
  }
}
