# AppBlockerUtil.swift

## Context
- Inspected: [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift)
- Call sites (blocking strategies):
  - [Foqos/Models/Strategies/ManualBlockingStrategy.swift](Foqos/Models/Strategies/ManualBlockingStrategy.swift#L20-L53)
  - [Foqos/Models/Strategies/NFCBlockingStrategy.swift](Foqos/Models/Strategies/NFCBlockingStrategy.swift#L20-L92)
  - [Foqos/Models/Strategies/NFCManualBlockingStrategy.swift](Foqos/Models/Strategies/NFCManualBlockingStrategy.swift#L20-L88)
  - [Foqos/Models/Strategies/QRCodeBlockingStrategy.swift](Foqos/Models/Strategies/QRCodeBlockingStrategy.swift#L20-L106)
  - [Foqos/Models/Strategies/QRManualBlockingStrategy.swift](Foqos/Models/Strategies/QRManualBlockingStrategy.swift#L20-L86)
  - [Foqos/Models/Strategies/QRTimerBlockingStrategy.swift](Foqos/Models/Strategies/QRTimerBlockingStrategy.swift#L20-L93)
  - [Foqos/Models/Strategies/NFCTimerBlockingStrategy.swift](Foqos/Models/Strategies/NFCTimerBlockingStrategy.swift#L20-L94)
- Call sites (DeviceActivity timer activities):
  - [Foqos/Models/Timers/ScheduleTimerActivity.swift](Foqos/Models/Timers/ScheduleTimerActivity.swift#L1-L116)
  - [Foqos/Models/Timers/StrategyTimerActivity.swift](Foqos/Models/Timers/StrategyTimerActivity.swift#L1-L76)
  - [Foqos/Models/Timers/BreakTimerActivity.swift](Foqos/Models/Timers/BreakTimerActivity.swift#L1-L78)
  - Bridge from extension: [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift#L20-L41) -> [Foqos/Models/Timers/TimerActivityUtil.swift](Foqos/Models/Timers/TimerActivityUtil.swift#L1-L62)

## Confirmed
### `activateRestrictions(for:)`
- Definition: [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L9-L48)
- Purpose: given a `SharedData.ProfileSnapshot`, computes tokens/domains from that snapshot and writes them into a named `ManagedSettingsStore` ("foqosAppRestrictions") to enforce app/category/web restrictions.
- Called when a blocking session starts in app-driven strategies:
  - Manual start: [ManualBlockingStrategy.startBlocking](Foqos/Models/Strategies/ManualBlockingStrategy.swift#L22-L41)
  - NFC start (after successful scan): [NFCBlockingStrategy.startBlocking](Foqos/Models/Strategies/NFCBlockingStrategy.swift#L23-L52)
  - QR start (after successful scan): [QRCodeBlockingStrategy.startBlocking](Foqos/Models/Strategies/QRCodeBlockingStrategy.swift#L23-L52)
  - “Manual start + physical unblock via NFC/QR”: [NFCManualBlockingStrategy.startBlocking](Foqos/Models/Strategies/NFCManualBlockingStrategy.swift#L23-L45), [QRManualBlockingStrategy.startBlocking](Foqos/Models/Strategies/QRManualBlockingStrategy.swift#L23-L44)
- Also called by timer-driven flows (DeviceActivity) to (re)apply restrictions without requiring the app UI to be foreground:
  - Scheduled sessions: [ScheduleTimerActivity.start](Foqos/Models/Timers/ScheduleTimerActivity.swift#L32-L74)
  - Strategy timers: [StrategyTimerActivity.start](Foqos/Models/Timers/StrategyTimerActivity.swift#L22-L41)
  - Ending a break re-applies restrictions: [BreakTimerActivity.stop](Foqos/Models/Timers/BreakTimerActivity.swift#L41-L76)

### `deactivateRestrictions()`
- Definition: [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L50-L63)
- Purpose: clears the same `ManagedSettingsStore` fields (`shield.*`, `webContent.blockedByFilter`, `denyAppRemoval`) and calls `store.clearAllSettings()`.
- Called when a session ends in app-driven strategies:
  - Manual stop: [ManualBlockingStrategy.stopBlocking](Foqos/Models/Strategies/ManualBlockingStrategy.swift#L43-L53)
  - NFC stop (after scan + validation): [NFCBlockingStrategy.stopBlocking](Foqos/Models/Strategies/NFCBlockingStrategy.swift#L55-L91)
  - QR stop (after scan + validation): [QRCodeBlockingStrategy.stopBlocking](Foqos/Models/Strategies/QRCodeBlockingStrategy.swift#L55-L105)
  - “Manual start + physical unblock”: [NFCManualBlockingStrategy.stopBlocking](Foqos/Models/Strategies/NFCManualBlockingStrategy.swift#L47-L86), [QRManualBlockingStrategy.stopBlocking](Foqos/Models/Strategies/QRManualBlockingStrategy.swift#L46-L85)
  - Timer strategies’ stop UI also clears restrictions: [QRTimerBlockingStrategy.stopBlocking](Foqos/Models/Strategies/QRTimerBlockingStrategy.swift#L60-L92), [NFCTimerBlockingStrategy.stopBlocking](Foqos/Models/Strategies/NFCTimerBlockingStrategy.swift#L55-L94)
- Also called by timer-driven flows:
  - Scheduled sessions end: [ScheduleTimerActivity.stop](Foqos/Models/Timers/ScheduleTimerActivity.swift#L76-L99)
  - Strategy timers end: [StrategyTimerActivity.stop](Foqos/Models/Timers/StrategyTimerActivity.swift#L43-L70)
  - Starting a break disables restrictions: [BreakTimerActivity.start](Foqos/Models/Timers/BreakTimerActivity.swift#L22-L39)

### `getWebDomains(from:)`
- Definition: [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L65-L72)
- Purpose: maps `profile.domains: [String]?` into `Set<WebDomain>` for `store.webContent.blockedByFilter`.
- Usage: internal helper, only used by `activateRestrictions(for:)` in the same file: [Foqos/Utils/AppBlockerUtil.swift](Foqos/Utils/AppBlockerUtil.swift#L9-L18)

### Instantiations that don’t (currently) call methods
- `DeviceActivityMonitorExtension` defines `private let appBlocker = AppBlockerUtil()` but doesn’t call it directly (timer routing goes through `TimerActivityUtil`): [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift#L20-L41)
- `StrategyManager` also defines `private let appBlocker = AppBlockerUtil()` (no `.activateRestrictions` / `.deactivateRestrictions` usage found in this file): [Foqos/Utils/StrategyManager.swift](Foqos/Utils/StrategyManager.swift#L30-L40)

## Unconfirmed
- Whether the “unused” `appBlocker` properties are intentional (reserved for future use) or dead code.

## How to confirm
- Search for direct calls:
  - query: `\.activateRestrictions\b` and `\.deactivateRestrictions\b` (scope: `**/*.swift`)
- Confirm timer-driven pathway:
  - Start/end events: [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift#L20-L41)
  - Routing/parsing: [Foqos/Models/Timers/TimerActivityUtil.swift](Foqos/Models/Timers/TimerActivityUtil.swift#L1-L62)
  - Implementations: [Foqos/Models/Timers/ScheduleTimerActivity.swift](Foqos/Models/Timers/ScheduleTimerActivity.swift#L1-L116), [Foqos/Models/Timers/StrategyTimerActivity.swift](Foqos/Models/Timers/StrategyTimerActivity.swift#L1-L76), [Foqos/Models/Timers/BreakTimerActivity.swift](Foqos/Models/Timers/BreakTimerActivity.swift#L1-L78)

## Key takeaways
- `activateRestrictions` / `deactivateRestrictions` are the single choke points for turning ManagedSettings restrictions on/off, used by both UI strategies and DeviceActivity-based background timer flows.
- Timer-based strategies (like QR/NFC + Timer) start restrictions indirectly via `DeviceActivityMonitorExtension` -> `TimerActivityUtil` -> `StrategyTimerActivity.start`.
- `getWebDomains` is a local helper used only within `activateRestrictions`.
