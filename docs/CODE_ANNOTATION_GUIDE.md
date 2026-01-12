# Foqos 代码文件注释指南

## 注释原则
1. **块级注释** - 对每个逻辑块或方法进行分组注释
2. **中文注释** - 方便中文开发者阅读
3. **用途说明** - 说明"是什么"和"为什么"，不仅仅是"做什么"
4. **流程注释** - 用 ASCII 图表说明关键流程
5. **示例代码** - 提供实际使用案例

---

## AppBlockerUtil.swift 详细注释

```swift
import ManagedSettings
import SwiftUI

/**
 # AppBlockerUtil - Screen Time 限制执行引擎
 
 ## 核心职责
 这是连接业务逻辑与 Apple ManagedSettings 框架的关键类。
 它负责将 Profile 配置转换为实际的系统屏蔽限制。
 
 ## 三大限制类型
 1. **应用屏蔽** (Application Shield)
    - 白名单模式: 仅允许指定应用，其他全部屏蔽
    - 黑名单模式: 屏蔽指定应用，其他全部允许
    
 2. **网页屏蔽** (Web Content Filter)
    - 白名单模式: 仅允许访问指定域名
    - 黑名单模式: 屏蔽指定域名
    
 3. **严格模式** (Strict Mode / Deny App Removal)
    - 防止用户卸载被屏蔽的应用
    - 仅在用户停止阻止时才解除
 
 ## 数据流
 BlockedProfiles (SwiftData)
     ↓
 [转换为 SharedData.ProfileSnapshot]
     ↓
 AppBlockerUtil.activateRestrictions()
     ↓
 ManagedSettingsStore (系统 API)
     ↓
 [系统强制执行限制]
 
 ## 关键设计决策
 - 使用 ProfileSnapshot 而非直接使用 BlockedProfiles
   原因：ProfileSnapshot 可被序列化到 App Group，供 Extensions 使用
 
 - 使用 FamilyActivitySelection 中的 tokens
   原因：tokens 是 Screen Time API 的标准输入，包含应用和分类信息
 */
class AppBlockerUtil {
  /// ManagedSettingsStore 实例 - 真正执行限制的底层 API
  let store = ManagedSettingsStore(
    named: ManagedSettingsStore.Name("foqosAppRestrictions")
  )

  /// 激活屏蔽限制
  /// 
  /// 这个方法是整个项目中最关键的"屏蔽执行"入口。
  /// 它会根据配置分为以下几个阶段：
  /// 1. 准备应用和网页的 token 列表
  /// 2. 根据模式（白名单/黑名单）设置应用屏蔽
  /// 3. 根据模式设置网页屏蔽
  /// 4. 如果启用严格模式，防止应用卸载
  ///
  /// - Parameter profile: SharedData.ProfileSnapshot - 包含所有屏蔽配置的快照
  ///
  /// 使用示例：
  /// ```swift
  /// let profile = SharedData.profileSnapshots["profile-id"]
  /// appBlocker.activateRestrictions(for: profile)
  /// // 之后，设备上被屏蔽的应用将显示 Shield UI，用户无法打开
  /// ```
  func activateRestrictions(for profile: SharedData.ProfileSnapshot) {
    print("Starting restrictions...")

    let selection = profile.selectedActivity
    
    // 🔧 配置参数
    /// 是否启用白名单应用模式
    /// true: 仅允许 applicationTokens 中的应用，其他全部屏蔽
    /// false: 屏蔽 applicationTokens 中的应用，其他全部允许
    let allowOnlyApps = profile.enableAllowMode
    
    /// 是否启用白名单网页模式（与应用模式独立）
    let allowOnlyDomains = profile.enableAllowModeDomains
    
    /// 是否启用严格模式（防应用卸载）
    let strict = profile.enableStrictMode
    
    /// 是否启用 Safari 网页屏蔽
    /// 如果 false，则网页屏蔽被禁用，用户可自由浏览
    let enableSafariBlocking = profile.enableSafariBlocking
    
    /// 提取域名列表用于网页过滤
    let domains = getWebDomains(from: profile)

    // 📦 提取 token 列表
    /// FamilyActivitySelection 包含用户选择的应用和分类
    let applicationTokens = selection.applicationTokens
    let categoriesTokens = selection.categoryTokens
    let webTokens = selection.webDomainTokens

    // ================================================
    // 【应用屏蔽阶段】
    // ================================================
    if allowOnlyApps {
      // 🟢 白名单模式：屏蔽所有应用除外指定的应用
      // 例如：用户只想允许 Safari、邮件、笔记，其他所有应用都屏蔽
      /// 设置为：屏蔽所有分类，除了 applicationTokens
      store.shield.applicationCategories = .all(except: applicationTokens)

      if enableSafariBlocking {
        // Safari 也使用白名单模式
        store.shield.webDomainCategories = .all(except: webTokens)
      }
    } else {
      // 🔴 黑名单模式：仅屏蔽指定的应用
      // 例如：用户想屏蔽 TikTok、YouTube、游戏，但其他应用正常
      /// 仅屏蔽指定的应用
      store.shield.applications = applicationTokens
      /// 仅屏蔽指定的分类（如"游戏"、"社交媒体"）
      store.shield.applicationCategories = .specific(categoriesTokens)

      if enableSafariBlocking {
        // Safari 使用黑名单模式
        store.shield.webDomainCategories = .specific(categoriesTokens)
        store.shield.webDomains = webTokens
      }
    }

    // ================================================
    // 【网页内容过滤阶段】
    // ================================================
    /// 注意：这与上面的 webDomainCategories 和 webDomains 不同！
    /// webContent.blockedByFilter 用于内容分类过滤，例如：
    /// - 成人内容
    /// - 赌博网站
    /// - 暴力内容
    /// - 自定义域名黑名单
    if allowOnlyDomains {
      // 白名单模式：仅允许指定的域名，其他被过滤器拦截
      store.webContent.blockedByFilter = .all(except: domains)
    } else {
      // 黑名单模式：指定的域名被过滤器拦截
      store.webContent.blockedByFilter = .specific(domains)
    }

    // ================================================
    // 【严格模式阶段】
    // ================================================
    /// 启用此选项后，用户无法卸载被屏蔽的应用
    /// 例如：用户启用严格模式屏蔽 TikTok，他无法手动卸载 TikTok
    /// 必须等待屏蔽期结束或扫描 NFC 标签才能恢复
    store.application.denyAppRemoval = strict
  }

  /// 解除所有屏蔽限制
  ///
  /// 将设备恢复到完全无限制的状态。
  /// 这个方法在以下情况调用：
  /// 1. 用户手动停止阻止
  /// 2. 计时器到期自动停止
  /// 3. 使用 NFC/QR 码解锁
  ///
  /// 使用示例：
  /// ```swift
  /// appBlocker.deactivateRestrictions()
  /// // 之后，所有被屏蔽的应用和网站都可以正常访问
  /// ```
  func deactivateRestrictions() {
    print("Stoping restrictions...")

    // 清空所有应用屏蔽配置
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    
    // 清空所有网页屏蔽配置
    store.shield.webDomains = nil
    store.shield.webDomainCategories = nil

    // 关闭严格模式，允许用户卸载应用
    store.application.denyAppRemoval = false

    // 清空网页内容过滤规则
    store.webContent.blockedByFilter = nil

    // 彻底清空 ManagedSettingsStore 中的所有设置
    // 这确保没有"幽灵"限制残留
    store.clearAllSettings()
  }

  /// 从 Profile 快照中提取网页域名列表
  ///
  /// - Parameter profile: Profile 快照
  /// - Returns: WebDomain 对象的集合
  func getWebDomains(from profile: SharedData.ProfileSnapshot) -> Set<WebDomain> {
    if let domains = profile.domains {
      return Set(domains.map { WebDomain(domain: $0) })
    }
    return []
  }
}
```

---

## RequestAuthorizer.swift 详细注释

```swift
import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

/**
 # RequestAuthorizer - Family Controls 授权管理
 
 ## 核心职责
 管理用户对"屏幕使用时间"功能的授权状态。
 
 ## 授权流程
 1. App 启动时检查当前授权状态
 2. 如果未授权，在主页显示"需要授权"提示
 3. 用户点击授权按钮触发 requestAuthorization()
 4. 系统显示授权对话框
 5. 用户同意后，isAuthorized 状态更新，功能解锁
 
 ## 关键概念
 - **AuthorizationStatus**: 系统侧的真实状态
   - .approved - 已授权
   - .denied - 用户拒绝
   - .notDetermined - 尚未请求
 
 - **isAuthorized**: App 侧的观察值
   - true - 用户已授权，可以使用屏蔽功能
   - false - 未授权或被拒绝
 
 ## 约束条件
 - 一旦用户拒绝授权，除非重新安装 App，否则无法再次请求
 - 用户可在"设置 > 屏幕使用时间"中手动更改授权状态
 - 某些 iOS 版本或测试环境中可能不支持授权
 */
class RequestAuthorizer: ObservableObject {
  /// 发布当前授权状态，供 UI 订阅
  /// true: 已授权，可以使用屏蔽功能
  /// false: 未授权，需要提示用户
  @Published var isAuthorized = false

  /// 获取系统侧的真实授权状态
  /// 这是"真实源"(source of truth)，isAuthorized 是基于此生成的
  func getAuthorizationStatus() -> AuthorizationCenter.AuthorizationStatus {
    return AuthorizationCenter.shared.authorizationStatus
  }

  /// 异步请求 Family Controls 授权
  ///
  /// 调用此方法时：
  /// 1. 系统会显示一个本地授权对话框
  /// 2. 用户可以选择"允许"或"拒绝"
  /// 3. 结果会同步到 isAuthorized (通过 MainActor 确保 UI 更新)
  ///
  /// 关键实现：
  /// - 使用 Task {} 在后台线程执行 async/await API
  /// - 使用 await MainActor.run {} 回到主线程更新 @Published
  /// - 这避免了跨线程更新 UI 状态导致的崩溃
  ///
  /// 使用示例：
  /// ```swift
  /// @EnvironmentObject var requestAuthorizer: RequestAuthorizer
  ///
  /// Button("授权屏幕使用时间") {
  ///   requestAuthorizer.requestAuthorization()
  /// }
  /// ```
  func requestAuthorization() {
    Task {
      do {
        // 向系统请求 Family Controls 授权
        // Scope: .individual 表示针对当前用户（非家长控制）
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        
        // 授权请求完成后，更新 isAuthorized 状态
        await MainActor.run {
          // 检查最新的授权状态
          self.isAuthorized = self.getAuthorizationStatus() == .approved
        }
      } catch {
        // 授权请求失败（例如：系统限制、设备不支持等）
        print("Authorization request failed: \(error)")
        
        await MainActor.run {
          self.isAuthorized = false
        }
      }
    }
  }
}
```

---

## DeviceActivityMonitorExtension.swift 详细注释

```swift
import DeviceActivity
import ManagedSettings
import OSLog

private let log = Logger(
  subsystem: "com.foqos.monitor",
  category: "DeviceActivity"
)

/**
 # DeviceActivityMonitorExtension - 日程监控回调处理
 
 ## 核心职责
 当 DeviceActivitySchedule 到达触发时间时，系统会在后台唤醒这个 Extension。
 它负责执行实际的屏蔽启动和停止逻辑。
 
 ## 执行流程
 1. [App 端] 用户设置日程（如"每晚10点-早6点"）
 2. [App 端] 调用 DeviceActivityCenter.startMonitoring() 注册监控
 3. [系统] 到达触发时间（如晚上10:00）
 4. [系统] 在后台唤醒这个 Extension 进程
 5. [Extension] 回调 intervalDidStart()
 6. [Extension] 从 SharedData 读取配置快照
 7. [Extension] 调用 AppBlockerUtil 应用限制
 8. [用户] 看到被屏蔽应用显示 Shield UI
 9. [系统] 到达结束时间（如早上6:00）
 10. [Extension] 回调 intervalDidEnd()
 11. [Extension] 调用 AppBlockerUtil 解除限制
 12. [用户] 应用恢复正常使用
 
 ## 重要约束
 - Extension 进程在后台执行，无法直接访问主 App
 - 因此必须使用 SharedData (App Group UserDefaults) 共享配置
 - 所有操作都受 Family Controls entitlements 限制
 - 如果授权被撤销，此 Extension 将失效
 
 ## 调试方法
 由于 Extension 在后台运行，调试很困难。建议：
 1. 查看 OSLog 日志（Xcode Organizer > Console）
 2. 在 AppBlockerUtil 中添加 UserDefaults 写入作为"日志"
 3. 在主 App 中创建"日程历史"视图显示最后的操作
 */
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  private let appBlocker = AppBlockerUtil()

  override init() {
    super.init()
  }

  /// 日程间隔开始回调
  ///
  /// 当 DeviceActivitySchedule 的开始时间到达时，系统调用此方法。
  /// 此方法必须快速完成（通常有 30 秒超时限制）。
  ///
  /// - Parameter activity: DeviceActivityName - 标识具体是哪个日程
  ///   名称格式通常是 "ScheduleTimerActivity_<profile-id>"
  ///
  /// 执行流程：
  /// 1. 根据 activity 名称解析 Profile ID
  /// 2. 从 SharedData 读取 ProfileSnapshot
  /// 3. 调用 AppBlockerUtil.activateRestrictions()
  /// 4. 更新 SessionSnapshot 到 SharedData
  /// 5. 记录操作日志
  ///
  /// 注意：
  /// - 不要在此方法中执行长时间操作
  /// - 不要尝试访问主 App 的 ModelContext
  /// - 使用 SharedData 作为跨进程通信的唯一方式
  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    log.info("intervalDidStart for activity: \(activity.rawValue)")
    
    // 由 TimerActivityUtil 处理实际的启动逻辑
    // 包括解析 activity 名称、读取配置、应用限制
    TimerActivityUtil.startTimerActivity(for: activity)
  }

  /// 日程间隔结束回调
  ///
  /// 当 DeviceActivitySchedule 的结束时间到达时，系统调用此方法。
  ///
  /// - Parameter activity: DeviceActivityName - 标识具体是哪个日程
  ///
  /// 执行流程：
  /// 1. 根据 activity 名称解析 Profile ID
  /// 2. 从 SharedData 读取当前 SessionSnapshot
  /// 3. 调用 AppBlockerUtil.deactivateRestrictions()
  /// 4. 清空 SessionSnapshot
  /// 5. 记录操作日志
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)

    log.info("intervalDidEnd for activity: \(activity.rawValue)")
    
    // 由 TimerActivityUtil 处理实际的停止逻辑
    TimerActivityUtil.stopTimerActivity(for: activity)
  }
}
```

---

## 注释最佳实践

### ✅ 好的注释例子
```swift
/// 【应用屏蔽阶段】
/// 
/// 这个阶段根据 allowOnlyApps 标志决定使用白名单还是黑名单模式：
/// - 白名单模式: 屏蔽所有应用除外指定的应用
/// - 黑名单模式: 仅屏蔽指定的应用
if allowOnlyApps {
  store.shield.applicationCategories = .all(except: applicationTokens)
} else {
  store.shield.applications = applicationTokens
}
```

### ❌ 差的注释例子
```swift
// 设置应用屏蔽
if allowOnlyApps {
  store.shield.applicationCategories = .all(except: applicationTokens)
}
```

### ✅ 好的块级注释
```swift
// ================================================
// 【数据验证阶段】
// ================================================
// 1. 检查配置是否完整
// 2. 验证时间范围的合法性
// 3. 确保不存在冲突的日程
guard validateConfiguration(profile) else {
  throw ConfigurationError.invalid
}
```

---

## 下一步

1. 继续为以下文件添加详细注释：
   - [ ] StrategyManager.swift (优先级最高)
   - [ ] DeviceActivityCenterUtil.swift
   - [ ] TimersUtil.swift
   - [ ] LiveActivityManager.swift
   - [ ] BlockedProfiles.swift

2. 为每个文件创建：
   - [ ] 整体架构图
   - [ ] 数据流图
   - [ ] 使用案例示例

3. 创建：
   - [ ] API 参考文档
   - [ ] 常见错误和解决方案
   - [ ] 贡献指南

