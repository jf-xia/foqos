import SwiftUI

/**
 1) 作用：集中管理通用/深链 URL 的解析与路由信号，拆出 profile 相关路径片段，写入可观察状态（`profileId` / `navigateToProfileId` / `link`），供上层视图监听并触发会话切换或页面跳转，支持后续清理以避免重复导航。
 2) 项目内用法与流程：在应用根场景以单例形式注入环境对象用于全局路由信号（参见 foqosApp.swift）；`HomeView` 监听 `profileId` 与 `link` 的变化来从深链触发会话开/关（HomeView.swift），监听 `navigateToProfileId` 来滚动/选中对应卡片（HomeView.swift），完成后调用 `clearNavigation()` 复位状态。
 3) 项目内用法示例：
    - 根场景注入，允许任意子视图读取路由信号：
      ```swift
      @StateObject private var nav = NavigationManager()
      HomeView()
        .environmentObject(nav)   // 根级注入
      ```
    - 解析通用链接后触发会话切换（`HomeView` 中的监听）：
      ```swift
      .onChange(of: navigationManager.profileId) { _, newValue in
        if let id = newValue, let url = navigationManager.link {
          toggleSessionFromDeeplink(id, link: url) // 会话开关
          navigationManager.clearNavigation()      // 避免重复触发
        }
      }
      ```
    - 解析导航型链接后定位到特定配置卡片：
      ```swift
      .onChange(of: navigationManager.navigateToProfileId) { _, newValue in
        if let id = newValue {
          navigateToProfileId = UUID(uuidString: id) // UI 滚动/选中
          navigationManager.clearNavigation()
        }
      }
      ```
 4) GitHub 常见模式（Activity/设置类 App 的深链路由，stars>200，近两年 Swift 项目抽象）：使用 `URLComponents` 解析 host/path/query；定义 `Route` 枚举或结构体承载目的地；在 `@EnvironmentObject` / `ObservableObject` 路由器里存储轻量状态，视图层用 `.onOpenURL` / `.onContinueUserActivity` 或 `.onChange` 驱动导航；处理后立即清空路由状态防止重复跳转。
 5) GitHub 常见用法示例（抽象化示例）：
    ```swift
    final class DeepLinkRouter: ObservableObject {
      @Published var route: Route?

      func handle(_ url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        switch comps.path.split(separator: "/").map(String.init) {
        case ["profile", let id]:
          route = .openProfile(UUID(uuidString: id))
        case ["navigate", let id]:
          route = .scrollTo(UUID(uuidString: id))
        default:
          break
        }
      }

      func clear() { route = nil }
    }
    ```
 注意事项：仅维护应用内路由信号，不自动导航；必须由监听视图消费后调用 `clearNavigation()`/`clear()` 复位；URL 解析失败时静默忽略以避免错误路由；若需支持 host/查询参数，可在解析阶段扩展匹配逻辑。 
*/
class NavigationManager: ObservableObject {
  @Published var profileId: String? = nil
  @Published var link: URL? = nil

  @Published var navigateToProfileId: String? = nil

  func handleLink(_ url: URL) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    guard let path = components?.path else { return }

    let parts = path.split(separator: "/")
    if let basePath = parts[safe: 0], let profileId = parts[safe: 1] {
      switch String(basePath) {
      case "profile":
        self.profileId = String(profileId)
        self.link = url
      case "navigate":
        self.navigateToProfileId = String(profileId)
        self.link = url
      default:
        break
      }
    }
  }

  func clearNavigation() {
    profileId = nil
    link = nil
    navigateToProfileId = nil
  }
}
