//
//  AchievementManager.swift
//  ZenBound
//
//  成就管理器
//  负责成就的解锁和进度追踪
//

import SwiftData
import SwiftUI

/// 成就管理器
class AchievementManager: ObservableObject {
    // MARK: - Singleton
    static let shared = AchievementManager()
    
    // MARK: - Published Properties
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: Achievement?
    @Published var showUnlockAnimation: Bool = false
    
    private init() {}
    
    // MARK: - Achievement Loading
    
    /// 初始化成就系统
    func initializeAchievements(context: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        
        if let existingAchievements = try? context.fetch(descriptor), !existingAchievements.isEmpty {
            achievements = existingAchievements
        } else {
            // 首次运行，创建所有预设成就
            for achievementDef in AchievementDefinitions.allAchievements {
                context.insert(achievementDef)
                achievements.append(achievementDef)
            }
            print("[ZenBound] Initialized \(achievements.count) achievements")
        }
    }
    
    // MARK: - Progress Tracking
    
    /// 记录番茄钟完成
    func trackPomodoroComplete(context: ModelContext) {
        updateAchievementProgress("first_pomodoro", newProgress: 1, context: context)
        incrementAchievementProgress("ten_pomodoros", context: context)
        incrementAchievementProgress("fifty_pomodoros", context: context)
        incrementAchievementProgress("hundred_pomodoros", context: context)
        
        // 检查特殊成就
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 {
            updateAchievementProgress("early_bird", newProgress: 1, context: context)
        }
        if hour >= 22 {
            updateAchievementProgress("night_owl", newProgress: 1, context: context)
        }
    }
    
    /// 记录连续天数
    func trackStreak(days: Int, context: ModelContext) {
        updateAchievementProgress("three_day_streak", newProgress: days, context: context)
        updateAchievementProgress("seven_day_streak", newProgress: days, context: context)
        updateAchievementProgress("thirty_day_streak", newProgress: days, context: context)
    }
    
    /// 记录宠物等级
    func trackPetLevel(_ level: Int, context: ModelContext) {
        if level >= 1 {
            updateAchievementProgress("first_pet", newProgress: 1, context: context)
        }
        updateAchievementProgress("pet_level_5", newProgress: level, context: context)
        updateAchievementProgress("pet_level_10", newProgress: level, context: context)
    }
    
    /// 记录无干扰日
    func trackNoDistractionDay(context: ModelContext) {
        updateAchievementProgress("no_distraction", newProgress: 1, context: context)
    }
    
    // MARK: - Achievement Updates
    
    /// 更新成就进度
    func updateAchievementProgress(_ id: String, newProgress: Int, context: ModelContext) {
        guard let achievement = achievements.first(where: { $0.id == id }) else { return }
        
        if achievement.isUnlocked { return }
        
        let previousProgress = achievement.progress
        achievement.updateProgress(newProgress)
        
        // 检查是否刚解锁
        if !achievement.isUnlocked && achievement.progress >= achievement.target {
            unlockAchievement(achievement, context: context)
        } else if achievement.progress != previousProgress {
            print("[ZenBound] Achievement progress updated: \(achievement.title) (\(achievement.progress)/\(achievement.target))")
        }
    }
    
    /// 增加成就进度
    func incrementAchievementProgress(_ id: String, context: ModelContext) {
        guard let achievement = achievements.first(where: { $0.id == id }) else { return }
        
        if achievement.isUnlocked { return }
        
        updateAchievementProgress(id, newProgress: achievement.progress + 1, context: context)
    }
    
    /// 解锁成就
    private func unlockAchievement(_ achievement: Achievement, context: ModelContext) {
        achievement.unlock()
        recentlyUnlocked = achievement
        showUnlockAnimation = true
        
        // 发放奖励
        PetManager.shared.rewardForTaskComplete(
            coins: achievement.rewardCoins,
            experience: achievement.rewardExperience
        )
        
        print("[ZenBound] 🏆 Achievement unlocked: \(achievement.title)")
        
        // 3秒后隐藏动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUnlockAnimation = false
        }
    }
    
    // MARK: - Queries
    
    /// 获取已解锁成就数量
    var unlockedCount: Int {
        return achievements.filter { $0.isUnlocked }.count
    }
    
    /// 获取总成就数量
    var totalCount: Int {
        return achievements.count
    }
    
    /// 获取解锁进度
    var unlockProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
    
    /// 按分类获取成就
    func achievements(for category: AchievementCategory) -> [Achievement] {
        return achievements.filter { $0.category == category }
    }
    
    /// 获取最近解锁的成就
    func recentUnlocks(limit: Int = 5) -> [Achievement] {
        return achievements
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? Date.distantPast) > ($1.unlockedAt ?? Date.distantPast) }
            .prefix(limit)
            .map { $0 }
    }
}
