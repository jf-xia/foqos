import Combine
import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

/**
 `RequestAuthorizer`

 位置（通用描述）：iOS App 的“屏幕使用时间 / Family Controls 授权封装”工具类（通常位于 Utils/Services 一类目录），由 SwiftUI 通过 `@EnvironmentObject` 注入到各个页面。

 ---
 ## 1) 这段代码的作用
 这个类把 Apple Screen Time 相关能力的**授权请求**封装成一个可被 SwiftUI 观察的对象：

 - `requestAuthorization()`：异步向系统发起 FamilyControls 授权请求（当前 scope 为 `.individual`），并把结果同步到 `@Published isAuthorized`。
 - `getAuthorizationStatus()`：同步读取系统侧的 `AuthorizationCenter.shared.authorizationStatus`（这是“真实状态源”，例如 `.approved/.denied/...`）。

 典型用途：
 - 在用户第一次使用“应用屏蔽/专注模式”等功能前，提示并触发授权。
 - 在 UI 上展示当前是否已授权，并在授权成功后驱动引导页关闭/功能解锁。

 关键点：
 - 通过 `Task {}` 执行异步 API，并用 `await MainActor.run {}` 更新 `@Published`，避免跨线程更新 UI 状态。
 - 本类不持久化授权结果；`isAuthorized` 是“本项目侧信号”，而 `authorizationStatus` 才是系统侧最终状态。

 ---
 ## 2) 项目内的使用方式与相关功能/UI
 在本项目中，它主要与以下 UI/流程协作：

 - **全局注入**：在 iOS 入口（`@main App`）里创建单例式实例，并注入到根视图树。
 - **主页授权提示**：主页上方有一个“需要授权”的 Callout/提示条，未授权时出现，点击后触发 `requestAuthorization()`。
 - **引导页（Intro）**：引导页结束或最后一步会触发授权；并且主页会监听 `isAuthorized` 来决定是否继续展示引导页。
 - **设置页状态展示**：设置页里用红/绿点和文字展示当前授权状态。

 ---
 ## 3) 项目内每一种用法总结 + 相关代码示例
 注意：下面的“位置”均为通用化描述（不写具体路径），代码片段为“从项目真实用法抽象出来的最小示例”。

 ### 用法 A：在 iOS 入口创建并注入为 EnvironmentObject
 目的：保证全 App 使用同一个授权状态与授权请求入口。

 ```swift
 @main
 struct AppEntry: App {
   @StateObject private var requestAuthorizer = RequestAuthorizer()

   var body: some Scene {
     WindowGroup {
       RootView()
         .environmentObject(requestAuthorizer)
     }
   }
 }
 ```

 ### 用法 B：主页展示“未授权提示条”，点击触发授权
 相关 UI：一个 Callout/卡片式提示组件；当 `authorizationStatus != .approved` 时展示。

 ```swift
 struct HomeScreen: View {
   @EnvironmentObject var requestAuthorizer: RequestAuthorizer

   var body: some View {
     AuthorizationCallout(
       authorizationStatus: requestAuthorizer.getAuthorizationStatus(),
       onAuthorizationHandler: {
         requestAuthorizer.requestAuthorization()
       }
     )
   }
 }
 ```

 ### 用法 C：主页监听 `isAuthorized`，驱动“引导页/权限页”展示与关闭
 相关功能：用 `@AppStorage` 保存“是否显示引导页”，授权成功后自动关闭。

 ```swift
 struct HomeScreen: View {
   @EnvironmentObject var requestAuthorizer: RequestAuthorizer
   @AppStorage("showIntroScreen") private var showIntroScreen = true

   var body: some View {
     Content()
       .onChange(of: requestAuthorizer.isAuthorized) { _, newValue in
         showIntroScreen = !newValue
       }
       .fullScreenCover(isPresented: $showIntroScreen) {
         IntroView {
           requestAuthorizer.requestAuthorization()
         }
       }
   }
 }
 ```

 ### 用法 D：在设置页展示授权状态（红/绿点 + 文案）
 相关 UI：设置页“About/权限”一行的状态指示。

 ```swift
 struct SettingsScreen: View {
   @EnvironmentObject var requestAuthorizer: RequestAuthorizer

   var body: some View {
     HStack {
       Text("Screen Time Access")
       Spacer()
       Circle()
         .fill(requestAuthorizer.getAuthorizationStatus() == .approved ? .green : .red)
         .frame(width: 8, height: 8)
       Text(requestAuthorizer.getAuthorizationStatus() == .approved ? "Authorized" : "Not Authorized")
     }
   }
 }
 ```

 ### 用法 E：在引导页容器的“最后一步”回调里触发授权
 相关 UI：引导页 Stepper 最后一步点击后调用 `onRequestAuthorization()`。

 ```swift
 struct IntroFlowContainer: View {
   @EnvironmentObject var requestAuthorizer: RequestAuthorizer

   var body: some View {
     AnimatedIntroContainer(
       onRequestAuthorization: {
         requestAuthorizer.requestAuthorization()
       }
     )
   }
 }
 ```

 ---
 ## 4) GitHub / 公开项目里常见的其它用法与相关功能
 说明：这里总结的是公开仓库中常见模式（例如把授权请求放在 App/RootView 的 `onAppear` 或做成一个权限管理器），示例为“通用写法”，避免逐字复制第三方代码。

 ### 常见用法 1：在 App 启动/根视图首次出现时自动请求授权
 场景：不等用户点击按钮，首次启动就弹系统授权；常用于 Demo 或强依赖权限的 App。

 ```swift
 @main
 struct AppEntry: App {
   var body: some Scene {
     WindowGroup {
       RootView()
         .task {
           // 首次进入即尝试请求
           try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
         }
     }
   }
 }
 ```

 ### 常见用法 2：请求前先判断 `authorizationStatus`，避免重复弹窗/无意义请求
 场景：一些实现会在请求前检查 `.approved`，已授权则直接走“开启屏蔽/选择 App”流程。

 ```swift
 @MainActor
 func ensureAuthorized() async -> Bool {
   if AuthorizationCenter.shared.authorizationStatus == .approved {
     return true
   }

   do {
     try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
     return AuthorizationCenter.shared.authorizationStatus == .approved
   } catch {
     return false
   }
 }
 ```

 ### 常见用法 3：把“授权状态”单独做成可观察属性（而不是每次同步读取）
 场景：需要更强的 UI 响应性时，会把状态缓存为 `@Published`，并在合适时机刷新。

 ```swift
 @MainActor
 final class PermissionModel: ObservableObject {
   @Published var status: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus

   func refresh() {
     status = AuthorizationCenter.shared.authorizationStatus
   }
 }
 ```

 ### 常见用法 4：授权成功后衔接 FamilyActivityPicker / ManagedSettingsStore
 场景：授权只是第一步；后续通常会：选择要限制的 App/分类，并写入 `ManagedSettingsStore` 应用屏蔽。

 ```swift
 // 伪代码级别示例：授权 -> 选择 -> 应用限制
 if AuthorizationCenter.shared.authorizationStatus == .approved {
   // 1) 展示 familyActivityPicker 让用户选择
   // 2) 将 selection 的 token 写入 ManagedSettingsStore 的 shield
 }
 ```

 ---
 ## 5) GitHub 常见用法总结 + 示例（对应上面 4 点）
 - 启动即请求：适合强依赖权限的最简流程（见“常见用法 1”示例）。
 - 请求前判断状态：减少无意义请求、便于控制引导（见“常见用法 2”示例）。
 - 可观察状态模型：更方便 UI 绑定与刷新（见“常见用法 3”示例）。
 - 授权后接屏蔽链路：权限 -> 选择 -> 限制 是常见闭环（见“常见用法 4”示例）。

 实务注意（经验性总结）：
 - 真机/模拟器差异：FamilyControls/Screen Time 相关能力在模拟器上经常不可用或行为不同，验证以真机为准。
 - 权限/Entitlement：需要相应 capability/entitlement（如 Family Controls）才能在生产环境生效。
 */

class RequestAuthorizer: ObservableObject {
  @Published var isAuthorized = false
  @Published var authorizationStatus: AuthorizationStatus = .notDetermined

  init() {
    checkAuthorizationStatus()
  }

  func checkAuthorizationStatus() {
    authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    isAuthorized = authorizationStatus == .approved
  }

  func requestAuthorization() async throws {
    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    print("Individual authorization successful")
    
    await MainActor.run {
      self.checkAuthorizationStatus()
    }
  }

  func requestAuthorization() {
    Task {
      do {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        print("Individual authorization successful")

        // Dispatch the update to the main thread
        await MainActor.run {
          self.checkAuthorizationStatus()
        }
      } catch {
        print("Error requesting authorization: \(error)")
        await MainActor.run {
          self.isAuthorized = false
          self.checkAuthorizationStatus()
        }
      }
    }
  }

  func revokeAuthorization() async {
    // Note: Apple doesn't provide a direct API to revoke authorization
    // User needs to manually revoke from Settings > Screen Time
    await MainActor.run {
      self.checkAuthorizationStatus()
    }
  }

  func getAuthorizationStatus() -> AuthorizationStatus {
    return AuthorizationCenter.shared.authorizationStatus
  }
}
