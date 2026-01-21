//
//  AppBlockerUtil.swift
//  ZenBound
//
//  Screen Time 限制管理工具
//  封装 ManagedSettingsStore，是应用层与 Apple Screen Time API 之间的桥梁
//

import FamilyControls
import ManagedSettings
import SwiftUI

/// 应用屏蔽工具类
/// 负责将业务层的屏蔽配置转化为系统底层的实际限制指令
class AppBlockerUtil {
    /// ManagedSettingsStore 实例，用于存储和管理屏蔽设置
    let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("zenBoundAppRestrictions")
    )
    
    // MARK: - 专注组限制
    
    /// 激活专注组限制
    /// - Parameter group: 专注组配置快照
    func activateFocusRestrictions(for group: SharedData.FocusGroupSnapshot) {
        print("[ZenBound] Starting focus restrictions for: \(group.name)")
        
        let selection = group.selectedActivity
        let applicationTokens = selection.applicationTokens
        let categoriesTokens = selection.categoryTokens
        let webTokens = selection.webDomainTokens
        
        if group.blockAllApps {
            // 屏蔽所有应用（除了选中的）
            store.shield.applicationCategories = .all(except: applicationTokens)
            store.shield.webDomainCategories = .all(except: webTokens)
        } else {
            // 仅屏蔽选中的应用
            store.shield.applications = applicationTokens
            store.shield.applicationCategories = .specific(categoriesTokens)
            store.shield.webDomainCategories = .specific(categoriesTokens)
            store.shield.webDomains = webTokens
        }
        
        // 禁止应用切换（如果启用）
        if group.blockAppSwitching {
            store.application.denyAppRemoval = true
        }
    }
    
    // MARK: - 严格组限制
    
    /// 激活严格组限制
    /// - Parameter group: 严格组配置快照
    func activateStrictRestrictions(for group: SharedData.StrictGroupSnapshot) {
        print("[ZenBound] Starting strict restrictions for: \(group.name)")
        
        let selection = group.selectedActivity
        let applicationTokens = selection.applicationTokens
        let categoriesTokens = selection.categoryTokens
        let webTokens = selection.webDomainTokens
        
        // 屏蔽选中的应用
        store.shield.applications = applicationTokens
        store.shield.applicationCategories = .specific(categoriesTokens)
        store.shield.webDomains = webTokens
        store.shield.webDomainCategories = .specific(categoriesTokens)
        
        // 网页过滤
        let blockedDomains = Set(group.blockedWebsites.map { WebDomain(domain: $0) })
        if !blockedDomains.isEmpty {
            store.webContent.blockedByFilter = .specific(blockedDomains)
        }
        
        // 禁止安装新应用（如果启用）
        if group.blockAppStoreInstall {
            store.application.denyAppInstallation = true
        }
    }
    
    // MARK: - 娱乐组限制
    
    /// 激活娱乐组限制
    /// - Parameter group: 娱乐组配置快照
    func activateEntertainmentRestrictions(for group: SharedData.EntertainmentGroupSnapshot) {
        print("[ZenBound] Starting entertainment restrictions for: \(group.name)")
        
        let selection = group.selectedActivity
        let applicationTokens = selection.applicationTokens
        let categoriesTokens = selection.categoryTokens
        let webTokens = selection.webDomainTokens
        
        // 屏蔽选中的娱乐应用
        store.shield.applications = applicationTokens
        store.shield.applicationCategories = .specific(categoriesTokens)
        store.shield.webDomains = webTokens
        store.shield.webDomainCategories = .specific(categoriesTokens)
        
        // 休息时屏蔽所有应用
        if group.enableRestBlock && group.blockAllAppsWhenRest {
            store.shield.applicationCategories = .all(except: applicationTokens)
        }
    }
    
    // MARK: - 通用方法
    
    /// 解除所有限制
    func deactivateAllRestrictions() {
        print("[ZenBound] Stopping all restrictions...")
        
        // 清除所有屏蔽
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        
        // 清除应用限制
        store.application.denyAppRemoval = false
        store.application.denyAppInstallation = false
        
        // 清除网页过滤
        store.webContent.blockedByFilter = nil
        
        // 清除所有设置
        store.clearAllSettings()
    }
    
    /// 临时解除限制（用于紧急解锁或休息时间）
    func temporarilyDeactivate() {
        print("[ZenBound] Temporarily deactivating restrictions...")
        
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }
    
    /// 恢复之前的限制
    /// - Parameter groupType: 应用组类型
    /// - Parameter groupId: 应用组ID
    func restoreRestrictions(groupType: SharedData.GroupType, groupId: String) {
        print("[ZenBound] Restoring restrictions for group: \(groupId)")
        
        switch groupType {
        case .focus:
            if let group = SharedData.getFocusGroup(id: groupId) {
                activateFocusRestrictions(for: group)
            }
        case .strict:
            if let group = SharedData.getStrictGroup(id: groupId) {
                activateStrictRestrictions(for: group)
            }
        case .entertainment:
            if let group = SharedData.getEntertainmentGroup(id: groupId) {
                activateEntertainmentRestrictions(for: group)
            }
        }
    }
}
