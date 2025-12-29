# Foqos/Views/BlockedProfileView.swift

## Context
- Inspected: `Foqos/Views/BlockedProfileView.swift`
- Primary role: Create/edit UI for a profile, including app/domain selection, schedule, strategy, reminders, strict unlocks (NFC/QR), and duplication.

## Confirmed

### Purpose
- Provides a form-driven UI for:
  - Creating a new `BlockedProfiles` entry
  - Editing an existing profile
  - Writing profile deep link to NFC
  - Generating a QR deep link
  - Duplicating a profile
  - Deleting a profile
  - Viewing profile insights
- Disables editing controls when a blocking session is active.

### Key types/functions
- `struct AlertIdentifier: Identifiable`
  - Used to multiplex error + delete confirmation alerts.
- `struct BlockedProfileView: View`
  - Environment:
    - `@Environment(\.modelContext) var modelContext`
    - `@Environment(\.dismiss) var dismiss`
    - `@EnvironmentObject var themeManager: ThemeManager`
    - `@EnvironmentObject var nfcWriter: NFCWriter`
    - `@EnvironmentObject var strategyManager: StrategyManager`
  - Input:
    - `var profile: BlockedProfiles?` (nil ⇒ create)
  - State mirrors profile fields:
    - Name, selected activity, allow modes, Safari blocking, domains, schedule, strict/break/reminder settings, physical unlock ids, etc.
  - Key computed:
    - `isEditing` = `profile != nil`
    - `isBlocking` = `strategyManager.activeSession?.isActive ?? false`
  - Init seeds state from `profile` or defaults; also resolves selected strategy via `StrategyManager.getStrategyFromId`.
- UI structure (selected highlights):
  - Shows banner when `isBlocking`.
  - Shows `ScheduleWarningPrompt` if `profile?.scheduleIsOutOfSync == true`.
  - Sections:
    - Name (text field)
    - Apps: `BlockedProfileAppSelector` + toggles for allow mode and Safari blocking
    - Domains: `BlockedProfileDomainSelector` + allow mode toggle
    - Strategy: `BlockingStrategyList`
    - Schedule: `BlockedProfileScheduleSelector` → `SchedulePicker` sheet
    - Breaks: toggle + duration picker
    - Safeguards: strict + disable background stops
    - Strict Unlocks: `BlockedProfilePhysicalUnblockSelector` (sets NFC/QR ids)
    - Notifications: Live Activity + Reminder (with time + message)
      - “Go to settings” button opens `UIApplication.openSettingsURLString` when not blocking
  - `.onChange(of: enableAllowMode)` resets `selectedActivity` to `FamilyActivitySelection(includeEntireCategory: newValue)`
  - Toolbar:
    - Cancel (dismiss)
    - If editing and not blocking: menu (write NFC, generate QR, duplicate, delete) + insights button
    - Save/Create checkmark when not blocking
  - Sheets:
    - `AppPicker`, `DomainPicker`, `SchedulePicker`
    - QR code: `QRCodeView(url: BlockedProfiles.getProfileDeepLink(...), profileName: ...)`
    - Insights: `ProfileInsightsView(profile: ...)`
    - Physical unblock: wraps `physicalReader.readQRCode(...)` in `BlockingStrategyActionView`
  - Alerts:
    - Error alert with message
    - Delete confirmation, calls `BlockedProfiles.deleteProfile(profileToDelete, in: modelContext)` then dismisses
  - Duplication flow:
    - Uses `TextFieldAlert` to enter name, then `BlockedProfiles.cloneProfile(...)` and `DeviceActivityCenterUtil.scheduleTimerActivity(for:)`
- Save logic:
  - `saveProfile()`:
    - Updates `schedule.updatedAt = Date()`
    - Computes reminder seconds or nil
    - If editing: `BlockedProfiles.updateProfile(...)` then `DeviceActivityCenterUtil.scheduleTimerActivity(for: updatedProfile)`
    - If creating: `BlockedProfiles.createProfile(...)` then `DeviceActivityCenterUtil.scheduleTimerActivity(for: newProfile)`
    - Dismisses on success
- NFC write:
  - `writeProfile()` writes the profile deep link via `nfcWriter.writeURL(url)`

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `SwiftData`, `FamilyControls`, `Foundation`
- Collaborators referenced (non-exhaustive):
  - Model/types: `BlockedProfiles`, `BlockedProfileSchedule`, `BlockingStrategy`, `NFCBlockingStrategy`
  - Managers/utils: `ThemeManager`, `NFCWriter`, `StrategyManager`, `DeviceActivityCenterUtil`, `PhysicalReader`
  - Views/components: `BlockedProfileAppSelector`, `BlockedProfileDomainSelector`, `BlockingStrategyList`, `BlockedProfileScheduleSelector`, `ScheduleWarningPrompt`, `BlockedProfilePhysicalUnblockSelector`, `AppPicker`, `DomainPicker`, `SchedulePicker`, `QRCodeView`, `ProfileInsightsView`, `BlockingStrategyActionView`, `TextFieldAlert`, `CustomToggle`, `ActionButton` (and others)

### Side-effects
- SwiftData writes via `BlockedProfiles.updateProfile/createProfile/deleteProfile/cloneProfile`.
- Schedules DeviceActivity timer activities via `DeviceActivityCenterUtil.scheduleTimerActivity(for:)`.
- Opens Settings app via `UIApplication.shared.open(...)`.
- NFC write via `NFCWriter.writeURL`.
- QR scan/read via `PhysicalReader.readNFCTag` and `PhysicalReader.readQRCode`.

### Invariants
- Editing is disabled if any session is active (`isBlocking`), enforced by UI disabled states and hiding save.
- Reminder message is truncated to max 178 chars.
- When enabling Apps Allow Mode, selection is replaced with `FamilyActivitySelection(includeEntireCategory: true)` (clears prior selection).

### Suggested comments/docstrings (suggestions only)
- Document why the “blocking” gate uses `strategyManager.activeSession?.isActive` and whether it should be profile-specific.
- Add a short doc comment to `scheduleIsOutOfSync` UI (“Apply” button) describing what it does.
- Consider documenting the meaning/format of `physicalUnblockNFCTagId` and `physicalUnblockQRCodeId`.

## Unconfirmed
- Exact meaning of `disableBackgroundStops` (enforced where?) beyond being stored on the model.
- Whether schedule timer activities are the only schedule mechanism.

## How to confirm
- Search for `disableBackgroundStops` usage.
- Inspect `DeviceActivityCenterUtil.scheduleTimerActivity(for:)` and any “out of sync” remediation code.
- Inspect `PhysicalReader`, `NFCWriter`, and strict unlock logic in strategies.

## Key takeaways
- This is the main “profile editor” screen and a major integration point for DeviceActivity + NFC/QR.
- Save operations always reschedule the profile’s timer activities.
