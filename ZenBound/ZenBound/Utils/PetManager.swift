//
//  PetManager.swift
//  ZenBound
//
//  宠物管理器
//  负责宠物状态更新、奖励发放和技能触发
//

import Combine
import SwiftData
import SwiftUI

/// 宠物管理器
class PetManager: ObservableObject {
    // MARK: - Singleton
    static let shared = PetManager()
    
    // MARK: - Published Properties
    @Published var currentPet: Pet?
    @Published var showEncouragement: Bool = false
    @Published var encouragementMessage: String = ""
    
    private init() {}
    
    // MARK: - Pet Initialization
    
    /// 初始化或加载宠物
    func loadOrCreatePet(context: ModelContext) {
        let descriptor = FetchDescriptor<Pet>()
        
        if let existingPet = try? context.fetch(descriptor).first {
            currentPet = existingPet
            existingPet.updateForTimeElapsed()
        } else {
            let newPet = Pet(name: "小咪")
            context.insert(newPet)
            currentPet = newPet
        }
        
        // 同步到 SharedData
        if let pet = currentPet {
            SharedData.petState = pet.toSnapshot()
        }
    }
    
    // MARK: - Rewards
    
    /// 完成番茄钟奖励
    func rewardForPomodoroComplete() {
        guard let pet = currentPet else { return }
        
        pet.addExperience(15)
        pet.addCoins(10)
        pet.happiness = min(100, pet.happiness + 5)
        
        syncToSharedData()
        
        // 触发庆祝动画（如果解锁了技能）
        if pet.unlockedSkills.contains(PetSkill.celebration.rawValue) {
            triggerCelebration()
        }
    }
    
    /// 完成任务奖励
    func rewardForTaskComplete(coins: Int, experience: Int) {
        guard let pet = currentPet else { return }
        
        pet.addExperience(experience)
        pet.addCoins(coins)
        pet.happiness = min(100, pet.happiness + 3)
        
        syncToSharedData()
    }
    
    /// 连续打卡奖励
    func rewardForStreak(days: Int) {
        guard let pet = currentPet else { return }
        
        let bonus = days * 5
        pet.addExperience(bonus)
        pet.addCoins(bonus * 2)
        
        syncToSharedData()
    }
    
    // MARK: - Pet Interactions
    
    /// 喂养宠物
    func feedPet() {
        guard let pet = currentPet else { return }
        pet.feed()
        syncToSharedData()
    }
    
    /// 和宠物玩耍
    func playWithPet() {
        guard let pet = currentPet else { return }
        pet.play()
        syncToSharedData()
    }
    
    /// 抚摸宠物
    func petThePet() {
        guard let pet = currentPet else { return }
        pet.pet()
        syncToSharedData()
    }
    
    // MARK: - Skill Triggers
    
    /// 触发鼓励话语
    func triggerEncouragement() {
        guard let pet = currentPet,
              pet.unlockedSkills.contains(PetSkill.encouragement.rawValue) else { return }
        
        let messages = [
            "加油！你做得很棒！",
            "继续保持专注！",
            "我相信你！",
            "你是最棒的！",
            "再坚持一会儿！",
            "💪 冲冲冲！"
        ]
        
        encouragementMessage = messages.randomElement() ?? "加油！"
        showEncouragement = true
        
        // 3秒后隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showEncouragement = false
        }
    }
    
    /// 触发庆祝动画
    func triggerCelebration() {
        // TODO: 实现庆祝动画
        print("[ZenBound] 🎉 Celebration triggered!")
    }
    
    /// 触发呼吸引导
    func triggerMeditationGuide() -> [String]? {
        guard let pet = currentPet,
              pet.unlockedSkills.contains(PetSkill.meditation.rawValue) else { return nil }
        
        return [
            "深呼吸...",
            "吸气... 1... 2... 3... 4...",
            "屏住... 1... 2... 3... 4...",
            "呼气... 1... 2... 3... 4... 5... 6...",
            "很好，再来一次..."
        ]
    }
    
    /// 获取早安问候
    func getMorningGreeting() -> String? {
        guard let pet = currentPet,
              pet.unlockedSkills.contains(PetSkill.morningGreeting.rawValue) else { return nil }
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 5 && hour < 12 {
            let greetings = [
                "早安！新的一天开始了！",
                "早上好！今天也要加油哦！",
                "早安！准备好开始新的一天了吗？"
            ]
            return greetings.randomElement()
        }
        
        return nil
    }
    
    /// 获取晚安提醒
    func getNightRoutineReminder() -> String? {
        guard let pet = currentPet,
              pet.unlockedSkills.contains(PetSkill.nighttimeRoutine.rawValue) else { return nil }
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 21 || hour < 5 {
            let reminders = [
                "该休息了，明天继续加油！",
                "晚安！好好睡觉哦！",
                "今天辛苦了，早点休息吧！"
            ]
            return reminders.randomElement()
        }
        
        return nil
    }
    
    // MARK: - Sync
    
    private func syncToSharedData() {
        guard let pet = currentPet else { return }
        SharedData.petState = pet.toSnapshot()
    }
    
    // MARK: - Computed Properties
    
    var petMoodEmoji: String {
        return currentPet?.mood.emoji ?? "😺"
    }
    
    var petMoodDescription: String {
        return currentPet?.mood.description ?? ""
    }
    
    var petLevel: Int {
        return currentPet?.level ?? 1
    }
    
    var petCoins: Int {
        return currentPet?.coins ?? 0
    }
}
