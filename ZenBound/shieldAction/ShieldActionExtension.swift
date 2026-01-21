//
//  ShieldActionExtension.swift
//  shieldAction
//
//  Created by Jack on 21/1/2026.
//

import ManagedSettings

// MARK: - App Group Constants
private let appGroupID = "group.dev.zenbound.data"

// MARK: - SharedData Keys
private enum SharedDataKey {
    static let activeSession = "activeSessionSnapshot"
    static let shieldAction = "pendingShieldAction"
}

// MARK: - Shield Action Types
private enum ZenBoundShieldAction: String, Codable {
    case openApp = "open_app"
    case breathingExercise = "breathing_exercise"
    case extendTime = "extend_time"
    case emergencyUnlock = "emergency_unlock"
}

// Override the functions below to customize the shield actions used in various situations.
// The system provides a default response for any functions that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldActionExtension: ShieldActionDelegate {
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    private var sessionType: String? {
        guard let data = userDefaults?.data(forKey: SharedDataKey.activeSession),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data) else {
            return nil
        }
        return snapshot.groupType
    }
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldAction(action: action, completionHandler: completionHandler)
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldAction(action: action, completionHandler: completionHandler)
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldAction(action: action, completionHandler: completionHandler)
    }
    
    // MARK: - Handle Actions
    
    private func handleShieldAction(action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        let type = sessionType ?? "focus"
        
        switch action {
        case .primaryButtonPressed:
            // Primary action: Open ZenBound app
            savePendingAction(.openApp)
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            // Secondary action depends on session type
            switch type {
            case "focus":
                // Continue focus - just close the shield
                completionHandler(.close)
                
            case "strict":
                // Emergency unlock - needs validation
                if canUseEmergencyUnlock() {
                    useEmergencyUnlock()
                    savePendingAction(.emergencyUnlock)
                    completionHandler(.defer)
                } else {
                    completionHandler(.close)
                }
                
            case "entertainment":
                // Extend time - check if allowed
                if canExtendTime() {
                    useTimeExtension()
                    savePendingAction(.extendTime)
                    completionHandler(.defer)
                } else {
                    completionHandler(.close)
                }
                
            default:
                completionHandler(.close)
            }
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    // MARK: - Emergency Unlock
    
    private func canUseEmergencyUnlock() -> Bool {
        let usedCount = userDefaults?.integer(forKey: "emergencyUnlocksUsed") ?? 0
        let maxCount = userDefaults?.integer(forKey: "emergencyUnlockMax") ?? 3
        return usedCount < maxCount
    }
    
    private func useEmergencyUnlock() {
        let usedCount = userDefaults?.integer(forKey: "emergencyUnlocksUsed") ?? 0
        userDefaults?.set(usedCount + 1, forKey: "emergencyUnlocksUsed")
        
        // Temporarily disable restrictions for 5 minutes
        userDefaults?.set(Date().addingTimeInterval(5 * 60), forKey: "emergencyUnlockExpiry")
    }
    
    // MARK: - Time Extension
    
    private func canExtendTime() -> Bool {
        let usedCount = userDefaults?.integer(forKey: "extensionsUsedToday") ?? 0
        let maxCount = userDefaults?.integer(forKey: "extensionMax") ?? 3
        return usedCount < maxCount
    }
    
    private func useTimeExtension() {
        let usedCount = userDefaults?.integer(forKey: "extensionsUsedToday") ?? 0
        userDefaults?.set(usedCount + 1, forKey: "extensionsUsedToday")
        
        // Record extension
        let extensionDuration = userDefaults?.integer(forKey: "extensionDuration") ?? 10
        userDefaults?.set(extensionDuration, forKey: "lastExtensionDuration")
    }
    
    // MARK: - Helpers
    
    private func savePendingAction(_ action: ZenBoundShieldAction) {
        if let encoded = try? JSONEncoder().encode(action) {
            userDefaults?.set(encoded, forKey: SharedDataKey.shieldAction)
        }
        userDefaults?.set(Date(), forKey: "pendingShieldActionTime")
    }
}

// MARK: - Session Snapshot
private struct SessionSnapshot: Codable {
    var groupId: String
    var groupType: String
    var activitySelectionBase64: String
    var startTime: Date
    var completedPomodoros: Int
    var totalPomodoros: Int
}
