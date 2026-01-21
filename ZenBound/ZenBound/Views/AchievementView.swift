//
//  AchievementView.swift
//  ZenBound
//
//  成就视图
//

import SwiftUI
import SwiftData

struct AchievementView: View {
    @EnvironmentObject var achievementManager: AchievementManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedCategory: AchievementCategory?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 进度概览
                    AchievementProgressCard()
                    
                    // 最近解锁
                    RecentUnlocksSection()
                    
                    // 分类选择
                    CategoryFilterSection(selectedCategory: $selectedCategory)
                    
                    // 成就列表
                    AchievementGridSection(selectedCategory: selectedCategory)
                }
                .padding()
            }
            .navigationTitle("成就")
            .overlay {
                // 解锁动画
                if achievementManager.showUnlockAnimation,
                   let achievement = achievementManager.recentlyUnlocked {
                    AchievementUnlockOverlay(achievement: achievement)
                }
            }
        }
    }
}

// MARK: - Achievement Progress Card
struct AchievementProgressCard: View {
    @EnvironmentObject var achievementManager: AchievementManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("成就进度")
                        .font(.headline)
                    
                    Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount) 已解锁")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: achievementManager.unlockProgress)
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(achievementManager.unlockProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
            }
            
            // 分类进度
            HStack(spacing: 16) {
                ForEach(AchievementCategory.allCases.prefix(4), id: \.self) { category in
                    CategoryProgressItem(category: category)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct CategoryProgressItem: View {
    let category: AchievementCategory
    @EnvironmentObject var achievementManager: AchievementManager
    
    var categoryAchievements: [Achievement] {
        achievementManager.achievements(for: category)
    }
    
    var unlockedCount: Int {
        categoryAchievements.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: category.icon)
                .foregroundColor(.purple)
            
            Text("\(unlockedCount)/\(categoryAchievements.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Unlocks Section
struct RecentUnlocksSection: View {
    @EnvironmentObject var achievementManager: AchievementManager
    
    var recentUnlocks: [Achievement] {
        achievementManager.recentUnlocks(limit: 3)
    }
    
    var body: some View {
        if !recentUnlocks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("最近解锁")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentUnlocks, id: \.id) { achievement in
                            RecentUnlockCard(achievement: achievement)
                        }
                    }
                }
            }
        }
    }
}

struct RecentUnlockCard: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let date = achievement.unlockedAt {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Category Filter Section
struct CategoryFilterSection: View {
    @Binding var selectedCategory: AchievementCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
}

// MARK: - Achievement Grid Section
struct AchievementGridSection: View {
    let selectedCategory: AchievementCategory?
    @EnvironmentObject var achievementManager: AchievementManager
    
    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievementManager.achievements(for: category)
        }
        return achievementManager.achievements
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(filteredAchievements, id: \.id) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .purple : .gray)
                
                // 锁定图标
                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .offset(x: 20, y: 20)
                }
            }
            
            // 标题
            Text(achievement.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            // 描述
            Text(achievement.achievementDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // 进度（未解锁时显示）
            if !achievement.isUnlocked && achievement.target > 1 {
                VStack(spacing: 4) {
                    ProgressView(value: achievement.progressPercentage)
                        .tint(.purple)
                    
                    Text("\(achievement.progress)/\(achievement.target)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 奖励
            if achievement.isUnlocked {
                HStack(spacing: 8) {
                    Label("+\(achievement.rewardCoins)", systemImage: "dollarsign.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Label("+\(achievement.rewardExperience)", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.isUnlocked ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .opacity(achievement.isUnlocked ? 1 : 0.7)
    }
}

// MARK: - Achievement Unlock Overlay
struct AchievementUnlockOverlay: View {
    let achievement: Achievement
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 图标
                Image(systemName: achievement.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                    .padding(30)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                
                Text("🎉 成就解锁!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(achievement.achievementDescription)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // 奖励
                HStack(spacing: 20) {
                    Label("+\(achievement.rewardCoins)", systemImage: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    
                    Label("+\(achievement.rewardExperience) EXP", systemImage: "star.fill")
                        .foregroundColor(.orange)
                }
                .font(.headline)
            }
            .padding(40)
        }
        .transition(.opacity)
    }
}

#Preview {
    AchievementView()
        .environmentObject(AchievementManager.shared)
}
