//
//  Pet.swift
//  ZenBound
//
//  宠物猫模型和状态管理
//

import Foundation
import SwiftData

// MARK: - 宠物猫模型
@Model
class Pet {
    @Attribute(.unique) var id: UUID
    var name: String
    var species: PetSpecies
    var appearance: PetAppearance
    
    // 状态属性
    var happiness: Int = 50          // 0-100
    var health: Int = 100            // 0-100
    var energy: Int = 100            // 0-100
    
    // 成长属性
    var level: Int = 1
    var experience: Int = 0
    var coins: Int = 0
    
    // 时间戳
    var lastFedTime: Date?
    var lastPlayedTime: Date?
    var lastPettedTime: Date?
    var createdAt: Date
    
    // 解锁的技能
    var unlockedSkills: [String] = []
    
    // 拥有的物品
    var inventory: [String] = []
    
    init(
        id: UUID = UUID(),
        name: String = "小咪",
        species: PetSpecies = .cat
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.appearance = PetAppearance()
        self.createdAt = Date()
    }
    
    // MARK: - 状态计算
    
    var mood: PetMood {
        if happiness >= 80 { return .happy }
        if happiness >= 60 { return .content }
        if happiness >= 40 { return .neutral }
        if happiness >= 20 { return .sad }
        return .unhappy
    }
    
    var experienceToNextLevel: Int {
        return level * 100
    }
    
    var levelProgress: Double {
        return Double(experience) / Double(experienceToNextLevel)
    }
    
    // MARK: - 交互方法
    
    func feed() {
        happiness = min(100, happiness + 10)
        health = min(100, health + 5)
        lastFedTime = Date()
        addExperience(5)
    }
    
    func play() {
        happiness = min(100, happiness + 15)
        energy = max(0, energy - 10)
        lastPlayedTime = Date()
        addExperience(10)
    }
    
    func pet() {
        happiness = min(100, happiness + 5)
        lastPettedTime = Date()
        addExperience(2)
    }
    
    func rest() {
        energy = min(100, energy + 20)
        health = min(100, health + 5)
    }
    
    func addExperience(_ exp: Int) {
        experience += exp
        while experience >= experienceToNextLevel {
            experience -= experienceToNextLevel
            levelUp()
        }
    }
    
    func addCoins(_ amount: Int) {
        coins += amount
    }
    
    private func levelUp() {
        level += 1
        happiness = min(100, happiness + 20)
        // 解锁新技能
        checkSkillUnlocks()
    }
    
    private func checkSkillUnlocks() {
        for skill in PetSkill.allCases {
            if skill.unlockLevel <= level && !unlockedSkills.contains(skill.rawValue) {
                unlockedSkills.append(skill.rawValue)
            }
        }
    }
    
    // MARK: - 时间流逝影响
    
    func updateForTimeElapsed() {
        let now = Date()
        
        // 检查上次喂食时间
        if let lastFed = lastFedTime {
            let hoursSinceFeeding = now.timeIntervalSince(lastFed) / 3600
            if hoursSinceFeeding > 8 {
                happiness = max(0, happiness - Int(hoursSinceFeeding - 8) * 2)
            }
        }
        
        // 能量恢复
        if let lastPlayed = lastPlayedTime {
            let hoursSincePlay = now.timeIntervalSince(lastPlayed) / 3600
            if hoursSincePlay > 2 {
                energy = min(100, energy + Int(hoursSincePlay - 2) * 5)
            }
        }
    }
    
    func toSnapshot() -> SharedData.PetStateSnapshot {
        return SharedData.PetStateSnapshot(
            happiness: happiness,
            health: health,
            level: level,
            experience: experience,
            coins: coins,
            unlockedSkills: unlockedSkills,
            lastFedTime: lastFedTime,
            lastPlayedTime: lastPlayedTime
        )
    }
}

// MARK: - 宠物种类
enum PetSpecies: String, Codable, CaseIterable {
    case cat = "Cat"
    case dog = "Dog"
    case rabbit = "Rabbit"
    case hamster = "Hamster"
    
    var displayName: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .cat: return "🐱"
        case .dog: return "🐕"
        case .rabbit: return "🐰"
        case .hamster: return "🐹"
        }
    }
}

// MARK: - 宠物心情
enum PetMood: String, CaseIterable {
    case happy = "Happy"
    case content = "Content"
    case neutral = "Neutral"
    case sad = "Sad"
    case unhappy = "Unhappy"
    
    var emoji: String {
        switch self {
        case .happy: return "😸"
        case .content: return "😺"
        case .neutral: return "😐"
        case .sad: return "😿"
        case .unhappy: return "🙀"
        }
    }
    
    var description: String {
        switch self {
        case .happy: return "非常开心！"
        case .content: return "心情不错"
        case .neutral: return "还行吧"
        case .sad: return "有点难过"
        case .unhappy: return "需要关爱"
        }
    }
}

// MARK: - 宠物外观
struct PetAppearance: Codable {
    var colorHex: String = "#FFB347"
    var accessory: String?
    var background: String = "default"
}

// MARK: - 宠物技能
enum PetSkill: String, CaseIterable {
    case encouragement = "Encouragement"
    case focusBoost = "Focus Boost"
    case breakReminder = "Break Reminder"
    case celebration = "Celebration"
    case meditation = "Meditation Guide"
    case morningGreeting = "Morning Greeting"
    case nighttimeRoutine = "Nighttime Routine"
    
    var displayName: String {
        switch self {
        case .encouragement: return "鼓励话语"
        case .focusBoost: return "专注加成"
        case .breakReminder: return "休息提醒"
        case .celebration: return "成就庆祝"
        case .meditation: return "冥想引导"
        case .morningGreeting: return "早安问候"
        case .nighttimeRoutine: return "晚安仪式"
        }
    }
    
    var description: String {
        switch self {
        case .encouragement: return "在专注时给予鼓励"
        case .focusBoost: return "增加专注时获得的经验"
        case .breakReminder: return "温柔地提醒休息"
        case .celebration: return "完成任务时庆祝动画"
        case .meditation: return "引导呼吸练习"
        case .morningGreeting: return "每天早上打招呼"
        case .nighttimeRoutine: return "睡前放松提醒"
        }
    }
    
    var unlockLevel: Int {
        switch self {
        case .encouragement: return 1
        case .focusBoost: return 3
        case .breakReminder: return 5
        case .celebration: return 7
        case .meditation: return 10
        case .morningGreeting: return 12
        case .nighttimeRoutine: return 15
        }
    }
    
    var icon: String {
        switch self {
        case .encouragement: return "quote.bubble"
        case .focusBoost: return "bolt.fill"
        case .breakReminder: return "bell.fill"
        case .celebration: return "party.popper"
        case .meditation: return "leaf.fill"
        case .morningGreeting: return "sun.max.fill"
        case .nighttimeRoutine: return "moon.stars.fill"
        }
    }
}
