//
//  DeviceActivityUtil.swift
//  ZenBound
//
//  设备活动监控中心工具类
//  封装 DeviceActivityCenter，管理和调度设备活动监控任务
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// 设备活动工具类
/// 负责注册和管理所有的设备活动监控任务
class DeviceActivityUtil {
    
    // MARK: - Activity Names
    
    /// 获取专注组的活动名称
    static func focusActivityName(for groupId: UUID) -> DeviceActivityName {
        return DeviceActivityName("zenbound.focus.\(groupId.uuidString)")
    }
    
    /// 获取严格组的活动名称
    static func strictActivityName(for groupId: UUID) -> DeviceActivityName {
        return DeviceActivityName("zenbound.strict.\(groupId.uuidString)")
    }
    
    /// 获取娱乐组的活动名称
    static func entertainmentActivityName(for groupId: UUID) -> DeviceActivityName {
        return DeviceActivityName("zenbound.entertainment.\(groupId.uuidString)")
    }
    
    /// 获取休息的活动名称
    static func breakActivityName(for groupId: UUID) -> DeviceActivityName {
        return DeviceActivityName("zenbound.break.\(groupId.uuidString)")
    }
    
    /// 获取番茄钟的活动名称
    static func pomodoroActivityName(for groupId: UUID, cycle: Int) -> DeviceActivityName {
        return DeviceActivityName("zenbound.pomodoro.\(groupId.uuidString).\(cycle)")
    }
    
    // MARK: - Focus Group Scheduling
    
    /// 启动番茄钟计时活动
    static func startPomodoroActivity(for group: FocusGroup) {
        let center = DeviceActivityCenter()
        let activityName = pomodoroActivityName(for: group.id, cycle: 0)
        
        let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
            from: group.pomodoroDuration
        )
        
        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: false
        )
        
        do {
            stopActivity(activityName, with: center)
            try center.startMonitoring(activityName, during: schedule)
            print("[ZenBound] Pomodoro activity scheduled: \(group.pomodoroDuration) minutes")
        } catch {
            print("[ZenBound] Failed to start pomodoro activity: \(error)")
        }
    }
    
    /// 启动休息计时活动
    static func startBreakActivity(for group: FocusGroup) {
        let center = DeviceActivityCenter()
        let activityName = breakActivityName(for: group.id)
        
        let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
            from: group.breakDuration
        )
        
        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: false
        )
        
        do {
            stopActivity(activityName, with: center)
            try center.startMonitoring(activityName, during: schedule)
            print("[ZenBound] Break activity scheduled: \(group.breakDuration) minutes")
        } catch {
            print("[ZenBound] Failed to start break activity: \(error)")
        }
    }
    
    // MARK: - Strict Group Scheduling
    
    /// 启动严格模式时间表
    static func scheduleStrictActivity(for group: StrictGroup) {
        guard let schedules = group.schedules, !schedules.isEmpty else {
            print("[ZenBound] No schedules for strict group")
            return
        }
        
        let center = DeviceActivityCenter()
        
        for (index, schedule) in schedules.enumerated() {
            let activityName = DeviceActivityName("zenbound.strict.\(group.id.uuidString).\(index)")
            
            let intervalStart = DateComponents(
                hour: schedule.startHour,
                minute: schedule.startMinute
            )
            let intervalEnd = DateComponents(
                hour: schedule.endHour,
                minute: schedule.endMinute
            )
            
            let deviceSchedule = DeviceActivitySchedule(
                intervalStart: intervalStart,
                intervalEnd: intervalEnd,
                repeats: true
            )
            
            do {
                stopActivity(activityName, with: center)
                try center.startMonitoring(activityName, during: deviceSchedule)
                print("[ZenBound] Strict schedule \(index) started")
            } catch {
                print("[ZenBound] Failed to start strict schedule \(index): \(error)")
            }
        }
    }
    
    /// 启动单次会话限制
    static func startSingleSessionLimit(for group: StrictGroup) {
        let center = DeviceActivityCenter()
        let activityName = strictActivityName(for: group.id)
        
        let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
            from: group.singleSessionLimit
        )
        
        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: false
        )
        
        do {
            stopActivity(activityName, with: center)
            try center.startMonitoring(activityName, during: schedule)
            print("[ZenBound] Single session limit started: \(group.singleSessionLimit) minutes")
        } catch {
            print("[ZenBound] Failed to start single session limit: \(error)")
        }
    }
    
    // MARK: - Entertainment Group Scheduling
    
    /// 启动娱乐时间限制
    static func startEntertainmentLimit(for group: EntertainmentGroup) {
        let center = DeviceActivityCenter()
        let activityName = entertainmentActivityName(for: group.id)
        
        let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
            from: group.singleSessionLimit
        )
        
        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: false
        )
        
        do {
            stopActivity(activityName, with: center)
            try center.startMonitoring(activityName, during: schedule)
            print("[ZenBound] Entertainment limit started: \(group.singleSessionLimit) minutes")
        } catch {
            print("[ZenBound] Failed to start entertainment limit: \(error)")
        }
    }
    
    /// 启动休息提醒
    static func scheduleRestReminder(for group: EntertainmentGroup) {
        guard group.enableRestBlock else { return }
        
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName("zenbound.rest.\(group.id.uuidString)")
        
        let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
            from: group.restReminderInterval
        )
        
        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: true
        )
        
        do {
            stopActivity(activityName, with: center)
            try center.startMonitoring(activityName, during: schedule)
            print("[ZenBound] Rest reminder scheduled: every \(group.restReminderInterval) minutes")
        } catch {
            print("[ZenBound] Failed to schedule rest reminder: \(error)")
        }
    }
    
    // MARK: - Stop Activities
    
    /// 停止单个活动
    static func stopActivity(_ name: DeviceActivityName, with center: DeviceActivityCenter? = nil) {
        let activityCenter = center ?? DeviceActivityCenter()
        activityCenter.stopMonitoring([name])
    }
    
    /// 停止所有与组相关的活动
    static func stopAllActivities(for groupId: UUID) {
        let center = DeviceActivityCenter()
        
        let activitiesToStop = [
            focusActivityName(for: groupId),
            strictActivityName(for: groupId),
            entertainmentActivityName(for: groupId),
            breakActivityName(for: groupId),
            pomodoroActivityName(for: groupId, cycle: 0)
        ]
        
        center.stopMonitoring(activitiesToStop)
        print("[ZenBound] All activities stopped for group: \(groupId)")
    }
    
    /// 停止所有活动
    static func stopAllActivities() {
        let center = DeviceActivityCenter()
        let allActivities = center.activities
        center.stopMonitoring(allActivities)
        print("[ZenBound] All activities stopped")
    }
    
    // MARK: - Helper Methods
    
    /// 获取从现在开始的时间间隔
    private static func getTimeIntervalStartAndEnd(from minutes: Int) -> (DateComponents, DateComponents) {
        let now = Date()
        let calendar = Calendar.current
        
        // 开始时间：现在
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        
        // 结束时间：现在 + 指定分钟
        let endDate = calendar.date(byAdding: .minute, value: minutes, to: now)!
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: endDate)
        
        return (startComponents, endComponents)
    }
    
    /// 获取当前活动的活动
    static func getActiveActivities() -> Set<DeviceActivityName> {
        return DeviceActivityCenter().activities
    }
    
    /// 检查是否有活动正在运行
    static func hasActiveActivities(for groupId: UUID) -> Bool {
        let activities = getActiveActivities()
        let groupIdString = groupId.uuidString
        
        return activities.contains { $0.rawValue.contains(groupIdString) }
    }
}
