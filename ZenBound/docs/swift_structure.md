# ZenBound Swift 代码结构

> 生成时间: 2026-01-22 22:54:28

## 文件列表

- **ZenBound/**
  - [ZenBound/Models/BlockedProfileSessions.swift](#zenbound-models-blockedprofilesessions-swift)
  - [ZenBound/Models/BlockedProfiles.swift](#zenbound-models-blockedprofiles-swift)
  - [ZenBound/Models/Schedule.swift](#zenbound-models-schedule-swift)
  - [ZenBound/Models/Shared.swift](#zenbound-models-shared-swift)
  - [ZenBound/Models/Strategies/BlockingStrategy.swift](#zenbound-models-strategies-blockingstrategy-swift)
  - [ZenBound/Models/Strategies/Data/StrategyTimerData.swift](#zenbound-models-strategies-data-strategytimerdata-swift)
  - [ZenBound/Models/Strategies/ManualBlockingStrategy.swift](#zenbound-models-strategies-manualblockingstrategy-swift)
  - [ZenBound/Models/Strategies/ShortcutTimerBlockingStrategy.swift](#zenbound-models-strategies-shortcuttimerblockingstrategy-swift)
  - [ZenBound/Models/Timers/BreakTimerActivity.swift](#zenbound-models-timers-breaktimeractivity-swift)
  - [ZenBound/Models/Timers/ScheduleTimerActivity.swift](#zenbound-models-timers-scheduletimeractivity-swift)
  - [ZenBound/Models/Timers/StrategyTimerActivity.swift](#zenbound-models-timers-strategytimeractivity-swift)
  - [ZenBound/Models/Timers/TimerActivity.swift](#zenbound-models-timers-timeractivity-swift)
  - [ZenBound/Models/Timers/TimerActivityUtil.swift](#zenbound-models-timers-timeractivityutil-swift)
  - [ZenBound/Utils/AppBlockerUtil.swift](#zenbound-utils-appblockerutil-swift)
  - [ZenBound/Utils/DeviceActivityCenterUtil.swift](#zenbound-utils-deviceactivitycenterutil-swift)
  - [ZenBound/Utils/FamilyActivityUtil.swift](#zenbound-utils-familyactivityutil-swift)
  - [ZenBound/Utils/FocusMessages.swift](#zenbound-utils-focusmessages-swift)
  - [ZenBound/Utils/LiveActivityManager.swift](#zenbound-utils-liveactivitymanager-swift)
  - [ZenBound/Utils/ProfileInsightsUtil.swift](#zenbound-utils-profileinsightsutil-swift)
  - [ZenBound/Utils/RatingManager.swift](#zenbound-utils-ratingmanager-swift)
  - [ZenBound/Utils/RequestAuthorizer.swift](#zenbound-utils-requestauthorizer-swift)
  - [ZenBound/Utils/StrategyManager.swift](#zenbound-utils-strategymanager-swift)
  - [ZenBound/Utils/ThemeManager.swift](#zenbound-utils-thememanager-swift)
  - [ZenBound/Utils/TimersUtil.swift](#zenbound-utils-timersutil-swift)
  - [ZenBound/ZenBoundApp.swift](#zenbound-zenboundapp-swift)
- **ZenBoundTests/**
  - [ZenBoundTests/ZenBoundTests.swift](#zenboundtests-zenboundtests-swift)
- **ZenBoundUITests/**
  - [ZenBoundUITests/ZenBoundUITests.swift](#zenbounduitests-zenbounduitests-swift)
  - [ZenBoundUITests/ZenBoundUITestsLaunchTests.swift](#zenbounduitests-zenbounduitestslaunchtests-swift)
- **monitor/**
  - [monitor/DeviceActivityMonitorExtension.swift](#monitor-deviceactivitymonitorextension-swift)
- **shieldAction/**
  - [shieldAction/ShieldActionExtension.swift](#shieldaction-shieldactionextension-swift)
- **shieldConfig/**
  - [shieldConfig/ShieldConfigurationExtension.swift](#shieldconfig-shieldconfigurationextension-swift)
- **widget/**
  - [widget/widgetBundle.swift](#widget-widgetbundle-swift)

---

## 详细结构

### 📁 ZenBound

#### BlockedProfileSessions.swift
<a id="zenbound-models-blockedprofilesessions-swift"></a>
`ZenBound/Models/BlockedProfileSessions.swift`

**🔷 class BlockedProfileSession**
  - `var id`: String
  - `var tag`: String
  - `var blockedProfile`: BlockedProfiles
  - `var startTime`: Date
  - `var endTime`: Date?
  - `var breakStartTime`: Date?
  - `var breakEndTime`: Date?
  - `var forceStarted`: Bool
  - `var isActive`: Bool
  - `var isBreakAvailable`: Bool
  - `var isBreakActive`: Bool
  - `var duration`: TimeInterval
  - `let end`
  - `Date` (call)
  - `end.timeIntervalSince` (call)
  - `func init(tag:blockedProfile:forceStarted:)`
  - `func startBreak()`
  - `func endBreak()`
  - `func endSession()`
  - `func toSnapshot()` → SharedData.SessionSnapshot
  - `static func mostRecentActiveSession(in:)` → BlockedProfileSession?
  - `static func createSession(in:withTag:withProfile:forceStart:)` → BlockedProfileSession
  - `static func upsertSessionFromSnapshot(in:withSnapshot:)`
  - `static func findSession(byID:in:)` → BlockedProfileSession?
  - `static func recentInactiveSessions(in:limit:)` → [BlockedProfileSession]

#### BlockedProfiles.swift
<a id="zenbound-models-blockedprofiles-swift"></a>
`ZenBound/Models/BlockedProfiles.swift`

**🔷 class BlockedProfiles**
  - `var id`: UUID
  - `var name`: String
  - `var selectedActivity`: FamilyActivitySelection
  - `var createdAt`: Date
  - `var updatedAt`: Date
  - `var order`: Int
  - `var blockingStrategyId`: String?
  - `var strategyData`: Data?
  - `var enableLiveActivity`: Bool
  - `var reminderTimeInSeconds`: UInt32?
  - `var customReminderMessage`: String?
  - `var enableBreaks`: Bool
  - `var breakTimeInMinutes`: Int
  - `var enableStrictMode`: Bool
  - `var enableAllowMode`: Bool
  - `var enableAllowModeDomains`: Bool
  - `var enableSafariBlocking`: Bool
  - `var disableBackgroundStops`: Bool
  - `var physicalUnblockNFCTagId`: String?
  - `var physicalUnblockQRCodeId`: String?
  - `var domains`: [String]?
  - `var schedule`: BlockedProfileSchedule?
  - `var sessions`: [BlockedProfileSession]
  - `var activeScheduleTimerActivity`: DeviceActivityName?
  - `DeviceActivityCenterUtil.getActiveScheduleTimerActivity` (call)
  - `var scheduleIsOutOfSync`: Bool
  - `DeviceActivityCenterUtil.getActiveScheduleTimerActivity` (call)
  - `func init(id:name:selectedActivity:createdAt:updatedAt:blockingStrategyId:strategyData:enableLiveActivity:reminderTimeInSeconds:customReminderMessage:enableBreaks:breakTimeInMinutes:enableStrictMode:enableAllowMode:enableAllowModeDomains:enableSafariBlocking:order:domains:physicalUnblockNFCTagId:physicalUnblockQRCodeId:schedule:disableBackgroundStops:)`
  - `static func fetchProfiles(in:)` → [BlockedProfiles]
  - `static func findProfile(byID:in:)` → BlockedProfiles?
  - `static func fetchMostRecentlyUpdatedProfile(in:)` → BlockedProfiles?
  - `static func updateProfile(_:in:name:selection:blockingStrategyId:strategyData:enableLiveActivity:reminderTime:customReminderMessage:enableBreaks:breakTimeInMinutes:enableStrictMode:enableAllowMode:enableAllowModeDomains:enableSafariBlocking:order:domains:physicalUnblockNFCTagId:physicalUnblockQRCodeId:schedule:disableBackgroundStops:)` → BlockedProfiles
  - `static func deleteProfile(_:in:)`
  - `static func getProfileDeepLink(_:)` → String
  - `static func getSnapshot(for:)` → SharedData.ProfileSnapshot
  - `static func updateSnapshot(for:)`
  - `static func deleteSnapshot(for:)`
  - `static func reorderProfiles(_:in:)`
  - `static func getNextOrder(in:)` → Int
  - `static func createProfile(in:name:selection:blockingStrategyId:strategyData:enableLiveActivity:reminderTimeInSeconds:customReminderMessage:enableBreaks:breakTimeInMinutes:enableStrictMode:enableAllowMode:enableAllowModeDomains:enableSafariBlocking:domains:physicalUnblockNFCTagId:physicalUnblockQRCodeId:schedule:disableBackgroundStops:)` → BlockedProfiles
  - `static func cloneProfile(_:in:newName:)` → BlockedProfiles
  - `static func addDomain(to:context:domain:)`
  - `static func removeDomain(from:context:domain:)`

#### Schedule.swift
<a id="zenbound-models-schedule-swift"></a>
`ZenBound/Models/Schedule.swift`

**🔸 enum Weekday**: Int, CaseIterable, Codable, Equatable
  **case sunday**
  **case monday**
  **case tuesday**
  **case wednesday**
  **case thursday**
  **case friday**
  **case saturday**
  - `var name`: String
  - `var shortLabel`: String
**🔶 struct BlockedProfileSchedule**: Codable, Equatable
  - `var days`: [Weekday]
  - `var startHour`: Int
  - `var startMinute`: Int
  - `var endHour`: Int
  - `var endMinute`: Int
  - `var updatedAt`: Date
  - `Date` (call)
  - `var isActive`: Bool
  - `var totalDurationInSeconds`: Int
  - `var summaryText`: String
  - `let daysSummary`
  - `days
      .sorted { $0.rawValue < $1.rawValue }
      .map { $0.shortLabel }
      .joined` (call)
  - `let start`
  - `formattedTimeString` (call)
  - `let end`
  - `formattedTimeString` (call)
  - `func isTodayScheduled(now:calendar:)` → Bool
  - `func olderThan15Minutes(now:)` → Bool
  - -`func formattedTimeString(hour24:minute:)` → String

#### Shared.swift
<a id="zenbound-models-shared-swift"></a>
`ZenBound/Models/Shared.swift`

**🔸 enum SharedData**
  - -`static var suite`
  - `UserDefaults` (call)
  **🔸 enum Key**: String
    **case profileSnapshots**
    **case activeScheduleSession**
    **case completedScheduleSessions**
  **🔶 struct ProfileSnapshot**: Codable, Equatable
    - `var id`: UUID
    - `var name`: String
    - `var selectedActivity`: FamilyActivitySelection
    - `var createdAt`: Date
    - `var updatedAt`: Date
    - `var blockingStrategyId`: String?
    - `var strategyData`: Data?
    - `var order`: Int
    - `var enableLiveActivity`: Bool
    - `var reminderTimeInSeconds`: UInt32?
    - `var customReminderMessage`: String?
    - `var enableBreaks`: Bool
    - `var breakTimeInMinutes`: Int
    - `var enableStrictMode`: Bool
    - `var enableAllowMode`: Bool
    - `var enableAllowModeDomains`: Bool
    - `var enableSafariBlocking`: Bool
    - `var domains`: [String]?
    - `var physicalUnblockNFCTagId`: String?
    - `var physicalUnblockQRCodeId`: String?
    - `var schedule`: BlockedProfileSchedule?
    - `var disableBackgroundStops`: Bool?
  **🔶 struct SessionSnapshot**: Codable, Equatable
    - `var id`: String
    - `var tag`: String
    - `var blockedProfileId`: UUID
    - `var startTime`: Date
    - `var endTime`: Date?
    - `var breakStartTime`: Date?
    - `var breakEndTime`: Date?
    - `var forceStarted`: Bool
  - `static var profileSnapshots`: [String: ProfileSnapshot]
  - `let data`
  - `suite.data` (call)
  - `JSONDecoder().decode` (call)
  - `let data`
  - `JSONEncoder().encode` (call)
  - `suite.set` (call)
  - `suite.removeObject` (call)
  - `static func snapshot(for:)` → ProfileSnapshot?
  - `static func setSnapshot(_:for:)`
  - `static func removeSnapshot(for:)`
  - `static var completedSessionsInSchedular`: [SessionSnapshot]
  - `let data`
  - `suite.data` (call)
  - `JSONDecoder().decode` (call)
  - `let data`
  - `JSONEncoder().encode` (call)
  - `suite.set` (call)
  - `suite.removeObject` (call)
  - `static var activeSharedSession`: SessionSnapshot?
  - `let data`
  - `suite.data` (call)
  - `JSONDecoder().decode` (call)
  - `let data`
  - `JSONEncoder().encode` (call)
  - `suite.set` (call)
  - `suite.removeObject` (call)
  - `static func createSessionForSchedular(for:)`
  - `static func createActiveSharedSession(for:)`
  - `static func getActiveSharedSession()` → SessionSnapshot?
  - `static func endActiveSharedSession()`
  - `static func flushActiveSession()`
  - `static func getCompletedSessionsForSchedular()` → [SessionSnapshot]
  - `static func flushCompletedSessionsForSchedular()`
  - `static func setBreakStartTime(date:)`
  - `static func setBreakEndTime(date:)`
  - `static func setEndTime(date:)`

#### BlockingStrategy.swift
<a id="zenbound-models-strategies-blockingstrategy-swift"></a>
`ZenBound/Models/Strategies/BlockingStrategy.swift`

**🔸 enum SessionStatus**
  **case started(_:)**
  **case ended(_:)**
**📋 protocol BlockingStrategy**
  - `static var id`: String
  - `var name`: String
  - `var description`: String
  - `var iconType`: String
  - `var color`: Color
  - `var hidden`: Bool
  - `var onSessionCreation`: ((SessionStatus) -> Void)?
  - `var onErrorMessage`: ((String) -> Void)?
  - `func getIdentifier()` → String
  - `func startBlocking(context:profile:forceStart:)` → (any View)?
  - `func stopBlocking(context:session:)` → (any View)?

#### StrategyTimerData.swift
<a id="zenbound-models-strategies-data-strategytimerdata-swift"></a>
`ZenBound/Models/Strategies/Data/StrategyTimerData.swift`

**🔶 struct StrategyTimerData**: Codable
  - `var durationInMinutes`: Int
  - `static func toStrategyTimerData(from:)` → StrategyTimerData
  - `static func toData(from:)` → Data?

#### ManualBlockingStrategy.swift
<a id="zenbound-models-strategies-manualblockingstrategy-swift"></a>
`ZenBound/Models/Strategies/ManualBlockingStrategy.swift`

**🔷 class ManualBlockingStrategy**: BlockingStrategy
  - `static var id`: String
  - `var name`: String
  - `var description`: String
  - `var iconType`: String
  - `var color`: Color
  - `var hidden`: Bool
  - `var onSessionCreation`: ((SessionStatus) -> Void)?
  - `var onErrorMessage`: ((String) -> Void)?
  - -`var appBlocker`: AppBlockerUtil
  - `AppBlockerUtil` (call)
  - `func getIdentifier()` → String
  - `func startBlocking(context:profile:forceStart:)` → (any View)?
  - `func stopBlocking(context:session:)` → (any View)?

#### ShortcutTimerBlockingStrategy.swift
<a id="zenbound-models-strategies-shortcuttimerblockingstrategy-swift"></a>
`ZenBound/Models/Strategies/ShortcutTimerBlockingStrategy.swift`

**🔷 class ShortcutTimerBlockingStrategy**: BlockingStrategy
  - `static var id`: String
  - `var name`: String
  - `var description`: String
  - `var iconType`: String
  - `var color`: Color
  - `var hidden`: Bool
  - `var onSessionCreation`: ((SessionStatus) -> Void)?
  - `var onErrorMessage`: ((String) -> Void)?
  - -`var appBlocker`: AppBlockerUtil
  - `AppBlockerUtil` (call)
  - `func getIdentifier()` → String
  - `func startBlocking(context:profile:forceStart:)` → (any View)?
  - `func stopBlocking(context:session:)` → (any View)?

#### BreakTimerActivity.swift
<a id="zenbound-models-timers-breaktimeractivity-swift"></a>
`ZenBound/Models/Timers/BreakTimerActivity.swift`

- -`var log`
- `Logger` (call)
**🔷 class BreakTimerActivity**: TimerActivity
  - `static var id`: String
  - -`var appBlocker`
  - `AppBlockerUtil` (call)
  - `func getDeviceActivityName(from:)` → DeviceActivityName
  - `func getAllBreakTimerActivities(from:)` → [DeviceActivityName]
  - `func start(for:)`
  - `func stop(for:)`

#### ScheduleTimerActivity.swift
<a id="zenbound-models-timers-scheduletimeractivity-swift"></a>
`ZenBound/Models/Timers/ScheduleTimerActivity.swift`

- -`var log`: Logger
- `Logger` (call)
**🔷 class ScheduleTimerActivity**: TimerActivity
  - `static var id`: String
  - -`var appBlocker`
  - `AppBlockerUtil` (call)
  - `func getDeviceActivityName(from:)` → DeviceActivityName
  - `func getAllScheduleTimerActivities(from:)` → [DeviceActivityName]
  - `func start(for:)`
  - `func stop(for:)`
  - `func getScheduleInterval(from:)` → (
    intervalStart: DateComponents, intervalEnd: DateComponents
  )

#### StrategyTimerActivity.swift
<a id="zenbound-models-timers-strategytimeractivity-swift"></a>
`ZenBound/Models/Timers/StrategyTimerActivity.swift`

- -`var log`: Logger
- `Logger` (call)
**🔷 class StrategyTimerActivity**: TimerActivity
  - `static var id`: String
  - -`var appBlocker`
  - `AppBlockerUtil` (call)
  - `func getDeviceActivityName(from:)` → DeviceActivityName
  - `func getAllStrategyTimerActivities(from:)` → [DeviceActivityName]
  - `func start(for:)`
  - `func stop(for:)`

#### TimerActivity.swift
<a id="zenbound-models-timers-timeractivity-swift"></a>
`ZenBound/Models/Timers/TimerActivity.swift`

**📋 protocol TimerActivity**
  - `static var id`: String
  - `func getDeviceActivityName(from:)` → DeviceActivityName
  - `func start(for:)`
  - `func stop(for:)`

#### TimerActivityUtil.swift
<a id="zenbound-models-timers-timeractivityutil-swift"></a>
`ZenBound/Models/Timers/TimerActivityUtil.swift`

**🔷 class TimerActivityUtil**
  - `static func startTimerActivity(for:)`
  - `static func stopTimerActivity(for:)`
  - -`static func getTimerParts(from:)` → (
    deviceActivityId: String, profileId: String
  )
  - -`static func getTimerActivity(for:)` → TimerActivity?
  - -`static func getProfile(for:)` → SharedData.ProfileSnapshot?

#### AppBlockerUtil.swift
<a id="zenbound-utils-appblockerutil-swift"></a>
`ZenBound/Utils/AppBlockerUtil.swift`

**🔷 class AppBlockerUtil**
  - `var store`
  - `ManagedSettingsStore` (call)
  - `func activateRestrictions(for:)`
  - `func deactivateRestrictions()`
  - `func getWebDomains(from:)` → Set<WebDomain>

#### DeviceActivityCenterUtil.swift
<a id="zenbound-utils-deviceactivitycenterutil-swift"></a>
`ZenBound/Utils/DeviceActivityCenterUtil.swift`

**🔷 class DeviceActivityCenterUtil**
  - `static func scheduleTimerActivity(for:)`
  - `static func startBreakTimerActivity(for:)`
  - `static func startStrategyTimerActivity(for:)`
  - `static func removeScheduleTimerActivities(for:)`
  - `static func removeScheduleTimerActivities(for:)`
  - `static func removeAllBreakTimerActivities()`
  - `static func removeBreakTimerActivity(for:)`
  - `static func removeAllStrategyTimerActivities()`
  - `static func getActiveScheduleTimerActivity(for:)` → DeviceActivityName?
  - `static func getDeviceActivities()` → [DeviceActivityName]
  - -`static func stopActivities(for:with:)`
  - -`static func getTimeIntervalStartAndEnd(from:)` → (
    intervalStart: DateComponents, intervalEnd: DateComponents
  )

#### FamilyActivityUtil.swift
<a id="zenbound-utils-familyactivityutil-swift"></a>
`ZenBound/Utils/FamilyActivityUtil.swift`

**🔶 struct FamilyActivityUtil**
  - `static func countSelectedActivities(_:allowMode:)` → Int
  - `static func getCountDisplayText(_:allowMode:)` → String
  - `static func shouldShowAllowModeWarning(_:allowMode:)` → Bool
  - `static func getSelectionBreakdown(_:)` → (
    categories: Int, applications: Int, webDomains: Int
  )

#### FocusMessages.swift
<a id="zenbound-utils-focusmessages-swift"></a>
`ZenBound/Utils/FocusMessages.swift`

**🔶 struct FocusMessages**
  - `static var messages`
  - `static func getRandomMessage()` → String

#### LiveActivityManager.swift
<a id="zenbound-utils-liveactivitymanager-swift"></a>
`ZenBound/Utils/LiveActivityManager.swift`

**🔷 class LiveActivityManager**: ObservableObject
  - `var currentActivity`: Activity<FoqosWidgetAttributes>?
  - -`var storedActivityId`: String
  - `static var shared`
  - `LiveActivityManager` (call)
  - -`func init()`
  - -`var isSupported`: Bool
  - `ActivityAuthorizationInfo` (call)
  - -`func saveActivityId(_:)`
  - -`func removeActivityId()`
  - -`func restoreExistingActivity()`
  - `func startSessionActivity(session:)`
  - `func updateSessionActivity(session:)`
  - `func updateBreakState(session:)`
  - `func endSessionActivity()`

#### ProfileInsightsUtil.swift
<a id="zenbound-utils-profileinsightsutil-swift"></a>
`ZenBound/Utils/ProfileInsightsUtil.swift`

**🔶 struct ProfileInsightsMetrics**
  - `var totalCompletedSessions`: Int
  - `var totalFocusTime`: TimeInterval
  - `var averageSessionDuration`: TimeInterval?
  - `var longestSessionDuration`: TimeInterval?
  - `var shortestSessionDuration`: TimeInterval?
  - `var totalBreaksTaken`: Int
  - `var averageBreakDuration`: TimeInterval?
  - `var sessionsWithBreaks`: Int
  - `var sessionsWithoutBreaks`: Int
**🔷 class ProfileInsightsUtil**: ObservableObject
  - `var metrics`: ProfileInsightsMetrics
  **🔶 struct DayAggregate**: Identifiable
    - `var id`
    - `UUID` (call)
    - `var date`: Date
    - `var sessionsCount`: Int
    - `var focusDuration`: TimeInterval
  **🔶 struct HourAggregate**: Identifiable, Hashable
    - `var id`
    - `UUID` (call)
    - `var hour`: Int
    - `var sessionsStarted`: Int
    - `var averageSessionDuration`: TimeInterval?
    - `var totalFocus`: TimeInterval
  **🔶 struct BreakDayAggregate**: Identifiable
    - `var id`
    - `UUID` (call)
    - `var date`: Date
    - `var breaksCount`: Int
    - `var totalBreakDuration`: TimeInterval
  **🔶 struct BreakHourAggregate**: Identifiable, Hashable
    - `var id`
    - `UUID` (call)
    - `var hour`: Int
    - `var breaksStarted`: Int
    - `var averageBreakDuration`: TimeInterval?
  **🔶 struct SessionEndHourAggregate**: Identifiable, Hashable
    - `var id`
    - `UUID` (call)
    - `var hour`: Int
    - `var sessionsEnded`: Int
  **🔶 struct BreakStartHourAggregate**: Identifiable, Hashable
    - `var id`
    - `UUID` (call)
    - `var hour`: Int
    - `var breaksStarted`: Int
  **🔶 struct BreakEndHourAggregate**: Identifiable, Hashable
    - `var id`
    - `UUID` (call)
    - `var hour`: Int
    - `var breaksEnded`: Int
  - `var profile`: BlockedProfiles
  - -`var startDate`: Date?
  - -`var endDate`: Date?
  - `func init(profile:)`
  - `func setDateRange(start:end:)`
  - `func refresh()`
  - -`static func computeMetrics(for:from:to:)` → ProfileInsightsMetrics
  - `func formattedDuration(_:)` → String
  - `func formattedPercent(_:)` → String
  - `func dailyAggregates(days:endingOn:)` → [DayAggregate]
  - `func hourlyAggregates(days:endingOn:)` → [HourAggregate]
  - `func currentStreakDays()` → Int
  - `func longestStreakDays(lookbackDays:)` → Int
  - `func breakDailyAggregates(days:endingOn:)` → [BreakDayAggregate]
  - `func breakHourlyAggregates(days:endingOn:)` → [BreakHourAggregate]
  - `func sessionEndHourlyAggregates(days:endingOn:)` → [SessionEndHourAggregate]
  - `func breakStartHourlyAggregates(days:endingOn:)` → [BreakStartHourAggregate]
  - `func breakEndHourlyAggregates(days:endingOn:)` → [BreakEndHourAggregate]

#### RatingManager.swift
<a id="zenbound-utils-ratingmanager-swift"></a>
`ZenBound/Utils/RatingManager.swift`

**🔷 class RatingManager**: ObservableObject
  - -`var launchCount`
  - -`var lastVersionPromptedForReview`: String?
  - `var shouldRequestReview`
  - `func incrementLaunchCount()`
  - -`func checkIfShouldRequestReview()`
  - -`func requestReview()`

#### RequestAuthorizer.swift
<a id="zenbound-utils-requestauthorizer-swift"></a>
`ZenBound/Utils/RequestAuthorizer.swift`

**🔷 class RequestAuthorizer**: ObservableObject
  - `var isAuthorized`
  - `var authorizationStatus`: AuthorizationStatus
  - `func init()`
  - `func checkAuthorizationStatus()`
  - `func requestAuthorization()`
  - `func requestAuthorization()`
  - `func revokeAuthorization()`
  - `func getAuthorizationStatus()` → AuthorizationStatus

#### StrategyManager.swift
<a id="zenbound-utils-strategymanager-swift"></a>
`ZenBound/Utils/StrategyManager.swift`

**🔷 class StrategyManager**: ObservableObject
  - `static var shared`
  - `StrategyManager` (call)
  - `static var availableStrategies`: [BlockingStrategy]
  - `ManualBlockingStrategy` (call)
  - `ShortcutTimerBlockingStrategy` (call)
  - `var elapsedTime`: TimeInterval
  - `var timer`: Timer?
  - `var activeSession`: BlockedProfileSession?
  - `var showCustomStrategyView`: Bool
  - `var customStrategyView`: (any View)?
  - `var errorMessage`: String?
  - -`var emergencyUnblocksRemaining`: Int
  - -`var emergencyUnblocksResetPeriodInWeeks`: Int
  - -`var lastEmergencyUnblocksResetDateTimestamp`: Double
  - -`var liveActivityManager`
  - -`var timersUtil`
  - `TimersUtil` (call)
  - -`var appBlocker`
  - `AppBlockerUtil` (call)
  - `var isBlocking`: Bool
  - `var isBreakActive`: Bool
  - `var isBreakAvailable`: Bool
  - `func defaultReminderMessage(forProfile:)` → String
  - `func loadActiveSession(context:)`
  - `func toggleBlocking(context:activeProfile:)`
  - `func toggleBreak(context:)`
  - `func startTimer()`
  - `func stopTimer()`
  - -`func calculateBreakDuration()` → TimeInterval
  - `func toggleSessionFromDeeplink(_:url:context:)`
  - `func startSessionFromBackground(_:context:durationInMinutes:)`
  - `func stopSessionFromBackground(_:context:)`
  - `func getRemainingEmergencyUnblocks()` → Int
  - `func emergencyUnblock(context:)`
  - `func resetEmergencyUnblocks()`
  - `func checkAndResetEmergencyUnblocks()`
  - `func getNextResetDate()` → Date?
  - `func getResetPeriodInWeeks()` → Int
  - `func setResetPeriodInWeeks(_:)`
  - `static func getStrategyFromId(id:)` → BlockingStrategy
  - `func getStrategy(id:)` → BlockingStrategy
  - -`func startBreak(context:)`
  - -`func stopBreak(context:)`
  - -`func dismissView()`
  - -`func getActiveSession(context:)` → BlockedProfileSession?
  - -`func syncScheduleSessions(context:)`
  - -`func startBlocking(context:activeProfile:)`
  - -`func stopBlocking(context:)`
  - -`func scheduleReminder(profile:)`
  - -`func scheduleBreakReminder(profile:)`
  - `func cleanUpGhostSchedules(context:)`

#### ThemeManager.swift
<a id="zenbound-utils-thememanager-swift"></a>
`ZenBound/Utils/ThemeManager.swift`

**🔷 class ThemeManager**: ObservableObject
  - `static var shared`
  - `ThemeManager` (call)
  - `static var availableColors`: [(name: String, color: Color)]
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - `Color` (call)
  - -`static var defaultColorName`
  - `store` (argument)
  - -`var themeColorName`: String
  - `var selectedColorName`: String
  - `objectWillChange.send` (call)
  - `var themeColor`: Color
  - `Self.availableColors.first` (call)
  - `func setTheme(named:)`
**🔗 extension Color**
  - `func init(hex:)`
  - `func toHex()` → String?

#### TimersUtil.swift
<a id="zenbound-utils-timersutil-swift"></a>
`ZenBound/Utils/TimersUtil.swift`

**🔗 extension Notification.Name**
  - ~`static var backgroundTaskExecuted`
  - `Notification.Name` (call)
**🔸 enum NotificationResult**
  **case success**
  **case failure(_:)**
  - `var succeeded`: Bool
**🔷 class TimersUtil**
  - `static var backgroundProcessingTaskIdentifier`
  - `static var backgroundTaskUserDefaultsKey`
  - -`var backgroundTasks`: [String: [String: Any]]
  - `UserDefaults.standard.dictionary` (call)
  - `UserDefaults.standard.set` (call)
  - `static func registerBackgroundTasks()`
  - -`static func handleBackgroundProcessingTask(_:)`
  - `func scheduleBackgroundProcessing()`
  - `func cancelBackgroundTask(taskId:)`
  - `func cancelAllBackgroundTasks()`
  - `func scheduleNotification(title:message:seconds:identifier:completion:)` → String
  - `func cancelNotification(identifier:)`
  - `func cancelAllNotifications()`
  - `func cancelAll()`
  - -`func scheduleBackgroundTask(taskId:executionTime:notificationId:)`
  - -`func requestNotificationAuthorization(completion:)`

#### ZenBoundApp.swift
<a id="zenbound-zenboundapp-swift"></a>
`ZenBound/ZenBoundApp.swift`

- -`var container`: ModelContainer
- `{
    do {
        return try ModelContainer(
            for: BlockedProfileSession.self,
            BlockedProfiles.self
        )
    } catch {
        fatalError("Couldn't create ModelContainer: \(error)")
    }
}` (call)
**🔶 struct ZenBoundApp**: App
  - -`var requestAuthorizer`
  - `RequestAuthorizer` (call)
  - -`var startegyManager`
  - `func init()`
  - `var body`: some Scene
  - `WindowGroup {
            DemoHomeView()
                .environmentObject(requestAuthorizer)      // 权限管理 / Authorization
                .environmentObject(startegyManager)        // 策略管理 / Strategy (核心)
        }
        .modelContainer` (call)

### 📁 ZenBoundTests

#### ZenBoundTests.swift
<a id="zenboundtests-zenboundtests-swift"></a>
`ZenBoundTests/ZenBoundTests.swift`

**🔶 struct ZenBoundTests**
  - `func example()`

### 📁 ZenBoundUITests

#### ZenBoundUITests.swift
<a id="zenbounduitests-zenbounduitests-swift"></a>
`ZenBoundUITests/ZenBoundUITests.swift`

**🔷 class ZenBoundUITests**: XCTestCase
  - `func setUpWithError()`
  - `func tearDownWithError()`
  - `func testExample()`
  - `func testLaunchPerformance()`

#### ZenBoundUITestsLaunchTests.swift
<a id="zenbounduitests-zenbounduitestslaunchtests-swift"></a>
`ZenBoundUITests/ZenBoundUITestsLaunchTests.swift`

**🔷 class ZenBoundUITestsLaunchTests**: XCTestCase
  **class var runsForEachTargetApplicationUIConfiguration**
  - `func setUpWithError()`
  - `func testLaunch()`

### 📁 monitor

#### DeviceActivityMonitorExtension.swift
<a id="monitor-deviceactivitymonitorextension-swift"></a>
`monitor/DeviceActivityMonitorExtension.swift`

- -`var log`
- `Logger` (call)
**🔷 class DeviceActivityMonitorExtension**: DeviceActivityMonitor
  - -`var store`
  - `ManagedSettingsStore` (call)
  - `func init()`
  - `func intervalDidStart(for:)`
  - `func intervalDidEnd(for:)`

### 📁 shieldAction

#### ShieldActionExtension.swift
<a id="shieldaction-shieldactionextension-swift"></a>
`shieldAction/ShieldActionExtension.swift`

**🔷 class ShieldActionExtension**: ShieldActionDelegate
  - `func handle(action:for:completionHandler:)`
  - `func handle(action:for:completionHandler:)`
  - `func handle(action:for:completionHandler:)`

### 📁 shieldConfig

#### ShieldConfigurationExtension.swift
<a id="shieldconfig-shieldconfigurationextension-swift"></a>
`shieldConfig/ShieldConfigurationExtension.swift`

**🔷 class ShieldConfigurationExtension**: ShieldConfigurationDataSource
  - `func configuration(shielding:)` → ShieldConfiguration
  - `func configuration(shielding:in:)` → ShieldConfiguration
  - `func configuration(shielding:)` → ShieldConfiguration
  - `func configuration(shielding:in:)` → ShieldConfiguration
  - -`func createCustomShieldConfiguration(for:title:)` → ShieldConfiguration
  - -`func getFunBlockMessage(for:title:)` → (
    emoji: String, title: String, subtitle: String, buttonText: String
  )
  - -`func stableSeed(for:)` → UInt64
  - -`func makeEmojiIcon(_:size:)` → UIImage?
**🔸 enum BlockedContentType**
  **case app**
  **case website**

### 📁 widget

#### widgetBundle.swift
<a id="widget-widgetbundle-swift"></a>
`widget/widgetBundle.swift`

**🔶 struct ZenBoundWidgetBundle**: WidgetBundle
  - `var body`: some Widget
  - `ZenBoundWidget` (call)
**🔶 struct ZenBoundWidget**: Widget
  - `var kind`: String
  - `var body`: some WidgetConfiguration
  - `StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            ZenBoundWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ZenBound")
        .description("Track your focus sessions")
        .supportedFamilies` (call)
**🔶 struct SimpleEntry**: TimelineEntry
  - `var date`: Date
**🔶 struct SimpleProvider**: TimelineProvider
  - `func placeholder(in:)` → SimpleEntry
  - `func getSnapshot(in:completion:)`
  - `func getTimeline(in:completion:)`
**🔶 struct ZenBoundWidgetEntryView**: View
  - `var entry`: SimpleEntry
  - `var body`: some View
  - `VStack {
            Image(systemName: "timer")
                .font(.largeTitle)
            Text("ZenBound")
                .font(.caption)
        }
        .containerBackground` (call)
