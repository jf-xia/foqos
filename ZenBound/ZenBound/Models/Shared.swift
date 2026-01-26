import FamilyControls
import Foundation

enum SharedData {
  private static let suite = UserDefaults(
    suiteName: "group.com.zenbound.data"
  )!

  // MARK: – Keys
  private enum Key: String {
    case profileSnapshots
    case activeScheduleSession
    case completedScheduleSessions
  }

  // MARK: – Serializable snapshot of a profile (no sessions)
  struct ProfileSnapshot: Codable, Equatable {
    var id: UUID
    var name: String
    var selectedActivity: FamilyActivitySelection
    var createdAt: Date
    var updatedAt: Date
    var blockingStrategyId: String?
    var strategyData: Data?
    var order: Int

    var enableLiveActivity: Bool
    var reminderTimeInSeconds: UInt32?
    var customReminderMessage: String?
    var enableBreaks: Bool
    var breakTimeInMinutes: Int = 15
    var enableStrictMode: Bool
    var enableAllowMode: Bool
    var enableAllowModeDomains: Bool
    var enableSafariBlocking: Bool

    var domains: [String]?
    var physicalUnblockNFCTagId: String?
    var physicalUnblockQRCodeId: String?

    var schedule: BlockedProfileSchedule?

    var disableBackgroundStops: Bool?
  }

  // MARK: – Serializable snapshot of a session (no profile object)
  struct SessionSnapshot: Codable, Equatable {
    var id: String
    var tag: String
    var blockedProfileId: UUID

    var startTime: Date
    var endTime: Date?

    var breakStartTime: Date?
    var breakEndTime: Date?

    var forceStarted: Bool
  }

  // MARK: – Persisted snapshots keyed by profile ID (UUID string)
  static var profileSnapshots: [String: ProfileSnapshot] {
    get {
      guard let data = suite.data(forKey: Key.profileSnapshots.rawValue) else { return [:] }
      return (try? JSONDecoder().decode([String: ProfileSnapshot].self, from: data)) ?? [:]
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.profileSnapshots.rawValue)
      } else {
        suite.removeObject(forKey: Key.profileSnapshots.rawValue)
      }
    }
  }

  static func snapshot(for profileID: String) -> ProfileSnapshot? {
    profileSnapshots[profileID]
  }

  static func setSnapshot(_ snapshot: ProfileSnapshot, for profileID: String) {
    var all = profileSnapshots
    all[profileID] = snapshot
    profileSnapshots = all
  }

  static func removeSnapshot(for profileID: String) {
    var all = profileSnapshots
    all.removeValue(forKey: profileID)
    profileSnapshots = all
  }

  // MARK: – Persisted array of scheduled sessions
  static var completedSessionsInSchedular: [SessionSnapshot] {
    get {
      guard let data = suite.data(forKey: Key.completedScheduleSessions.rawValue) else { return [] }
      return (try? JSONDecoder().decode([SessionSnapshot].self, from: data)) ?? []
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.completedScheduleSessions.rawValue)
      } else {
        suite.removeObject(forKey: Key.completedScheduleSessions.rawValue)
      }
    }
  }

  // MARK: – Persisted array of scheduled sessions
  static var activeSharedSession: SessionSnapshot? {
    get {
      guard let data = suite.data(forKey: Key.activeScheduleSession.rawValue) else { return nil }
      return (try? JSONDecoder().decode(SessionSnapshot.self, from: data)) ?? nil
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: Key.activeScheduleSession.rawValue)
      } else {
        suite.removeObject(forKey: Key.activeScheduleSession.rawValue)
      }
    }
  }

  static func createSessionForSchedular(for profileID: UUID) {
    activeSharedSession = SessionSnapshot(
      id: UUID().uuidString,
      tag: profileID.uuidString,
      blockedProfileId: profileID,
      startTime: Date(),
      forceStarted: true)
  }

  static func createActiveSharedSession(for session: SessionSnapshot) {
    activeSharedSession = session
  }

  static func getActiveSharedSession() -> SessionSnapshot? {
    activeSharedSession
  }

  static func endActiveSharedSession() {
    guard var existingScheduledSession = activeSharedSession else { return }

    existingScheduledSession.endTime = Date()
    completedSessionsInSchedular.append(existingScheduledSession)

    activeSharedSession = nil
  }

  static func flushActiveSession() {
    activeSharedSession = nil
  }

  static func getCompletedSessionsForSchedular() -> [SessionSnapshot] {
    completedSessionsInSchedular
  }

  static func flushCompletedSessionsForSchedular() {
    completedSessionsInSchedular = []
  }

  static func setBreakStartTime(date: Date) {
    activeSharedSession?.breakStartTime = date
  }

  static func setBreakEndTime(date: Date) {
    activeSharedSession?.breakEndTime = date
  }

  static func setEndTime(date: Date) {
    activeSharedSession?.endTime = date
  }

  // MARK: - Entertainment Group Configuration
  
  private enum EntertainmentKey: String {
    case entertainmentConfig
  }
  
  /// 娱乐组配置快照 - 用于 App 与 Extension 之间共享
  struct EntertainmentConfig: Codable, Equatable {
    var isActive: Bool = false
    var selectedActivity: FamilyActivitySelection
    var hourlyLimitMinutes: Int = 15              // 每小时限制（分钟）
    var dailyLimitMinutes: Int = 120              // 每日总限制（分钟）
    var restDurationMinutes: Int = 45             // 强制休息时长
    var enableHourlyLimit: Bool = true            // 启用每小时限制
    var currentHourUsageMinutes: Int = 0          // 当前小时已用时间
    var lastResetHour: Int = -1                   // 上次重置的小时
    var todayTotalUsageMinutes: Int = 0           // 今日总使用时间
    var lastResetDate: Date?                      // 上次重置日期
    var shieldMessage: String = "Enjoy your time!"
    var enableWeekends: Bool = true               // 周末生效
  }
  
  static var entertainmentConfig: EntertainmentConfig? {
    get {
      guard let data = suite.data(forKey: EntertainmentKey.entertainmentConfig.rawValue) else { return nil }
      return try? JSONDecoder().decode(EntertainmentConfig.self, from: data)
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        suite.set(data, forKey: EntertainmentKey.entertainmentConfig.rawValue)
      } else {
        suite.removeObject(forKey: EntertainmentKey.entertainmentConfig.rawValue)
      }
    }
  }
  
  static func updateEntertainmentUsage(addMinutes: Int) {
    guard var config = entertainmentConfig else { return }
    config.currentHourUsageMinutes += addMinutes
    config.todayTotalUsageMinutes += addMinutes
    entertainmentConfig = config
  }
  
  static func resetEntertainmentHourlyUsage() {
    guard var config = entertainmentConfig else { return }
    let currentHour = Calendar.current.component(.hour, from: Date())
    if config.lastResetHour != currentHour {
      config.currentHourUsageMinutes = 0
      config.lastResetHour = currentHour
      entertainmentConfig = config
    }
  }
  
  static func resetEntertainmentDailyUsage() {
    guard var config = entertainmentConfig else { return }
    let today = Calendar.current.startOfDay(for: Date())
    if let lastReset = config.lastResetDate, Calendar.current.isDate(lastReset, inSameDayAs: today) {
      return // Already reset today
    }
    config.todayTotalUsageMinutes = 0
    config.currentHourUsageMinutes = 0
    config.lastResetDate = today
    entertainmentConfig = config
  }
}
