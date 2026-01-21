//
//  Task.swift
//  ZenBound
//
//  任务系统模型
//

import Foundation
import SwiftData

// MARK: - 任务模型
@Model
class ZenTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskDescription: String
    var type: TaskType
    var category: TaskCategory
    var status: TaskStatus
    var reward: Int              // 金币奖励
    var experienceReward: Int    // 经验奖励
    var bonusTime: Int           // 额外娱乐时间（分钟）
    var createdAt: Date
    var completedAt: Date?
    var expiresAt: Date?
    var targetCount: Int = 1
    var currentCount: Int = 0
    
    var isCompleted: Bool {
        return status == .completed
    }
    
    var isExpired: Bool {
        if let expires = expiresAt {
            return Date() > expires
        }
        return false
    }
    
    var progress: Double {
        return Double(currentCount) / Double(targetCount)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: TaskType,
        category: TaskCategory = .general,
        reward: Int = 10,
        experienceReward: Int = 5,
        bonusTime: Int = 0,
        targetCount: Int = 1,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = description
        self.type = type
        self.category = category
        self.status = .pending
        self.reward = reward
        self.experienceReward = experienceReward
        self.bonusTime = bonusTime
        self.targetCount = targetCount
        self.createdAt = Date()
        self.expiresAt = expiresAt
    }
    
    func incrementProgress() {
        currentCount = min(targetCount, currentCount + 1)
        if currentCount >= targetCount {
            complete()
        }
    }
    
    func complete() {
        status = .completed
        completedAt = Date()
    }
    
    func toSnapshot() -> SharedData.TaskSnapshot {
        return SharedData.TaskSnapshot(
            id: id,
            title: title,
            description: taskDescription,
            type: SharedData.TaskType(rawValue: type.rawValue) ?? .oneTime,
            status: SharedData.TaskStatus(rawValue: status.rawValue) ?? .pending,
            reward: reward,
            createdAt: createdAt,
            completedAt: completedAt,
            expiresAt: expiresAt
        )
    }
}

// MARK: - 任务类型
enum TaskType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case oneTime = "oneTime"
    case activity = "activity"
    
    var displayName: String {
        switch self {
        case .daily: return "每日任务"
        case .weekly: return "每周任务"
        case .oneTime: return "一次性任务"
        case .activity: return "活动任务"
        }
    }
}

// MARK: - 任务分类
enum TaskCategory: String, Codable, CaseIterable {
    case general = "General"
    case focus = "Focus"
    case health = "Health"
    case learning = "Learning"
    case social = "Social"
    case creativity = "Creativity"
    
    var displayName: String {
        switch self {
        case .general: return "通用"
        case .focus: return "专注"
        case .health: return "健康"
        case .learning: return "学习"
        case .social: return "社交"
        case .creativity: return "创意"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "star.fill"
        case .focus: return "target"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .social: return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        }
    }
}

// MARK: - 任务状态
enum TaskStatus: String, Codable {
    case pending = "pending"
    case inProgress = "inProgress"
    case completed = "completed"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "待完成"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .expired: return "已过期"
        }
    }
}

// MARK: - 预设任务模板
enum TaskTemplate {
    static func dailyFocusTask() -> ZenTask {
        return ZenTask(
            title: "完成一个番茄钟",
            description: "专注25分钟，完成一个完整的番茄钟周期",
            type: .daily,
            category: .focus,
            reward: 20,
            experienceReward: 15,
            bonusTime: 5,
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
    }
    
    static func dailyExerciseTask() -> ZenTask {
        return ZenTask(
            title: "做运动休息",
            description: "在休息时间完成简单的伸展运动",
            type: .daily,
            category: .health,
            reward: 15,
            experienceReward: 10,
            bonusTime: 5,
            expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
    }
    
    static func weeklyStreakTask() -> ZenTask {
        return ZenTask(
            title: "连续专注7天",
            description: "连续7天每天完成至少一个番茄钟",
            type: .weekly,
            category: .focus,
            reward: 100,
            experienceReward: 50,
            targetCount: 7,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
    }
    
    static func breathingExerciseTask() -> ZenTask {
        return ZenTask(
            title: "完成呼吸练习",
            description: "当看到 Shield 时，完成一次呼吸练习",
            type: .activity,
            category: .health,
            reward: 10,
            experienceReward: 5,
            bonusTime: 10
        )
    }
    
    static func mathDrillTask() -> ZenTask {
        return ZenTask(
            title: "数学练习",
            description: "完成一组数学题目",
            type: .activity,
            category: .learning,
            reward: 15,
            experienceReward: 10,
            bonusTime: 15
        )
    }
    
    static func vocabularyTask() -> ZenTask {
        return ZenTask(
            title: "词汇记忆",
            description: "学习并记忆10个新单词",
            type: .activity,
            category: .learning,
            reward: 15,
            experienceReward: 10,
            bonusTime: 15
        )
    }
}
