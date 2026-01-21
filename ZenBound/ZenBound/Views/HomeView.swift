//
//  HomeView.swift
//  ZenBound
//
//  主页视图 - 显示宠物状态、快速操作和应用组
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var petManager: PetManager
    @EnvironmentObject var taskManager: TaskManager
    
    @Query private var focusGroups: [FocusGroup]
    @Query private var strictGroups: [StrictGroup]
    @Query private var entertainmentGroups: [EntertainmentGroup]
    
    @State private var showCreateSheet = false
    @State private var selectedGroupType: SharedData.GroupType = .focus
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 宠物状态卡片
                    PetStatusCard()
                    
                    // 当前会话状态
                    if sessionManager.isSessionActive {
                        ActiveSessionCard()
                    }
                    
                    // 快速任务
                    QuickTasksSection()
                    
                    // 应用组列表
                    GroupListSection(
                        focusGroups: focusGroups,
                        strictGroups: strictGroups,
                        entertainmentGroups: entertainmentGroups,
                        onCreateGroup: { type in
                            selectedGroupType = type
                            showCreateSheet = true
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("ZenBound")
            .sheet(isPresented: $showCreateSheet) {
                CreateGroupSheet(groupType: selectedGroupType)
            }
        }
    }
}

// MARK: - Pet Status Card
struct PetStatusCard: View {
    @EnvironmentObject var petManager: PetManager
    
    var body: some View {
        NavigationLink(destination: PetView()) {
            HStack(spacing: 16) {
                // 宠物头像
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Text(petManager.currentPet?.species.emoji ?? "🐱")
                        .font(.system(size: 40))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(petManager.currentPet?.name ?? "小咪")
                            .font(.headline)
                        
                        Text("Lv.\(petManager.petLevel)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Text(petManager.petMoodDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 心情指示器
                    HStack(spacing: 4) {
                        Text(petManager.petMoodEmoji)
                        
                        ProgressView(value: Double(petManager.currentPet?.happiness ?? 50) / 100)
                            .tint(.pink)
                    }
                }
                
                Spacer()
                
                // 金币
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(petManager.petCoins)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Session Card
struct ActiveSessionCard: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(sessionManager.isBreak ? "休息中" : "专注中")
                        .font(.headline)
                    
                    Text(sessionTypeText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 计时器
                VStack {
                    Text(sessionManager.formattedRemainingTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(sessionManager.isBreak ? .green : .orange)
                    
                    Text("剩余时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 番茄钟进度（仅专注模式）
            if sessionManager.activeGroupType == .focus {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < sessionManager.currentPomodoroCount ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                    
                    Text("\(sessionManager.currentPomodoroCount)/4 番茄钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                if sessionManager.activeGroupType == .focus && !sessionManager.isBreak {
                    Button(action: {
                        sessionManager.startBreak()
                    }) {
                        Label("休息", systemImage: "cup.and.saucer.fill")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(20)
                    }
                }
                
                Button(action: {
                    sessionManager.stopCurrentSession(context: modelContext)
                }) {
                    Label("结束", systemImage: "stop.fill")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(sessionManager.isBreak ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
    
    var sessionTypeText: String {
        switch sessionManager.activeGroupType {
        case .focus: return "专注模式"
        case .strict: return "严格模式"
        case .entertainment: return "娱乐模式"
        case .none: return ""
        }
    }
}

// MARK: - Quick Tasks Section
struct QuickTasksSection: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日任务")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: TaskListView()) {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            
            if taskManager.dailyTasks.isEmpty {
                Text("今天没有任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(taskManager.dailyTasks.prefix(3), id: \.id) { task in
                    QuickTaskRow(task: task)
                }
            }
        }
    }
}

struct QuickTaskRow: View {
    let task: ZenTask
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        HStack {
            Button(action: {
                if !task.isCompleted {
                    taskManager.completeTask(task, context: modelContext)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isCompleted)
                
                if task.targetCount > 1 {
                    ProgressView(value: task.progress)
                        .tint(.purple)
                }
            }
            
            Spacer()
            
            if task.bonusTime > 0 {
                Label("+\(task.bonusTime)分钟", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Group List Section
struct GroupListSection: View {
    let focusGroups: [FocusGroup]
    let strictGroups: [StrictGroup]
    let entertainmentGroups: [EntertainmentGroup]
    let onCreateGroup: (SharedData.GroupType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("应用组")
                .font(.headline)
            
            // 专注组
            GroupTypeSection(
                title: "专注组",
                subtitle: "番茄工作法",
                icon: "timer",
                color: .orange,
                count: focusGroups.count,
                onTap: { onCreateGroup(.focus) }
            )
            
            ForEach(focusGroups, id: \.id) { group in
                NavigationLink(destination: FocusGroupConfigView(group: group)) {
                    GroupCard(name: group.name, icon: "timer", color: .orange, isActive: group.isActive)
                }
            }
            
            // 严格组
            GroupTypeSection(
                title: "严格组",
                subtitle: "时间限制",
                icon: "lock.fill",
                color: .red,
                count: strictGroups.count,
                onTap: { onCreateGroup(.strict) }
            )
            
            ForEach(strictGroups, id: \.id) { group in
                NavigationLink(destination: StrictGroupConfigView(group: group)) {
                    GroupCard(name: group.name, icon: "lock.fill", color: .red, isActive: group.isActive)
                }
            }
            
            // 娱乐组
            GroupTypeSection(
                title: "娱乐组",
                subtitle: "假期模式",
                icon: "gamecontroller.fill",
                color: .green,
                count: entertainmentGroups.count,
                onTap: { onCreateGroup(.entertainment) }
            )
            
            ForEach(entertainmentGroups, id: \.id) { group in
                NavigationLink(destination: EntertainmentGroupConfigView(group: group)) {
                    GroupCard(name: group.name, icon: "gamecontroller.fill", color: .green, isActive: group.isActive)
                }
            }
        }
    }
}

struct GroupTypeSection: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(count) 个")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: onTap) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, 8)
    }
}

struct GroupCard: View {
    let name: String
    let icon: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            if isActive {
                Text("运行中")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(10)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Create Group Sheet
struct CreateGroupSheet: View {
    let groupType: SharedData.GroupType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var groupName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("组名称", text: $groupName)
                }
                
                Section {
                    Text("创建后可以配置详细设置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("创建\(groupTypeTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createGroup()
                        dismiss()
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }
    
    var groupTypeTitle: String {
        switch groupType {
        case .focus: return "专注组"
        case .strict: return "严格组"
        case .entertainment: return "娱乐组"
        }
    }
    
    func createGroup() {
        switch groupType {
        case .focus:
            let group = FocusGroup(name: groupName)
            modelContext.insert(group)
        case .strict:
            let group = StrictGroup(name: groupName)
            modelContext.insert(group)
        case .entertainment:
            let group = EntertainmentGroup(name: groupName)
            modelContext.insert(group)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionManager.shared)
        .environmentObject(PetManager.shared)
        .environmentObject(TaskManager.shared)
        .modelContainer(for: [FocusGroup.self, StrictGroup.self, EntertainmentGroup.self])
}
