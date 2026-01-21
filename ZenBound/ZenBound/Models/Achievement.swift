//
//  Achievement.swift
//  ZenBound
//
//  成就系统模型
//

import Foundation
import SwiftData

// MARK: - 成就模型
@Model
class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var achievementDescription: String
    var category: AchievementCategory
    var iconName: String
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var progress: Int = 0
    var target: Int = 1
    var rewardCoins: Int = 0
    var rewardExperience: Int = 0
    
    var progressPercentage: Double {
        return Double(progress) / Double(target)
    }
    
    init(
        id: String,
        title: String,
        description: String,
        category: AchievementCategory,
        iconName: String,
        target: Int = 1,
        rewardCoins: Int = 50,
        rewardExperience: Int = 25
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.category = category
        self.iconName = iconName
        self.target = target
        self.rewardCoins = rewardCoins
        self.rewardExperience = rewardExperience
    }
    
    func updateProgress(_ newProgress: Int) {
        progress = min(target, newProgress)
        if progress >= target && !isUnlocked {
            unlock()
        }
    }
    
    func unlock() {
        isUnlocked = true
        unlockedAt = Date()
    }
    
    func toSnapshot() -> SharedData.AchievementSnapshot {
        return SharedData.AchievementSnapshot(
            id: id,
            title: title,
            description: achievementDescription,
            iconName: iconName,
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt,
            progress: progress,
            target: target
        )
    }
}

// MARK: - 成就分类
enum AchievementCategory: String, Codable, CaseIterable {
    case focus = "Focus"
    case streak = "Streak"
    case pet = "Pet"
    case social = "Social"
    case special = "Special"
    
    var displayName: String {
        switch self {
        case .focus: return "专注"
        case .streak: return "连续"
        case .pet: return "宠物"
        case .social: return "社交"
        case .special: return "特殊"
        }
    }
    
    var icon: String {
        switch self {
        case .focus: return "target"
        case .streak: return "flame.fill"
        case .pet: return "pawprint.fill"
        case .social: return "person.2.fill"
        case .special: return "star.fill"
        }
    }
}

// MARK: - 预设成就
enum AchievementDefinitions {
    // 专注类成就
    static let firstPomodoro = Achievement(
        id: "first_pomodoro",
        title: "初次尝试",
        description: "完成你的第一个番茄钟",
        category: .focus,
        iconName: "1.circle.fill",
        target: 1,
        rewardCoins: 20,
        rewardExperience: 10
    )
    
    static let tenPomodoros = Achievement(
        id: "ten_pomodoros",
        title: "专注新手",
        description: "完成10个番茄钟",
        category: .focus,
        iconName: "10.circle.fill",
        target: 10,
        rewardCoins: 50,
        rewardExperience: 30
    )
    
    static let fiftyPomodoros = Achievement(
        id: "fifty_pomodoros",
        title: "专注达人",
        description: "完成50个番茄钟",
        category: .focus,
        iconName: "50.circle.fill",
        target: 50,
        rewardCoins: 100,
        rewardExperience: 75
    )
    
    static let hundredPomodoros = Achievement(
        id: "hundred_pomodoros",
        title: "专注大师",
        description: "完成100个番茄钟",
        category: .focus,
        iconName: "100.circle.fill",
        target: 100,
        rewardCoins: 200,
        rewardExperience: 150
    )
    
    // 连续类成就
    static let threeDay = Achievement(
        id: "three_day_streak",
        title: "三日坚持",
        description: "连续3天完成任务",
        category: .streak,
        iconName: "flame",
        target: 3,
        rewardCoins: 30,
        rewardExperience: 20
    )
    
    static let sevenDay = Achievement(
        id: "seven_day_streak",
        title: "一周习惯",
        description: "连续7天完成任务",
        category: .streak,
        iconName: "flame.fill",
        target: 7,
        rewardCoins: 70,
        rewardExperience: 50
    )
    
    static let thirtyDay = Achievement(
        id: "thirty_day_streak",
        title: "月度坚持",
        description: "连续30天完成任务",
        category: .streak,
        iconName: "flame.circle.fill",
        target: 30,
        rewardCoins: 300,
        rewardExperience: 200
    )
    
    // 宠物类成就
    static let firstPet = Achievement(
        id: "first_pet",
        title: "新朋友",
        description: "领养你的第一只宠物",
        category: .pet,
        iconName: "pawprint",
        target: 1,
        rewardCoins: 20,
        rewardExperience: 10
    )
    
    static let petLevel5 = Achievement(
        id: "pet_level_5",
        title: "成长中",
        description: "将宠物升到5级",
        category: .pet,
        iconName: "arrow.up.circle.fill",
        target: 5,
        rewardCoins: 50,
        rewardExperience: 30
    )
    
    static let petLevel10 = Achievement(
        id: "pet_level_10",
        title: "亲密伙伴",
        description: "将宠物升到10级",
        category: .pet,
        iconName: "heart.circle.fill",
        target: 10,
        rewardCoins: 100,
        rewardExperience: 75
    )
    
    // 特殊成就
    static let earlyBird = Achievement(
        id: "early_bird",
        title: "早起鸟儿",
        description: "在早上6点前开始专注",
        category: .special,
        iconName: "sunrise.fill",
        target: 1,
        rewardCoins: 30,
        rewardExperience: 20
    )
    
    static let nightOwl = Achievement(
        id: "night_owl",
        title: "夜猫子",
        description: "在晚上10点后完成番茄钟",
        category: .special,
        iconName: "moon.stars.fill",
        target: 1,
        rewardCoins: 30,
        rewardExperience: 20
    )
    
    static let noDistraction = Achievement(
        id: "no_distraction",
        title: "心无旁骛",
        description: "一整天没有被 Shield 打断",
        category: .special,
        iconName: "checkmark.shield.fill",
        target: 1,
        rewardCoins: 50,
        rewardExperience: 30
    )
    
    // 所有预设成就
    static var allAchievements: [Achievement] {
        return [
            firstPomodoro,
            tenPomodoros,
            fiftyPomodoros,
            hundredPomodoros,
            threeDay,
            sevenDay,
            thirtyDay,
            firstPet,
            petLevel5,
            petLevel10,
            earlyBird,
            nightOwl,
            noDistraction
        ]
    }
}
