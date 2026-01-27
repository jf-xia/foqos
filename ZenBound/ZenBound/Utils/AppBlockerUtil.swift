import FamilyControls
import ManagedSettings
import SwiftUI

/**
 Screen Time 限制管理工具 / 核心屏蔽逻辑控制器

 1. 功能说明
    该类封装了 `ManagedSettingsStore`，是应用层与 Apple Screen Time API (ManagedSettings) 之间的主要桥梁。
    它负责将业务层的“屏蔽配置”（`SharedData.ProfileSnapshot`）转化为系统底层的实际限制指令，包括：
    - 应用屏蔽 (Shield Applications)
    - 网页屏蔽 (Web Content Filter)
    - 严格模式/防卸载 (Deny App Removal)
    - 白名单/黑名单模式切换

 2. 项目内使用方式
    - **核心依赖**: 被所有 `BlockingStrategy`（如 Manual, NFC, QR）和 `DeviceActivityMonitorExtension` 实例化并持有。
    - **调用时机**: 当专注会话开始 (`activateRestrictions`) 或结束 (`deactivateRestrictions`) 时调用。
    - **数据跨层**: 接受 `SharedData.ProfileSnapshot` 作为参数，这是一种设计用于在 App Group 间共享的轻量级数据结构（App 与 Extension 共享）。

 3. 项目内代码示例
    ```swift
    // 在策略类 (如 ManualBlockingStrategy) 中使用:
    class ManualStrategy {
        private let appBlocker = AppBlockerUtil()

        func startSession(profile: BlockedProfiles) {
            // 1. 将 SwiftData 模型转为快照
            let snapshot = BlockedProfiles.getSnapshot(for: profile)
            
            // 2. 激活限制
            appBlocker.activateRestrictions(for: snapshot)
        }

        func stopSession() {
            // 3. 解除限制
            appBlocker.deactivateRestrictions()
        }
    }
    ```
 */
 class AppBlockerUtil {
  let store = ManagedSettingsStore(
    named: ManagedSettingsStore.Name("ZenBoundAppRestrictions")
  )

  func activateRestrictions(for profile: SharedData.ProfileSnapshot) {
    print("Starting restrictions...")

      // Extract toggles from snapshot (App Group safe data)
    let selection = profile.selectedActivity
    let allowOnlyApps = profile.enableAllowMode
    let allowOnlyDomains = profile.enableAllowModeDomains
    let strict = profile.enableStrictMode
    let enableSafariBlocking = profile.enableSafariBlocking
    let domains = getWebDomains(from: profile)

    let applicationTokens = selection.applicationTokens
    let categoriesTokens = selection.categoryTokens
    let webTokens = selection.webDomainTokens

      // Mode 1: Allow-only apps (block everything except selected apps)
    if allowOnlyApps {
      store.shield.applicationCategories =
        .all(except: applicationTokens)

      if enableSafariBlocking {
        store.shield.webDomainCategories = .all(except: webTokens)
      }

    } else {
        // Mode 2: Block listed apps/categories (default)
      store.shield.applications = applicationTokens
      store.shield.applicationCategories = .specific(categoriesTokens)

      if enableSafariBlocking {
        store.shield.webDomainCategories = .specific(categoriesTokens)
        store.shield.webDomains = webTokens
      }
    }

      // Web filter: allow-only domains vs block specific domains
    if allowOnlyDomains {
      store.webContent.blockedByFilter = .all(except: domains)
    } else {
      store.webContent.blockedByFilter = .specific(domains)
    }

    store.application.denyAppRemoval = strict
  }

  func deactivateRestrictions() {
    print("Stoping restrictions...")

    // Clear all shields and app removal lock
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    store.shield.webDomainCategories = nil

    store.application.denyAppRemoval = false

    store.webContent.blockedByFilter = nil

    store.clearAllSettings()
  }

  func getWebDomains(from profile: SharedData.ProfileSnapshot) -> Set<WebDomain> {
    // Convert string domains to WebDomain tokens expected by ManagedSettings
    if let domains = profile.domains {
      return Set(domains.map { WebDomain(domain: $0) })
    }

    return []
  }

  // MARK: - Content & Privacy Restrictions (内容与隐私权限制)

  // MARK: iTunes 与 App Store 购买
  
  /// 设置 App Store 限制
  /// - Parameters:
  ///   - denyInstallation: 禁止安装 App
  ///   - denyRemoval: 禁止删除 App
  ///   - denyInAppPurchases: 禁止 App 内购买
  ///   - requirePassword: 购买时需要密码
  ///   - maximumRating: App 内容分级 (100=4+, 200=9+, 300=12+, 600=17+, nil=无限制)
  func setAppStoreRestrictions(
    denyInstallation: Bool = false,
    denyRemoval: Bool = false,
    denyInAppPurchases: Bool = false,
    requirePassword: Bool = false,
    maximumRating: Int? = nil
  ) {
    print("[ContentPrivacy] Setting App Store restrictions...")
    print("  - denyInstallation: \(denyInstallation)")
    print("  - denyRemoval: \(denyRemoval)")
    print("  - denyInAppPurchases: \(denyInAppPurchases)")
    print("  - requirePassword: \(requirePassword)")
    print("  - maximumRating: \(String(describing: maximumRating))")
    
    // 注意: denyAppInstallation 和 denyAppRemoval 在 store.application 中
    store.application.denyAppInstallation = denyInstallation
    store.application.denyAppRemoval = denyRemoval
    store.appStore.denyInAppPurchases = denyInAppPurchases
    store.appStore.requirePasswordForPurchases = requirePassword
    
    if let rating = maximumRating {
      store.appStore.maximumRating = rating
    } else {
      store.appStore.maximumRating = nil
    }
  }
  
  /// 清除 App Store 限制
  func clearAppStoreRestrictions() {
    print("[ContentPrivacy] Clearing App Store restrictions...")
    store.application.denyAppInstallation = false
    store.application.denyAppRemoval = false
    store.appStore.denyInAppPurchases = false
    store.appStore.requirePasswordForPurchases = false
    store.appStore.maximumRating = nil
  }

  // MARK: 媒体内容限制
  
  /// 设置媒体内容限制
  /// - Parameters:
  ///   - maximumMovieRating: 电影内容分级 (200=G, 300=PG, 400=PG-13, 500=R, 600=NC-17)
  ///   - maximumTVShowRating: 电视节目内容分级 (200=TV-Y, 300=TV-G, 400=TV-PG, 500=TV-14, 600=TV-MA)
  /// - Note: denyExplicitContent 在 ManagedSettings 框架中不可用，仅记录日志
  func setMediaRestrictions(
    denyExplicitContent: Bool = false,
    maximumMovieRating: Int? = nil,
    maximumTVShowRating: Int? = nil
  ) {
    print("[ContentPrivacy] Setting Media restrictions...")
    print("  - denyExplicitContent: \(denyExplicitContent) (注意: API 不支持此功能)")
    print("  - maximumMovieRating: \(String(describing: maximumMovieRating))")
    print("  - maximumTVShowRating: \(String(describing: maximumTVShowRating))")
    
    // 注意: MediaSettings 没有 denyExplicitContent 属性
    // 此功能需要通过 MDM 或设置 App 中手动配置
    
    if let movieRating = maximumMovieRating {
      store.media.maximumMovieRating = movieRating
    } else {
      store.media.maximumMovieRating = nil
    }
    
    if let tvRating = maximumTVShowRating {
      store.media.maximumTVShowRating = tvRating
    } else {
      store.media.maximumTVShowRating = nil
    }
  }
  
  /// 清除媒体内容限制
  func clearMediaRestrictions() {
    print("[ContentPrivacy] Clearing Media restrictions...")
    store.media.maximumMovieRating = nil
    store.media.maximumTVShowRating = nil
  }

  // MARK: Siri 限制
  
  /// 设置 Siri 限制
  /// - Parameters:
  ///   - denySiri: 完全禁用 Siri
  /// - Note: 细粒度控制 (网页搜索、语言过滤) 在 ManagedSettings 中不可用
  func setSiriRestrictions(
    denySiri: Bool = false
  ) {
    print("[ContentPrivacy] Setting Siri restrictions...")
    print("  - denySiri: \(denySiri)")
    
    // 注意: SiriSettings 只有 denySiri 属性
    // denySiriContentFromWeb 和 denyExplicitContent 不可用
    store.siri.denySiri = denySiri
  }
  
  /// 清除 Siri 限制
  func clearSiriRestrictions() {
    print("[ContentPrivacy] Clearing Siri restrictions...")
    store.siri.denySiri = false
  }

  // MARK: Game Center 限制
  
  /// 设置 Game Center 限制
  /// - Parameters:
  ///   - denyMultiplayer: 禁止多人游戏
  ///   - denyAddingFriends: 禁止新增朋友
  func setGameCenterRestrictions(
    denyMultiplayer: Bool = false,
    denyAddingFriends: Bool = false
  ) {
    print("[ContentPrivacy] Setting Game Center restrictions...")
    print("  - denyMultiplayer: \(denyMultiplayer)")
    print("  - denyAddingFriends: \(denyAddingFriends)")
    
    store.gameCenter.denyMultiplayerGaming = denyMultiplayer
    store.gameCenter.denyAddingFriends = denyAddingFriends
  }
  
  /// 清除 Game Center 限制
  func clearGameCenterRestrictions() {
    print("[ContentPrivacy] Clearing Game Center restrictions...")
    store.gameCenter.denyMultiplayerGaming = false
    store.gameCenter.denyAddingFriends = false
  }

  // MARK: 隐私权限变更限制
  
  /// 设置隐私权限变更限制 (仅记录日志，API 不支持)
  /// - Note: ManagedSettings 框架不提供隐私权限控制
  ///         这些功能需要通过 MDM 配置文件实现
  func setPrivacyRestrictions(
    denyPhotosModification: Bool = false
  ) {
    print("[ContentPrivacy] Setting Privacy restrictions...")
    print("  - denyPhotosModification: \(denyPhotosModification)")
    print("  ⚠️ 注意: ManagedSettings 不支持隐私权限控制")
    print("  ⚠️ 需要通过 MDM 配置文件实现此功能")
    
    // ManagedSettingsStore 没有 privacy 属性
    // 隐私权限控制需要通过设备管理 (MDM) 实现
  }
  
  /// 清除隐私权限限制 (仅记录日志)
  func clearPrivacyRestrictions() {
    print("[ContentPrivacy] Clearing Privacy restrictions (no-op)...")
    // ManagedSettingsStore 没有 privacy 属性
  }

  // MARK: 系统变更限制
  
  /// 设置系统变更限制
  /// - Parameters:
  ///   - lockPasscode: 禁止变更密码
  ///   - lockAccounts: 禁止变更帐号
  ///   - lockAppCellularData: 禁止 App 变更行动数据设置
  func setSystemRestrictions(
    lockPasscode: Bool = false,
    lockAccounts: Bool = false,
    lockAppCellularData: Bool = false
  ) {
    print("[ContentPrivacy] Setting System restrictions...")
    print("  - lockPasscode: \(lockPasscode)")
    print("  - lockAccounts: \(lockAccounts)")
    print("  - lockAppCellularData: \(lockAppCellularData)")
    
    store.passcode.lockPasscode = lockPasscode
    store.account.lockAccounts = lockAccounts
    store.cellular.lockAppCellularData = lockAppCellularData
  }
  
  /// 清除系统变更限制
  func clearSystemRestrictions() {
    print("[ContentPrivacy] Clearing System restrictions...")
    store.passcode.lockPasscode = false
    store.account.lockAccounts = false
    store.cellular.lockAppCellularData = false
  }

  // MARK: 一键应用所有内容与隐私限制
  
  /// 批量应用内容与隐私限制配置
  struct ContentPrivacyConfig {
    // App Store / Application
    var denyAppInstallation: Bool = false
    var denyAppRemoval: Bool = false
    var denyInAppPurchases: Bool = false
    var requirePasswordForPurchases: Bool = false
    var appStoreMaximumRating: Int? = nil
    
    // Media (仅支持分级限制)
    var maximumMovieRating: Int? = nil
    var maximumTVShowRating: Int? = nil
    
    // Siri (仅支持完全禁用)
    var denySiri: Bool = false
    
    // Game Center
    var denyMultiplayerGaming: Bool = false
    var denyAddingFriends: Bool = false
    
    // System
    var lockPasscode: Bool = false
    var lockAccounts: Bool = false
    var lockAppCellularData: Bool = false
  }
  
  /// 应用完整的内容与隐私限制配置
  func applyContentPrivacyRestrictions(_ config: ContentPrivacyConfig) {
    print("[ContentPrivacy] Applying full Content & Privacy restrictions...")
    
    setAppStoreRestrictions(
      denyInstallation: config.denyAppInstallation,
      denyRemoval: config.denyAppRemoval,
      denyInAppPurchases: config.denyInAppPurchases,
      requirePassword: config.requirePasswordForPurchases,
      maximumRating: config.appStoreMaximumRating
    )
    
    setMediaRestrictions(
      maximumMovieRating: config.maximumMovieRating,
      maximumTVShowRating: config.maximumTVShowRating
    )
    
    setSiriRestrictions(
      denySiri: config.denySiri
    )
    
    setGameCenterRestrictions(
      denyMultiplayer: config.denyMultiplayerGaming,
      denyAddingFriends: config.denyAddingFriends
    )
    
    setSystemRestrictions(
      lockPasscode: config.lockPasscode,
      lockAccounts: config.lockAccounts,
      lockAppCellularData: config.lockAppCellularData
    )
    
    print("[ContentPrivacy] All restrictions applied successfully!")
  }
  
  /// 清除所有内容与隐私限制
  func clearAllContentPrivacyRestrictions() {
    print("[ContentPrivacy] Clearing all Content & Privacy restrictions...")
    clearAppStoreRestrictions()
    clearMediaRestrictions()
    clearSiriRestrictions()
    clearGameCenterRestrictions()
    clearPrivacyRestrictions()
    clearSystemRestrictions()
    print("[ContentPrivacy] All restrictions cleared!")
  }
}
