//
//  DeviceActivityMonitorExtension.swift
//  monitor
//
//  Created by Jack on 21/1/2026.
//

import DeviceActivity
import Foundation
import ManagedSettings
import FamilyControls

// MARK: - App Group Constants
private let appGroupID = "group.dev.zenbound.data"

// MARK: - SharedData Keys
private enum SharedDataKey {
    static let activeSession = "activeSessionSnapshot"
    static let focusGroups = "focusGroupsSnapshot"
    static let strictGroups = "strictGroupsSnapshot"
    static let entertainmentGroups = "entertainmentGroupsSnapshot"
    static let shieldConfig = "shieldConfigSnapshot"
}

// MARK: - Activity Names
extension DeviceActivityName {
    static let focusSession = DeviceActivityName("zenbound.focus")
    static let strictSession = DeviceActivityName("zenbound.strict")
    static let entertainmentSession = DeviceActivityName("zenbound.entertainment")
    static let breakTime = DeviceActivityName("zenbound.break")
}

// MARK: - Event Names
extension DeviceActivityEvent.Name {
    static let pomodoroComplete = DeviceActivityEvent.Name("zenbound.pomodoro.complete")
    static let breakComplete = DeviceActivityEvent.Name("zenbound.break.complete")
    static let sessionTimeUp = DeviceActivityEvent.Name("zenbound.session.timeup")
    static let reminderWarning = DeviceActivityEvent.Name("zenbound.reminder.warning")
}

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    private let store = ManagedSettingsStore(named: .zenbound)
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Interval Events
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        switch activity {
        case .focusSession:
            activateFocusRestrictions()
        case .strictSession:
            activateStrictRestrictions()
        case .entertainmentSession:
            activateEntertainmentRestrictions()
        case .breakTime:
            deactivateAllRestrictions()
        default:
            break
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        switch activity {
        case .focusSession, .strictSession, .entertainmentSession:
            deactivateAllRestrictions()
            updateSessionStatus(completed: true)
        case .breakTime:
            // Break ended, check if we should continue focus
            if shouldContinueFocus() {
                activateFocusRestrictions()
            }
        default:
            break
        }
    }
    
    // MARK: - Threshold Events
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        switch event {
        case .pomodoroComplete:
            handlePomodoroComplete()
        case .breakComplete:
            handleBreakComplete()
        case .sessionTimeUp:
            handleSessionTimeUp()
        default:
            break
        }
    }
    
    // MARK: - Warning Events
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Prepare for upcoming session
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        // Warn user session is about to end
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        
        switch event {
        case .reminderWarning:
            // Send reminder notification
            break
        default:
            break
        }
    }
    
    // MARK: - Restriction Helpers
    
    private func activateFocusRestrictions() {
        guard let activitySelection = loadCurrentActivitySelection() else { return }
        
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = .specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens
    }
    
    private func activateStrictRestrictions() {
        guard let activitySelection = loadCurrentActivitySelection() else { return }
        
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = .specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens
    }
    
    private func activateEntertainmentRestrictions() {
        guard let activitySelection = loadCurrentActivitySelection() else { return }
        
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = .specific(activitySelection.categoryTokens)
        store.shield.webDomains = activitySelection.webDomainTokens
    }
    
    private func deactivateAllRestrictions() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    // MARK: - Data Helpers
    
    private func loadCurrentActivitySelection() -> FamilyActivitySelection? {
        guard let data = userDefaults?.data(forKey: SharedDataKey.activeSession),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data) else {
            return nil
        }
        
        // Decode FamilyActivitySelection from snapshot
        guard let selectionData = Data(base64Encoded: snapshot.activitySelectionBase64),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: selectionData) else {
            return nil
        }
        
        return selection
    }
    
    private func shouldContinueFocus() -> Bool {
        guard let data = userDefaults?.data(forKey: SharedDataKey.activeSession),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data) else {
            return false
        }
        return snapshot.completedPomodoros < snapshot.totalPomodoros
    }
    
    private func updateSessionStatus(completed: Bool) {
        userDefaults?.set(completed, forKey: "sessionCompleted")
    }
    
    // MARK: - Event Handlers
    
    private func handlePomodoroComplete() {
        // Increment pomodoro count
        if var data = userDefaults?.data(forKey: SharedDataKey.activeSession),
           var snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data) {
            snapshot.completedPomodoros += 1
            if let encoded = try? JSONEncoder().encode(snapshot) {
                userDefaults?.set(encoded, forKey: SharedDataKey.activeSession)
            }
        }
        
        // Deactivate restrictions for break
        deactivateAllRestrictions()
    }
    
    private func handleBreakComplete() {
        // Resume focus restrictions after break
        if shouldContinueFocus() {
            activateFocusRestrictions()
        } else {
            deactivateAllRestrictions()
            updateSessionStatus(completed: true)
        }
    }
    
    private func handleSessionTimeUp() {
        deactivateAllRestrictions()
        updateSessionStatus(completed: true)
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

// MARK: - ManagedSettingsStore Name Extension
extension ManagedSettingsStore.Name {
    static let zenbound = ManagedSettingsStore.Name("zenbound")
}
