//
//  TaskListView.swift
//  ZenBound
//
//  任务列表视图
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedFilter: TaskFilter = .all
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 统计卡片
                TaskStatsCard()
                    .padding()
                
                // 过滤器
                TaskFilterBar(selectedFilter: $selectedFilter)
                
                // 任务列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        switch selectedFilter {
                        case .all:
                            AllTasksSection()
                        case .daily:
                            TaskSection(title: "每日任务", tasks: taskManager.dailyTasks)
                        case .weekly:
                            TaskSection(title: "每周任务", tasks: taskManager.weeklyTasks)
                        case .activity:
                            ActivityTasksSection()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("任务")
            .onAppear {
                taskManager.loadTasks(context: modelContext)
            }
        }
    }
}

// MARK: - Task Stats Card
struct TaskStatsCard: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                title: "今日完成",
                value: "\(taskManager.completedToday)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "待完成",
                value: "\(taskManager.pendingTasksCount)",
                icon: "clock.fill",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "完成率",
                value: "\(Int(taskManager.todayCompletionRate * 100))%",
                icon: "chart.pie.fill",
                color: .purple
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Task Filter Bar
enum TaskFilter: String, CaseIterable {
    case all = "全部"
    case daily = "每日"
    case weekly = "每周"
    case activity = "活动"
}

struct TaskFilterBar: View {
    @Binding var selectedFilter: TaskFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - All Tasks Section
struct AllTasksSection: View {
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        VStack(spacing: 16) {
            if !taskManager.dailyTasks.isEmpty {
                TaskSection(title: "每日任务", tasks: taskManager.dailyTasks)
            }
            
            if !taskManager.weeklyTasks.isEmpty {
                TaskSection(title: "每周任务", tasks: taskManager.weeklyTasks)
            }
            
            if !taskManager.activityTasks.isEmpty {
                TaskSection(title: "活动任务", tasks: taskManager.activityTasks)
            }
        }
    }
}

// MARK: - Task Section
struct TaskSection: View {
    let title: String
    let tasks: [ZenTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(tasks.filter { $0.isCompleted }.count)/\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(tasks, id: \.id) { task in
                TaskRow(task: task)
            }
        }
    }
}

struct TaskRow: View {
    let task: ZenTask
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        HStack(spacing: 12) {
            // 完成按钮
            Button(action: {
                if !task.isCompleted {
                    if task.targetCount > 1 {
                        taskManager.updateTaskProgress(task, context: modelContext)
                    } else {
                        taskManager.completeTask(task, context: modelContext)
                    }
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            // 任务信息
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                
                Text(task.taskDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // 进度条（多目标任务）
                if task.targetCount > 1 {
                    HStack {
                        ProgressView(value: task.progress)
                            .tint(.purple)
                        
                        Text("\(task.currentCount)/\(task.targetCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 奖励
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("+\(task.reward)")
                        .font(.caption)
                }
                
                if task.bonusTime > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("+\(task.bonusTime)分")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        .opacity(task.isCompleted ? 0.7 : 1)
    }
}

// MARK: - Activity Tasks Section
struct ActivityTasksSection: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("活动任务")
                .font(.headline)
            
            Text("完成活动任务可以获得额外的娱乐时间")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ActivityTaskType.allCases, id: \.rawValue) { taskType in
                    ActivityTaskCard(taskType: taskType) {
                        let _ = taskManager.generateActivityTask(type: taskType, context: modelContext)
                    }
                }
            }
        }
    }
}

struct ActivityTaskCard: View {
    let taskType: ActivityTaskType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: taskType.icon)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 50, height: 50)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                
                Text(taskType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TaskListView()
        .environmentObject(TaskManager.shared)
}
