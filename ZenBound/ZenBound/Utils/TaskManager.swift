//
//  TaskManager.swift
//  ZenBound
//
//  任务管理器
//  负责任务的创建、更新和完成逻辑
//

import SwiftData
import SwiftUI

/// 任务管理器
class TaskManager: ObservableObject {
    // MARK: - Singleton
    static let shared = TaskManager()
    
    // MARK: - Published Properties
    @Published var dailyTasks: [Task] = []
    @Published var weeklyTasks: [Task] = []
    @Published var activityTasks: [Task] = []
    @Published var completedToday: Int = 0
    
    private init() {}
    
    // MARK: - Task Loading
    
    /// 加载所有任务
    func loadTasks(context: ModelContext) {
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        // 获取所有任务
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        guard let allTasks = try? context.fetch(descriptor) else { return }
        
        // 过滤任务
        dailyTasks = allTasks.filter { $0.type == .daily && !$0.isExpired }
        weeklyTasks = allTasks.filter { $0.type == .weekly && !$0.isExpired }
        activityTasks = allTasks.filter { $0.type == .activity && !$0.isCompleted }
        
        // 计算今天完成的任务
        completedToday = allTasks.filter {
            $0.isCompleted &&
            $0.completedAt != nil &&
            calendar.isDate($0.completedAt!, inSameDayAs: now)
        }.count
        
        // 检查是否需要生成新的每日任务
        checkAndGenerateDailyTasks(context: context)
    }
    
    // MARK: - Task Generation
    
    /// 检查并生成每日任务
    func checkAndGenerateDailyTasks(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        
        // 检查今天是否已有每日任务
        let hasDailyTask = dailyTasks.contains {
            calendar.isDate($0.createdAt, inSameDayAs: now)
        }
        
        if !hasDailyTask {
            generateDailyTasks(context: context)
        }
        
        // 检查本周是否已有每周任务
        let hasWeeklyTask = weeklyTasks.contains {
            calendar.isDate($0.createdAt, equalTo: now, toGranularity: .weekOfYear)
        }
        
        if !hasWeeklyTask {
            generateWeeklyTasks(context: context)
        }
    }
    
    /// 生成每日任务
    func generateDailyTasks(context: ModelContext) {
        let tasks = [
            TaskTemplate.dailyFocusTask(),
            TaskTemplate.dailyExerciseTask()
        ]
        
        for task in tasks {
            context.insert(task)
            dailyTasks.append(task)
        }
        
        print("[ZenBound] Generated \(tasks.count) daily tasks")
    }
    
    /// 生成每周任务
    func generateWeeklyTasks(context: ModelContext) {
        let task = TaskTemplate.weeklyStreakTask()
        context.insert(task)
        weeklyTasks.append(task)
        
        print("[ZenBound] Generated weekly task")
    }
    
    /// 生成活动任务
    func generateActivityTask(type: ActivityTaskType, context: ModelContext) -> Task {
        let task: Task
        
        switch type {
        case .physicalExercise:
            task = TaskTemplate.dailyExerciseTask()
        case .knowledgeQuiz:
            task = Task(
                title: "知识问答",
                description: "回答一组知识问题",
                type: .activity,
                category: .learning,
                reward: 15,
                experienceReward: 10,
                bonusTime: 15
            )
        case .wishBottle:
            task = Task(
                title: "许愿瓶",
                description: "写下你的一个愿望",
                type: .activity,
                category: .creativity,
                reward: 10,
                experienceReward: 5,
                bonusTime: 5
            )
        case .emotionDiary:
            task = Task(
                title: "情绪日记",
                description: "记录今天的心情",
                type: .activity,
                category: .health,
                reward: 10,
                experienceReward: 5,
                bonusTime: 10
            )
        case .cooperativeTasks:
            task = Task(
                title: "合作任务",
                description: "和家人一起完成一个任务",
                type: .activity,
                category: .social,
                reward: 20,
                experienceReward: 15,
                bonusTime: 20
            )
        case .mathDrills:
            task = TaskTemplate.mathDrillTask()
        case .vocabularyMemorization:
            task = TaskTemplate.vocabularyTask()
        }
        
        context.insert(task)
        activityTasks.append(task)
        
        return task
    }
    
    // MARK: - Task Completion
    
    /// 完成任务
    func completeTask(_ task: Task, context: ModelContext) {
        task.complete()
        completedToday += 1
        
        // 发放奖励
        PetManager.shared.rewardForTaskComplete(
            coins: task.reward,
            experience: task.experienceReward
        )
        
        // 如果有额外时间奖励，更新会话管理器
        if task.bonusTime > 0 {
            SessionManager.shared.extendTime(minutes: task.bonusTime)
        }
        
        print("[ZenBound] Task completed: \(task.title)")
        
        // 刷新任务列表
        loadTasks(context: context)
    }
    
    /// 更新任务进度
    func updateTaskProgress(_ task: Task, context: ModelContext) {
        task.incrementProgress()
        
        if task.isCompleted {
            completeTask(task, context: context)
        }
        
        print("[ZenBound] Task progress updated: \(task.title) (\(task.currentCount)/\(task.targetCount))")
    }
    
    // MARK: - Task Queries
    
    /// 获取待完成任务数量
    var pendingTasksCount: Int {
        return dailyTasks.filter { !$0.isCompleted }.count +
               weeklyTasks.filter { !$0.isCompleted }.count
    }
    
    /// 获取今日完成率
    var todayCompletionRate: Double {
        let totalDaily = dailyTasks.count
        guard totalDaily > 0 else { return 0 }
        
        let completedDaily = dailyTasks.filter { $0.isCompleted }.count
        return Double(completedDaily) / Double(totalDaily)
    }
    
    /// 获取本周完成率
    var weeklyCompletionRate: Double {
        let totalWeekly = weeklyTasks.count
        guard totalWeekly > 0 else { return 0 }
        
        let completedWeekly = weeklyTasks.filter { $0.isCompleted }.count
        return Double(completedWeekly) / Double(totalWeekly)
    }
}
