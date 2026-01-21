//
//  SharedData.swift
//  ZenBound
//
//  屏幕时间管理应用的跨进程数据共享层
//  用于主 App 与 Extensions (monitor/shieldConfig/shieldAction/widget) 之间的通信
//

import FamilyControls
import Foundation

// MARK: - App Group 常量
enum AppGroupConfig {
    static let suiteName = "group.dev.zenbound.data"
}

// MARK: - SharedData 命名空间
enum SharedData {
    private static let suite = UserDefaults(suiteName: AppGroupConfig.suiteName)!
    
    // MARK: - Keys
    private enum Key: String {
        // 应用组配置快照
        case groupModeSnapshots
        // 当前活动会话
        case activeSession
        // 已完成会话历史
        case completedSessions
        // 宠物状态
        case petState
        // 任务列表
        case tasks
        // 成就进度
        case achievements
        // Shield 配置
        case shieldConfig
    }
    
    // MARK: - 应用组模式快照 (Group Mode Snapshots)
    
    /// 专注组配置快照
    struct FocusGroupSnapshot: Codable, Equatable {
        var id: UUID
        var name: String
        var isActive: Bool
        var selectedActivity: FamilyActivitySelection
        
        // 番茄钟设置
        var pomodoroDuration: Int = 25  // 分钟
        var breakDuration: Int = 5       // 分钟
        var pomodoroCount: Int = 3       // 周期数
        
        // 专注限制
        var disableNotifications: Bool = true
        var blockAllApps: Bool = false
        var blockAppSwitching: Bool = false
        var requirePhotoCheck: Bool = false
        var reminderBeforeEnd: Bool = true
        var reminderBeforeBreakEnd: Bool = true
        var extraTimePerPomodoro: Int = 5  // 分钟
        
        // Shield 主题
        var shieldTitle: String = "Focus Time!"
        var shieldMessage: String = "Take a deep breath"
        var shieldColorHex: String = "#4A90D9"
    }
    
    /// 严格组配置快照
    struct StrictGroupSnapshot: Codable, Equatable {
        var id: UUID
        var name: String
        var isActive: Bool
        var selectedActivity: FamilyActivitySelection
        var blockedWebsites: [String] = []
        var blockedKeywords: [String] = []
        
        // 时间限制
        var dailyTimeLimit: Int = 60     // 分钟
        var singleSessionLimit: Int = 15 // 分钟
        
        // 时间表
        var alwaysActive: Bool = true
        var schedules: [ScheduleSnapshot] = []
        
        // 其他设置
        var enableEmergencyUnlock: Bool = false
        var blockAppStoreInstall: Bool = false
        var emergencyUnlockCount: Int = 3
        
        // Shield 主题
        var shieldTitle: String = "Daily limit reached"
        var shieldMessage: String = "Come back tomorrow"
        var shieldColorHex: String = "#E74C3C"
    }
    
    /// 娱乐组配置快照
    struct EntertainmentGroupSnapshot: Codable, Equatable {
        var id: UUID
        var name: String
        var isActive: Bool
        var selectedActivity: FamilyActivitySelection
        
        // 假期选择
        var enableWeekends: Bool = true
        var holidayDates: [Date] = []
        var customDates: [Date] = []
        
        // 娱乐限制
        var dailyTimeLimit: Int = 120    // 分钟
        var singleSessionLimit: Int = 30 // 分钟
        var allowExtension: Bool = true
        var extensionCount: Int = 2
        var extensionDuration: Int = 10  // 分钟
        
        // 休息屏蔽
        var enableRestBlock: Bool = true
        var blockAllAppsWhenRest: Bool = false
        var restReminderInterval: Int = 60  // 分钟
        var restReminderMessage: String = "Time to take a break!"
        
        // 活动任务
        var enableActivityTasks: Bool = true
        var selectedTasks: [String] = []
        var extraTimePerTask: Int = 10   // 分钟
        
        // Shield 主题
        var shieldTitle: String = "Enjoy your time!"
        var shieldMessage: String = "Remember to take breaks!"
        var shieldColorHex: String = "#27AE60"
    }
    
    /// 时间表快照
    struct ScheduleSnapshot: Codable, Equatable {
        var startTime: DateComponents
        var endTime: DateComponents
        var selectedDays: [Int] = [1, 2, 3, 4, 5, 6, 7]  // 1=周日, 7=周六
    }
    
    // MARK: - 会话快照
    struct SessionSnapshot: Codable, Equatable {
        var id: String
        var groupType: GroupType
        var groupId: UUID
        var startTime: Date
        var endTime: Date?
        var pauseTime: Date?
        var totalPauseDuration: TimeInterval = 0
        var pomodoroCount: Int = 0
        var isBreak: Bool = false
    }
    
    enum GroupType: String, Codable {
        case focus
        case strict
        case entertainment
    }
    
    // MARK: - 宠物状态快照
    struct PetStateSnapshot: Codable, Equatable {
        var happiness: Int = 50       // 0-100
        var health: Int = 100         // 0-100
        var level: Int = 1
        var experience: Int = 0
        var coins: Int = 0
        var unlockedSkills: [String] = []
        var lastFedTime: Date?
        var lastPlayedTime: Date?
    }
    
    // MARK: - 任务快照
    struct TaskSnapshot: Codable, Equatable {
        var id: UUID
        var title: String
        var description: String
        var type: TaskType
        var status: TaskStatus
        var reward: Int
        var createdAt: Date
        var completedAt: Date?
        var expiresAt: Date?
    }
    
    enum TaskType: String, Codable {
        case daily
        case weekly
        case oneTime
        case activity
    }
    
    enum TaskStatus: String, Codable {
        case pending
        case inProgress
        case completed
        case expired
    }
    
    // MARK: - 成就快照
    struct AchievementSnapshot: Codable, Equatable {
        var id: String
        var title: String
        var description: String
        var iconName: String
        var isUnlocked: Bool
        var unlockedAt: Date?
        var progress: Int = 0
        var target: Int = 1
    }
    
    // MARK: - Shield 配置快照
    struct ShieldConfigSnapshot: Codable, Equatable {
        var title: String
        var message: String
        var primaryButtonText: String
        var secondaryButtonText: String?
        var colorHex: String
        var emojiIcon: String
        var groupType: GroupType
        
        // 可用操作
        var allowOpenApp: Bool = true
        var allowBreathingExercise: Bool = true
        var allowInputIntent: Bool = true
        var allowAlternativeApp: Bool = true
        var allowCompleteTodo: Bool = false
    }
    
    // MARK: - 存取方法
    
    // Focus Group
    static var focusGroups: [String: FocusGroupSnapshot] {
        get {
            guard let data = suite.data(forKey: Key.groupModeSnapshots.rawValue + "_focus") else { return [:] }
            return (try? JSONDecoder().decode([String: FocusGroupSnapshot].self, from: data)) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: Key.groupModeSnapshots.rawValue + "_focus")
            }
        }
    }
    
    static func setFocusGroup(_ snapshot: FocusGroupSnapshot) {
        var all = focusGroups
        all[snapshot.id.uuidString] = snapshot
        focusGroups = all
    }
    
    static func getFocusGroup(id: String) -> FocusGroupSnapshot? {
        return focusGroups[id]
    }
    
    // Strict Group
    static var strictGroups: [String: StrictGroupSnapshot] {
        get {
            guard let data = suite.data(forKey: Key.groupModeSnapshots.rawValue + "_strict") else { return [:] }
            return (try? JSONDecoder().decode([String: StrictGroupSnapshot].self, from: data)) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: Key.groupModeSnapshots.rawValue + "_strict")
            }
        }
    }
    
    static func setStrictGroup(_ snapshot: StrictGroupSnapshot) {
        var all = strictGroups
        all[snapshot.id.uuidString] = snapshot
        strictGroups = all
    }
    
    static func getStrictGroup(id: String) -> StrictGroupSnapshot? {
        return strictGroups[id]
    }
    
    // Entertainment Group
    static var entertainmentGroups: [String: EntertainmentGroupSnapshot] {
        get {
            guard let data = suite.data(forKey: Key.groupModeSnapshots.rawValue + "_entertainment") else { return [:] }
            return (try? JSONDecoder().decode([String: EntertainmentGroupSnapshot].self, from: data)) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: Key.groupModeSnapshots.rawValue + "_entertainment")
            }
        }
    }
    
    static func setEntertainmentGroup(_ snapshot: EntertainmentGroupSnapshot) {
        var all = entertainmentGroups
        all[snapshot.id.uuidString] = snapshot
        entertainmentGroups = all
    }
    
    static func getEntertainmentGroup(id: String) -> EntertainmentGroupSnapshot? {
        return entertainmentGroups[id]
    }
    
    // Active Session
    static var activeSession: SessionSnapshot? {
        get {
            guard let data = suite.data(forKey: Key.activeSession.rawValue) else { return nil }
            return try? JSONDecoder().decode(SessionSnapshot.self, from: data)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: Key.activeSession.rawValue)
            } else {
                suite.removeObject(forKey: Key.activeSession.rawValue)
            }
        }
    }
    
    // Pet State
    static var petState: PetStateSnapshot {
        get {
            guard let data = suite.data(forKey: Key.petState.rawValue) else {
                return PetStateSnapshot()
            }
            return (try? JSONDecoder().decode(PetStateSnapshot.self, from: data)) ?? PetStateSnapshot()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: Key.petState.rawValue)
            }
        }
    }
    
    // Shield Config
    static var shieldConfig: ShieldConfigSnapshot? {
        get {
            guard let data = suite.data(forKey: Key.shieldConfig.rawValue) else { return nil }
            return try? JSONDecoder().decode(ShieldConfigSnapshot.self, from: data)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: Key.shieldConfig.rawValue)
            } else {
                suite.removeObject(forKey: Key.shieldConfig.rawValue)
            }
        }
    }
    
    // MARK: - 便捷方法
    
    static func startSession(groupType: GroupType, groupId: UUID) {
        activeSession = SessionSnapshot(
            id: UUID().uuidString,
            groupType: groupType,
            groupId: groupId,
            startTime: Date()
        )
    }
    
    static func endSession() {
        guard var session = activeSession else { return }
        session.endTime = Date()
        activeSession = nil
    }
    
    static func incrementPomodoroCount() {
        guard var session = activeSession else { return }
        session.pomodoroCount += 1
        activeSession = session
    }
    
    static func updatePetHappiness(delta: Int) {
        var pet = petState
        pet.happiness = max(0, min(100, pet.happiness + delta))
        petState = pet
    }
    
    static func addPetExperience(_ exp: Int) {
        var pet = petState
        pet.experience += exp
        // 简单的升级逻辑
        let expNeeded = pet.level * 100
        if pet.experience >= expNeeded {
            pet.level += 1
            pet.experience -= expNeeded
        }
        petState = pet
    }
}
