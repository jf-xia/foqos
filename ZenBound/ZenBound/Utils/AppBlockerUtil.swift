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
}
