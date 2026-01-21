//
//  SessionManager.swift
//  ZenBound
//
//  会话管理协调器
//  负责管理所有类型的会话生命周期
//

import SwiftData
import SwiftUI
import WidgetKit

/// 会话管理器
/// 核心业务逻辑：管理所有屏蔽会话和策略
class SessionManager: ObservableObject {
    // MARK: - Singleton
    static let shared = SessionManager()
    
    // MARK: - Published Properties
    @Published var activeGroupType: SharedData.GroupType?
    @Published var activeGroupId: UUID?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isBreak: Bool = false
    @Published var currentPomodoroCount: Int = 0
    @Published var remainingTime: TimeInterval = 0
    
    // MARK: - Private Properties
    private var timer: Timer?
    private let appBlocker = AppBlockerUtil()
    
    private init() {}
    
    // MARK: - Session Control
    
    /// 开始专注会话
    func startFocusSession(group: FocusGroup, context: ModelContext) {
        print("[ZenBound] Starting focus session for: \(group.name)")
        
        // 保存快照到 App Group
        let snapshot = group.toSnapshot()
        SharedData.setFocusGroup(snapshot)
        
        // 创建会话
        let session = FocusSession(focusGroup: group)
        context.insert(session)
        
        // 激活限制
        appBlocker.activateFocusRestrictions(for: snapshot)
        
        // 更新状态
        activeGroupType = .focus
        activeGroupId = group.id
        currentPomodoroCount = 0
        isBreak = false
        remainingTime = TimeInterval(group.pomodoroDuration * 60)
        
        // 开始计时
        startTimer()
        
        // 同步到 SharedData
        SharedData.startSession(groupType: .focus, groupId: group.id)
        
        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 开始严格模式会话
    func startStrictSession(group: StrictGroup, context: ModelContext) {
        print("[ZenBound] Starting strict session for: \(group.name)")
        
        // 保存快照到 App Group
        let snapshot = group.toSnapshot()
        SharedData.setStrictGroup(snapshot)
        
        // 创建会话
        let session = StrictSession(strictGroup: group)
        context.insert(session)
        
        // 激活限制
        appBlocker.activateStrictRestrictions(for: snapshot)
        
        // 更新状态
        activeGroupType = .strict
        activeGroupId = group.id
        remainingTime = TimeInterval(group.dailyTimeLimit * 60)
        
        // 开始计时
        startTimer()
        
        // 同步到 SharedData
        SharedData.startSession(groupType: .strict, groupId: group.id)
        
        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 开始娱乐会话
    func startEntertainmentSession(group: EntertainmentGroup, context: ModelContext) {
        print("[ZenBound] Starting entertainment session for: \(group.name)")
        
        // 检查今天是否允许娱乐
        guard group.isEntertainmentAllowedToday() else {
            print("[ZenBound] Entertainment not allowed today")
            return
        }
        
        // 保存快照到 App Group
        let snapshot = group.toSnapshot()
        SharedData.setEntertainmentGroup(snapshot)
        
        // 创建会话
        let session = EntertainmentSession(entertainmentGroup: group)
        context.insert(session)
        
        // 激活限制
        appBlocker.activateEntertainmentRestrictions(for: snapshot)
        
        // 更新状态
        activeGroupType = .entertainment
        activeGroupId = group.id
        remainingTime = TimeInterval(group.dailyTimeLimit * 60)
        
        // 开始计时
        startTimer()
        
        // 同步到 SharedData
        SharedData.startSession(groupType: .entertainment, groupId: group.id)
        
        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 停止当前会话
    func stopCurrentSession(context: ModelContext) {
        print("[ZenBound] Stopping current session")
        
        // 停止计时
        stopTimer()
        
        // 解除限制
        appBlocker.deactivateAllRestrictions()
        
        // 清除状态
        activeGroupType = nil
        activeGroupId = nil
        elapsedTime = 0
        remainingTime = 0
        isBreak = false
        currentPomodoroCount = 0
        
        // 结束 SharedData 会话
        SharedData.endSession()
        
        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Break Control
    
    /// 开始休息
    func startBreak() {
        guard let groupType = activeGroupType, groupType == .focus else { return }
        
        print("[ZenBound] Starting break")
        isBreak = true
        
        // 临时解除限制
        appBlocker.temporarilyDeactivate()
        
        // 获取休息时长
        if let groupId = activeGroupId,
           let group = SharedData.getFocusGroup(id: groupId.uuidString) {
            remainingTime = TimeInterval(group.breakDuration * 60)
        }
    }
    
    /// 结束休息
    func endBreak() {
        guard let groupType = activeGroupType, groupType == .focus else { return }
        
        print("[ZenBound] Ending break")
        isBreak = false
        currentPomodoroCount += 1
        SharedData.incrementPomodoroCount()
        
        // 恢复限制
        if let groupId = activeGroupId {
            appBlocker.restoreRestrictions(groupType: .focus, groupId: groupId.uuidString)
            
            // 设置下一个番茄钟时间
            if let group = SharedData.getFocusGroup(id: groupId.uuidString) {
                remainingTime = TimeInterval(group.pomodoroDuration * 60)
            }
        }
        
        // 奖励宠物经验
        SharedData.addPetExperience(10)
        SharedData.updatePetHappiness(delta: 5)
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func timerTick() {
        elapsedTime += 1
        
        if remainingTime > 0 {
            remainingTime -= 1
            
            // 检查是否完成
            if remainingTime <= 0 {
                handleTimerComplete()
            }
        }
    }
    
    private func handleTimerComplete() {
        guard let groupType = activeGroupType else { return }
        
        switch groupType {
        case .focus:
            if isBreak {
                endBreak()
            } else {
                // 番茄钟完成，开始休息
                startBreak()
            }
        case .strict, .entertainment:
            // 时间用完，保持屏蔽
            print("[ZenBound] Time limit reached")
        }
    }
    
    // MARK: - Emergency Unlock
    
    /// 紧急解锁
    func emergencyUnlock(context: ModelContext) {
        guard let groupType = activeGroupType else { return }
        
        print("[ZenBound] Emergency unlock requested")
        
        // 临时解除限制
        appBlocker.temporarilyDeactivate()
        
        // 更新使用次数
        if groupType == .strict, let groupId = activeGroupId {
            if var group = SharedData.getStrictGroup(id: groupId.uuidString) {
                // 注意：这里需要更新数据库中的 StrictGroup
                print("[ZenBound] Emergency unlock used, remaining: \(group.emergencyUnlockCount - 1)")
            }
        }
    }
    
    // MARK: - Extension Time
    
    /// 延长使用时间
    func extendTime(minutes: Int) {
        guard let groupType = activeGroupType, groupType == .entertainment else { return }
        
        print("[ZenBound] Extending time by \(minutes) minutes")
        remainingTime += TimeInterval(minutes * 60)
    }
    
    // MARK: - Computed Properties
    
    var isSessionActive: Bool {
        return activeGroupType != nil
    }
    
    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
