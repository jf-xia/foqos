# 06 — Clone Guide — Blocked Profile Sessions (SwiftData + FamilyControls)

## Context
Inspected:
- Project / build settings:
  - `foqos.xcodeproj/project.pbxproj`
- Entitlements:
  - `Foqos/foqos.entitlements`
  - `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`
  - `FoqosShieldConfig/FoqosShieldConfig.entitlements`
  - `FoqosWidget/FoqosWidgetExtension.entitlements`
- Shared data + snapshots:
  - `Foqos/Models/Shared.swift`
  - `Foqos/Models/BlockedProfiles.swift`
  - `Foqos/Models/BlockedProfileSessions.swift`
  - `Foqos/Models/Schedule.swift`
- Blocking + timers:
  - `Foqos/Utils/AppBlockerUtil.swift`
  - `Foqos/Utils/DeviceActivityCenterUtil.swift`
  - `Foqos/Models/Timers/TimerActivityUtil.swift`
  - `Foqos/Models/Timers/ScheduleTimerActivity.swift`
  - `Foqos/Models/Timers/BreakTimerActivity.swift`
  - `Foqos/Models/Timers/StrategyTimerActivity.swift`
- Extension entrypoints:
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
  - `FoqosShieldConfig/ShieldConfigurationExtension.swift`
- App Intents glue:
  - `Foqos/Intents/BlockedProfileEntity.swift`
  - `Foqos/Intents/StartProfileIntent.swift`
  - `Foqos/Intents/StopProfileIntent.swift`
  - `Foqos/Intents/CheckSessionActiveIntent.swift`
  - `Foqos/Intents/CheckProfileStatusIntent.swift`
  - `Foqos/foqosApp.swift`

---

## 1) What you’re building
A “session” abstraction around Managed Settings (screen-time style restrictions), so you can:
- Start / stop blocking for a chosen profile.
- Track sessions in SwiftData (history + current session).
- Keep extensions (DeviceActivity monitor, widgets, shield config UI) in sync via an App Group snapshot store.

### Confirmed
- A profile is stored as a SwiftData model (`BlockedProfiles`) with a `sessions` relationship to SwiftData sessions (`BlockedProfileSession`).
- A “shared session snapshot” exists in App Group UserDefaults (`SharedData.activeSharedSession`) to let extensions drive restrictions and later sync back into SwiftData.

### Unconfirmed
- Whether you want to clone the *full* feature set (schedule timer + breaks + strategy timers + widgets) or only the manual “start/stop + history” loop.

### How to confirm
- Decide clone scope:
  - Minimal: only manual sessions (`ManualBlockingStrategy`) + App Intents.
  - Full: also DeviceActivity schedules + break/strategy timers.

---

## 2) Pre-requisites

### Confirmed
**Targets / deployment targets (as configured in this repo)**
- Main app `foqos`: `IPHONEOS_DEPLOYMENT_TARGET = 17.6` in `foqos.xcodeproj/project.pbxproj`.
- Device Activity monitor extension `FoqosDeviceMonitor`: `IPHONEOS_DEPLOYMENT_TARGET = 18.0`.
- Widget extension `FoqosWidgetExtension`: `IPHONEOS_DEPLOYMENT_TARGET = 18.2`.
- Shield configuration extension `FoqosShieldConfig`: `IPHONEOS_DEPLOYMENT_TARGET = 18.5`.

**Capabilities / entitlements**
- App Group is used across all shipping targets (shared suite `group.dev.ambitionsoftware.foqos`).
  - `com.apple.security.application-groups` in:
    - `Foqos/foqos.entitlements`
    - `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`
    - `FoqosShieldConfig/FoqosShieldConfig.entitlements`
    - `FoqosWidget/FoqosWidgetExtension.entitlements`
- Screen Time / Family Controls capability is enabled for:
  - main app: `com.apple.developer.family-controls = true` in `Foqos/foqos.entitlements`
  - monitor extension: `com.apple.developer.family-controls = true` in `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`

**Required frameworks used by this feature**
- `FamilyControls`, `ManagedSettings`, `DeviceActivity` are imported across the feature code:
  - `Foqos/Models/BlockedProfiles.swift`
  - `Foqos/Utils/RequestAuthorizer.swift`
  - `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
  - `Foqos/Utils/AppBlockerUtil.swift`

**Info.plist privacy strings / build-time injected keys**
- Privacy keys are injected via `INFOPLIST_KEY_*` in `foqos.xcodeproj/project.pbxproj` (project uses `GENERATE_INFOPLIST_FILE = YES`).
  - `INFOPLIST_KEY_NSCameraUsageDescription` and `INFOPLIST_KEY_NFCReaderUsageDescription` are set for the app target.

### Unconfirmed
- Whether you can lower the deployment targets (e.g. from iOS 18.x down to iOS 16/17). The repo’s current settings are higher than the minimum API availability implied by the frameworks.

### How to confirm
- Search `foqos.xcodeproj/project.pbxproj` for `IPHONEOS_DEPLOYMENT_TARGET` under each `XCBuildConfiguration` block.
- Check entitlements for App Group + Family Controls:
  - `Foqos/foqos.entitlements`
  - `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`
- Verify runtime authorization flow:
  - `Foqos/Utils/RequestAuthorizer.swift` uses `AuthorizationCenter.shared.requestAuthorization(for: .individual)`.

---

## 3) Architecture sketch

### Confirmed
**State ownership**
- App-level “blocking state” is owned by `StrategyManager.shared`:
  - `StrategyManager.activeSession: BlockedProfileSession?`
  - `StrategyManager.isBlocking` computed from `activeSession?.isActive`.
- Extensions do *not* read SwiftData directly; they read App Group snapshots:
  - Profiles: `SharedData.profileSnapshots`
  - Active session: `SharedData.activeSharedSession`

**Data model**
- SwiftData:
  - `BlockedProfiles` (profile + selection + options + schedule + sessions)
  - `BlockedProfileSession` (start/end/break times + `forceStarted`)
- App Group snapshots (Codable):
  - `SharedData.ProfileSnapshot`
  - `SharedData.SessionSnapshot`

**Side-effect boundary (where restrictions actually change)**
- Restrictions are applied / removed through `AppBlockerUtil` using `ManagedSettingsStore`:
  - `AppBlockerUtil.activateRestrictions(for: SharedData.ProfileSnapshot)`
  - `AppBlockerUtil.deactivateRestrictions()`
- Entry points that trigger side effects:
  - Manual start/stop in app via strategies (e.g. `ManualBlockingStrategy`).
  - DeviceActivity callbacks in the monitor extension:
    - `DeviceActivityMonitorExtension.intervalDidStart/intervalDidEnd` calls `TimerActivityUtil.startTimerActivity/stopTimerActivity`.

**Sync boundary (extensions → app SwiftData)**
- `StrategyManager.getActiveSession()` calls `syncScheduleSessions()` before fetching SwiftData’s active session.
- `syncScheduleSessions()` upserts `SharedData.SessionSnapshot` into SwiftData via `BlockedProfileSession.upsertSessionFromSnapshot(...)` and then flushes completed snapshots.

### Unconfirmed
- Whether you want shared snapshots to be the “source of truth” (as in schedules) for *all* sessions, or only for extension-driven sessions.

### How to confirm
- Follow the snapshot flow:
  - Profile snapshot creation: `BlockedProfiles.updateSnapshot(for:)` in `Foqos/Models/BlockedProfiles.swift`.
  - Session snapshot creation: `BlockedProfileSession.createSession(...)` in `Foqos/Models/BlockedProfileSessions.swift`.
  - Extension timers writing snapshots: `Foqos/Models/Timers/*.swift`.
  - App sync from snapshots: `StrategyManager.syncScheduleSessions(...)` in `Foqos/Utils/StrategyManager.swift`.

---

## 4) Step-by-step implementation
These steps describe how to implement a similar “session + restrictions” feature by cloning the patterns from this repo.

### Minimal happy path (manual start/stop + history)
1. Create SwiftData models:
   - Profile model similar to `BlockedProfiles`.
   - Session model similar to `BlockedProfileSession`.
2. Add a shared snapshot store (App Group UserDefaults) similar to `SharedData`:
   - Store a `ProfileSnapshot` keyed by profile UUID string.
   - Store `activeSharedSession` as a `SessionSnapshot`.
3. Implement the restriction toggler (the side-effect boundary):
   - Clone `AppBlockerUtil` and decide your policy mapping from selection → `ManagedSettingsStore`.
4. Implement “start session”:
   - Write profile snapshot first (`updateSnapshot(for:)`) so extensions can read it.
   - Activate restrictions (`AppBlockerUtil.activateRestrictions`).
   - Create SwiftData session via a helper like `BlockedProfileSession.createSession` that also writes `SharedData.activeSharedSession`.
5. Implement “stop session”:
   - End the SwiftData session (set `endTime`).
   - Deactivate restrictions.
   - Flush `SharedData.activeSharedSession`.

### Extension-driven path (schedule / break / timers)
1. Add a DeviceActivity monitor extension (like `FoqosDeviceMonitor`).
2. When DeviceActivity intervals start/end, dispatch by activity name:
   - Clone `TimerActivityUtil` name-parsing logic.
3. For each timer type, implement a `TimerActivity`:
   - Schedule timer: create/close shared sessions + toggle restrictions (`ScheduleTimerActivity`).
   - Break timer: temporarily remove restrictions and set `breakStartTime` / `breakEndTime` (`BreakTimerActivity`).
   - Strategy timer: ensure restrictions start/stop and end shared session (`StrategyTimerActivity`).
4. In the app, sync snapshots back into SwiftData:
   - Clone `StrategyManager.syncScheduleSessions` + `BlockedProfileSession.upsertSessionFromSnapshot`.

### Edge cases (from this repo)
- If a schedule interval starts while another shared session exists:
  - `ScheduleTimerActivity.start(for:)` ends the existing shared session if it belongs to a different profile.
- Backward compatibility in activity name format:
  - `TimerActivityUtil.getTimerParts(from:)` supports both `type:profileId` and legacy `profileId` naming.
- Schedule gating:
  - `ScheduleTimerActivity.start(for:)` checks `schedule.isTodayScheduled()` and `schedule.olderThan15Minutes()`.

### Unconfirmed
- Whether you want to persist extension-driven sessions as SwiftData sessions *immediately* (as this repo does when the app reads state) vs asynchronously via background refresh.

### How to confirm
- Review the concrete implementations:
  - Manual flow: `Foqos/Models/Strategies/ManualBlockingStrategy.swift`
  - Extension callback: `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`
  - Timer dispatch: `Foqos/Models/Timers/TimerActivityUtil.swift`
  - Schedule/break/strategy behaviors: `Foqos/Models/Timers/*.swift`

---

## 5) Testing strategy

### Confirmed
- The project defines `foqosTests` and `foqosUITests` targets in `foqos.xcodeproj/project.pbxproj`, but no test sources were found in the workspace at the time of inspection.

### Unconfirmed
- The repo currently has no automated coverage for:
  - snapshot encoding/decoding,
  - restriction toggling policy mapping,
  - timer name parsing compatibility.

### How to confirm
- Search for test sources:
  - `**/*Tests*/*.swift`

Suggested tests (if you add them):
- Unit test `SharedData` encoding/decoding and key behaviors (active + completed sessions).
- Unit test `TimerActivityUtil.getTimerParts(from:)` for both naming formats.
- Unit test `BlockedProfileSession.upsertSessionFromSnapshot` for update vs insert.

---

## 6) Common pitfalls

### Confirmed
- App Intents depend on a SwiftData `ModelContainer` injected via `AppDependencyManager`:
  - `foqosApp.init()` registers a `ModelContainer` dependency.
  - Intents use `@Dependency(key: "ModelContainer")`.
- Extension lifecycle constraints: the monitor extension reacts to DeviceActivity interval callbacks and must be able to toggle restrictions without the main app running.
- Shared-data correctness matters: extensions read from `UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos")`.

### Unconfirmed
- Whether the “18.x” deployment targets are required due to other features not covered in this guide.

### How to confirm
- Trace App Intent dependency wiring:
  - `Foqos/foqosApp.swift`
  - `Foqos/Intents/*.swift`
- Verify all targets that participate in the feature have the same App Group:
  - `*.entitlements`

---

## Key takeaways
- In this codebase, SwiftData is the app’s persistence, but App Group snapshots are the cross-target integration layer.
- The **only** place restrictions change is `AppBlockerUtil` (ManagedSettingsStore). Everything else should funnel into that boundary.
- Extension-driven sessions are persisted by: (1) extension writes shared snapshots, (2) app syncs snapshots into SwiftData when it next loads active state.
