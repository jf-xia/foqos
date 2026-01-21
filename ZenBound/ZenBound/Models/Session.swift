//
//  Session.swift
//  ZenBound
//
//  会话记录模型
//

import Foundation
import SwiftData

// MARK: - 专注会话
@Model
class FocusSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var completedPomodoros: Int = 0
    var totalFocusTime: TimeInterval = 0
    var totalBreakTime: TimeInterval = 0
    var wasInterrupted: Bool = false
    
    @Relationship var focusGroup: FocusGroup?
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    init(
        id: UUID = UUID(),
        focusGroup: FocusGroup
    ) {
        self.id = id
        self.startTime = Date()
        self.focusGroup = focusGroup
    }
    
    func end() {
        self.endTime = Date()
        self.totalFocusTime = duration - totalBreakTime
    }
}

// MARK: - 严格模式会话
@Model
class StrictSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var usedTime: TimeInterval = 0
    var blockedAttempts: Int = 0
    var emergencyUnlocksUsed: Int = 0
    
    @Relationship var strictGroup: StrictGroup?
    
    init(
        id: UUID = UUID(),
        strictGroup: StrictGroup
    ) {
        self.id = id
        self.date = Date()
        self.strictGroup = strictGroup
    }
    
    func addUsedTime(_ time: TimeInterval) {
        usedTime += time
    }
    
    var remainingDailyTime: TimeInterval {
        guard let group = strictGroup else { return 0 }
        let limit = TimeInterval(group.dailyTimeLimit * 60)
        return max(0, limit - usedTime)
    }
}

// MARK: - 娱乐会话
@Model
class EntertainmentSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var usedTime: TimeInterval = 0
    var extensionsUsed: Int = 0
    var tasksCompleted: [String] = []
    var bonusTimeEarned: TimeInterval = 0
    
    @Relationship var entertainmentGroup: EntertainmentGroup?
    
    init(
        id: UUID = UUID(),
        entertainmentGroup: EntertainmentGroup
    ) {
        self.id = id
        self.date = Date()
        self.entertainmentGroup = entertainmentGroup
    }
    
    func addUsedTime(_ time: TimeInterval) {
        usedTime += time
    }
    
    func completeTask(_ taskType: String, bonusMinutes: Int) {
        tasksCompleted.append(taskType)
        bonusTimeEarned += TimeInterval(bonusMinutes * 60)
    }
    
    var remainingDailyTime: TimeInterval {
        guard let group = entertainmentGroup else { return 0 }
        let limit = TimeInterval(group.dailyTimeLimit * 60) + bonusTimeEarned
        return max(0, limit - usedTime)
    }
    
    var canExtend: Bool {
        guard let group = entertainmentGroup else { return false }
        return group.allowExtension && extensionsUsed < group.extensionCount
    }
}
