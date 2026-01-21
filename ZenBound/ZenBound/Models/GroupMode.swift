//
//  GroupMode.swift
//  ZenBound
//
//  应用组模式的 SwiftData 模型定义
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import SwiftData

// MARK: - 专注组模型 (Focus Group)
/// 使用番茄工作法，强制用户在使用一段时间后休息
@Model
class FocusGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var isActive: Bool = false
    var selectedActivity: FamilyActivitySelection
    var createdAt: Date
    var updatedAt: Date
    var order: Int = 0
    
    // 番茄钟设置
    var pomodoroDuration: Int = 25      // 分钟 (15/25/30/45/custom)
    var breakDuration: Int = 5          // 分钟 (5/10/15/custom)
    var pomodoroCount: Int = 3          // 周期数 (1/2/3/4/custom)
    
    // 专注限制设置
    var disableNotifications: Bool = true
    var blockAllApps: Bool = false
    var blockAppSwitching: Bool = false
    var requirePhotoCheck: Bool = false
    var reminderBeforeEnd: Bool = true           // 番茄结束前5分钟提醒
    var reminderBeforeBreakEnd: Bool = true      // 休息结束前1分钟提醒
    var extraTimePerPomodoro: Int = 5            // 完成番茄后获取额外娱乐时间
    
    // Shield 主题设置
    var shieldTitle: String = "Focus Time!"
    var shieldMessage: String = "Take a deep breath"
    var shieldColorHex: String = "#4A90D9"
    var shieldEmoji: String = "🎯"
    
    // 关联会话
    @Relationship var sessions: [FocusSession] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
        pomodoroDuration: Int = 25,
        breakDuration: Int = 5,
        pomodoroCount: Int = 3
    ) {
        self.id = id
        self.name = name
        self.selectedActivity = selectedActivity
        self.createdAt = Date()
        self.updatedAt = Date()
        self.pomodoroDuration = pomodoroDuration
        self.breakDuration = breakDuration
        self.pomodoroCount = pomodoroCount
    }
    
    func toSnapshot() -> SharedData.FocusGroupSnapshot {
        return SharedData.FocusGroupSnapshot(
            id: id,
            name: name,
            isActive: isActive,
            selectedActivity: selectedActivity,
            pomodoroDuration: pomodoroDuration,
            breakDuration: breakDuration,
            pomodoroCount: pomodoroCount,
            disableNotifications: disableNotifications,
            blockAllApps: blockAllApps,
            blockAppSwitching: blockAppSwitching,
            requirePhotoCheck: requirePhotoCheck,
            reminderBeforeEnd: reminderBeforeEnd,
            reminderBeforeBreakEnd: reminderBeforeBreakEnd,
            extraTimePerPomodoro: extraTimePerPomodoro,
            shieldTitle: shieldTitle,
            shieldMessage: shieldMessage,
            shieldColorHex: shieldColorHex
        )
    }
}

// MARK: - 严格组模型 (Strict Group)
/// 限制 App 当天的使用时间范围和使用时长
@Model
class StrictGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var isActive: Bool = false
    var selectedActivity: FamilyActivitySelection
    var blockedWebsites: [String] = []
    var blockedKeywords: [String] = []
    var createdAt: Date
    var updatedAt: Date
    var order: Int = 0
    
    // 时间限制
    var dailyTimeLimit: Int = 60         // 分钟 (5/10/15/30/45/60/90/120/custom)
    var singleSessionLimit: Int = 15     // 分钟 (5/10/15/30/custom)
    
    // 时间表
    var alwaysActive: Bool = true
    var schedules: [GroupSchedule]?
    
    // 其他设置
    var enableEmergencyUnlock: Bool = false
    var blockAppStoreInstall: Bool = false
    var emergencyUnlockCount: Int = 3    // 非娱乐app紧急使用次数
    var emergencyUnlocksUsed: Int = 0
    
    // Shield 主题设置
    var shieldTitle: String = "Daily limit reached"
    var shieldMessage: String = "Come back tomorrow"
    var shieldColorHex: String = "#E74C3C"
    var shieldEmoji: String = "⏰"
    
    // 关联会话
    @Relationship var sessions: [StrictSession] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
        dailyTimeLimit: Int = 60,
        singleSessionLimit: Int = 15
    ) {
        self.id = id
        self.name = name
        self.selectedActivity = selectedActivity
        self.createdAt = Date()
        self.updatedAt = Date()
        self.dailyTimeLimit = dailyTimeLimit
        self.singleSessionLimit = singleSessionLimit
    }
    
    func toSnapshot() -> SharedData.StrictGroupSnapshot {
        return SharedData.StrictGroupSnapshot(
            id: id,
            name: name,
            isActive: isActive,
            selectedActivity: selectedActivity,
            blockedWebsites: blockedWebsites,
            blockedKeywords: blockedKeywords,
            dailyTimeLimit: dailyTimeLimit,
            singleSessionLimit: singleSessionLimit,
            alwaysActive: alwaysActive,
            schedules: schedules?.map { $0.toSnapshot() } ?? [],
            enableEmergencyUnlock: enableEmergencyUnlock,
            blockAppStoreInstall: blockAppStoreInstall,
            emergencyUnlockCount: emergencyUnlockCount,
            shieldTitle: shieldTitle,
            shieldMessage: shieldMessage,
            shieldColorHex: shieldColorHex
        )
    }
    
    var remainingEmergencyUnlocks: Int {
        return max(0, emergencyUnlockCount - emergencyUnlocksUsed)
    }
}

// MARK: - 娱乐组模型 (Entertainment Group)
/// 支持设置週末或假期 App 每日总使用时长
@Model
class EntertainmentGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var isActive: Bool = false
    var selectedActivity: FamilyActivitySelection
    var createdAt: Date
    var updatedAt: Date
    var order: Int = 0
    
    // 假期选择
    var enableWeekends: Bool = true
    var holidayDates: [Date] = []
    var customDates: [Date] = []
    
    // 娱乐限制
    var dailyTimeLimit: Int = 120        // 分钟 (60/90/120/180/custom)
    var singleSessionLimit: Int = 30     // 分钟 (10/15/30/custom)
    var allowExtension: Bool = true
    var extensionCount: Int = 2          // 延长时间次数
    var extensionDuration: Int = 10      // 每次延长时间 (分钟)
    var extensionsUsedToday: Int = 0
    
    // 休息屏蔽
    var enableRestBlock: Bool = true
    var blockAllAppsWhenRest: Bool = false
    var restReminderInterval: Int = 60   // 分钟 (30/60/90/custom)
    var restReminderMessage: String = "Time to take a break!"
    
    // 活动任务
    var enableActivityTasks: Bool = true
    var selectedTasks: [String] = []     // 任务类型列表
    var extraTimePerTask: Int = 10       // 分钟 (5/10/15/custom)
    
    // Shield 主题设置
    var shieldTitle: String = "Enjoy your time!"
    var shieldMessage: String = "Remember to take breaks!"
    var shieldColorHex: String = "#27AE60"
    var shieldEmoji: String = "🎮"
    
    // 关联会话
    @Relationship var sessions: [EntertainmentSession] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
        dailyTimeLimit: Int = 120,
        singleSessionLimit: Int = 30
    ) {
        self.id = id
        self.name = name
        self.selectedActivity = selectedActivity
        self.createdAt = Date()
        self.updatedAt = Date()
        self.dailyTimeLimit = dailyTimeLimit
        self.singleSessionLimit = singleSessionLimit
    }
    
    func toSnapshot() -> SharedData.EntertainmentGroupSnapshot {
        return SharedData.EntertainmentGroupSnapshot(
            id: id,
            name: name,
            isActive: isActive,
            selectedActivity: selectedActivity,
            enableWeekends: enableWeekends,
            holidayDates: holidayDates,
            customDates: customDates,
            dailyTimeLimit: dailyTimeLimit,
            singleSessionLimit: singleSessionLimit,
            allowExtension: allowExtension,
            extensionCount: extensionCount,
            extensionDuration: extensionDuration,
            enableRestBlock: enableRestBlock,
            blockAllAppsWhenRest: blockAllAppsWhenRest,
            restReminderInterval: restReminderInterval,
            restReminderMessage: restReminderMessage,
            enableActivityTasks: enableActivityTasks,
            selectedTasks: selectedTasks,
            extraTimePerTask: extraTimePerTask,
            shieldTitle: shieldTitle,
            shieldMessage: shieldMessage,
            shieldColorHex: shieldColorHex
        )
    }
    
    var remainingExtensions: Int {
        return max(0, extensionCount - extensionsUsedToday)
    }
    
    /// 检查今天是否是允许娱乐的日子
    func isEntertainmentAllowedToday() -> Bool {
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        
        // 检查周末
        if enableWeekends && (weekday == 1 || weekday == 7) {
            return true
        }
        
        // 检查假期
        if holidayDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            return true
        }
        
        // 检查自定义日期
        if customDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            return true
        }
        
        return false
    }
}

// MARK: - 时间表模型
@Model
class GroupSchedule {
    @Attribute(.unique) var id: UUID
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var selectedDays: [Int] = [1, 2, 3, 4, 5, 6, 7]  // 1=周日, 7=周六
    
    init(
        id: UUID = UUID(),
        startHour: Int = 9,
        startMinute: Int = 0,
        endHour: Int = 17,
        endMinute: Int = 0,
        selectedDays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    ) {
        self.id = id
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.selectedDays = selectedDays
    }
    
    func toSnapshot() -> SharedData.ScheduleSnapshot {
        return SharedData.ScheduleSnapshot(
            startTime: DateComponents(hour: startHour, minute: startMinute),
            endTime: DateComponents(hour: endHour, minute: endMinute),
            selectedDays: selectedDays
        )
    }
}

// MARK: - 活动任务类型
enum ActivityTaskType: String, CaseIterable, Codable {
    case physicalExercise = "Physical Exercise"
    case knowledgeQuiz = "Knowledge Quiz"
    case wishBottle = "Wish Bottle"
    case emotionDiary = "Emotion Diary"
    case cooperativeTasks = "Cooperative Tasks"
    case mathDrills = "Math Drills"
    case vocabularyMemorization = "Vocabulary Memorization"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .physicalExercise: return "figure.run"
        case .knowledgeQuiz: return "brain.head.profile"
        case .wishBottle: return "sparkles"
        case .emotionDiary: return "heart.text.square"
        case .cooperativeTasks: return "person.2"
        case .mathDrills: return "plus.forwardslash.minus"
        case .vocabularyMemorization: return "textformat.abc"
        }
    }
}
