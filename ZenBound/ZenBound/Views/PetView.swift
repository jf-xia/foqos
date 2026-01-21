//
//  PetView.swift
//  ZenBound
//
//  宠物视图 - 显示宠物详情、技能和互动
//

import SwiftUI
import SwiftData

struct PetView: View {
    @EnvironmentObject var petManager: PetManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var showFeedAnimation = false
    @State private var showPlayAnimation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 宠物展示区
                    PetDisplayArea()
                    
                    // 状态条
                    PetStatusBars()
                    
                    // 互动按钮
                    PetInteractionButtons()
                    
                    // 技能列表
                    PetSkillsList()
                }
                .padding()
            }
            .navigationTitle("我的宠物")
            .overlay {
                // 鼓励消息
                if petManager.showEncouragement {
                    EncouragementOverlay(message: petManager.encouragementMessage)
                }
            }
        }
    }
}

// MARK: - Pet Display Area
struct PetDisplayArea: View {
    @EnvironmentObject var petManager: PetManager
    
    var body: some View {
        VStack(spacing: 16) {
            // 宠物动画区域
            ZStack {
                // 背景
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // 宠物表情
                Text(petManager.currentPet?.species.emoji ?? "🐱")
                    .font(.system(size: 100))
                
                // 心情气泡
                Text(petManager.petMoodEmoji)
                    .font(.system(size: 30))
                    .offset(x: 60, y: -60)
            }
            
            // 名字和等级
            VStack(spacing: 4) {
                Text(petManager.currentPet?.name ?? "小咪")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    Label("Lv.\(petManager.petLevel)", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Label("\(petManager.petCoins)", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                }
            }
            
            // 经验条
            VStack(spacing: 4) {
                ProgressView(value: petManager.currentPet?.levelProgress ?? 0)
                    .tint(.purple)
                
                Text("\(petManager.currentPet?.experience ?? 0)/\(petManager.currentPet?.experienceToNextLevel ?? 100) EXP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Pet Status Bars
struct PetStatusBars: View {
    @EnvironmentObject var petManager: PetManager
    
    var body: some View {
        VStack(spacing: 12) {
            StatusBar(
                title: "快乐度",
                icon: "heart.fill",
                value: Double(petManager.currentPet?.happiness ?? 50) / 100,
                color: .pink
            )
            
            StatusBar(
                title: "健康度",
                icon: "cross.fill",
                value: Double(petManager.currentPet?.health ?? 100) / 100,
                color: .green
            )
            
            StatusBar(
                title: "能量",
                icon: "bolt.fill",
                value: Double(petManager.currentPet?.energy ?? 100) / 100,
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct StatusBar: View {
    let title: String
    let icon: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            
            ProgressView(value: value)
                .tint(color)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40)
        }
    }
}

// MARK: - Pet Interaction Buttons
struct PetInteractionButtons: View {
    @EnvironmentObject var petManager: PetManager
    
    var body: some View {
        HStack(spacing: 20) {
            InteractionButton(
                title: "喂食",
                icon: "fork.knife",
                color: .orange,
                action: { petManager.feedPet() }
            )
            
            InteractionButton(
                title: "玩耍",
                icon: "figure.play",
                color: .purple,
                action: { petManager.playWithPet() }
            )
            
            InteractionButton(
                title: "抚摸",
                icon: "hand.raised.fill",
                color: .pink,
                action: { petManager.petThePet() }
            )
        }
    }
}

struct InteractionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .cornerRadius(16)
                    .scaleEffect(isPressed ? 1.1 : 1.0)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pet Skills List
struct PetSkillsList: View {
    @EnvironmentObject var petManager: PetManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("宠物技能")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PetSkill.allCases, id: \.rawValue) { skill in
                    SkillCard(
                        skill: skill,
                        isUnlocked: petManager.currentPet?.unlockedSkills.contains(skill.rawValue) ?? false
                    )
                }
            }
        }
    }
}

struct SkillCard: View {
    let skill: PetSkill
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: skill.icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? .purple : .gray)
            }
            
            Text(skill.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if !isUnlocked {
                Text("Lv.\(skill.unlockLevel) 解锁")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

// MARK: - Encouragement Overlay
struct EncouragementOverlay: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(message)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.purple)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .transition(.scale.combined(with: .opacity))
            
            Spacer()
        }
    }
}

#Preview {
    PetView()
        .environmentObject(PetManager.shared)
}
