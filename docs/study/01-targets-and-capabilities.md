# 01 — Targets & Capabilities

## Context
Inspected:
- `foqos.xcodeproj/project.pbxproj`
- Entitlements:
  - `Foqos/foqos.entitlements`
  - `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`
  - `FoqosShieldConfig/FoqosShieldConfig.entitlements`
  - `FoqosWidget/FoqosWidgetExtension.entitlements`
- Target Info.plists:
  - `Foqos/Info.plist`
  - `FoqosDeviceMonitor/Info.plist`
  - `FoqosShieldConfig/Info.plist`
  - `FoqosWidget/Info.plist`
- Evidence for shared-data usage and Live Activity widget:
  - `Foqos/Models/Shared.swift`
  - `Foqos/Utils/ThemeManager.swift`
  - `FoqosShieldConfig/ShieldConfigurationExtension.swift`
  - `FoqosWidget/FoqosWidgetLiveActivity.swift`

Notes:
- All targets shown here have `GENERATE_INFOPLIST_FILE = YES` in `project.pbxproj`, so some Info.plist keys are injected via build settings (e.g. `INFOPLIST_KEY_NSCameraUsageDescription`).
- `project.pbxproj` uses lowercase paths like `foqos/Info.plist` and `foqos/foqos.entitlements`, while the repo folder on disk is `Foqos/…`. On macOS this often works (case-insensitive FS), but it’s a real portability/CI risk on case-sensitive file systems.

## Confirmed

### Targets table

| Target name            | Product type (pbxproj `productType`)                   | Bundle ID (pbxproj `PRODUCT_BUNDLE_IDENTIFIER`) | Info.plist (pbxproj `INFOPLIST_FILE`) | Entitlements (pbxproj `CODE_SIGN_ENTITLEMENTS`)      |
| ---------------------- | ------------------------------------------------------ | ----------------------------------------------- | ------------------------------------- | ---------------------------------------------------- |
| `foqos`                | Application (`com.apple.product-type.application`)     | `dev.ambitionsoftware.foqos`                    | `foqos/Info.plist`                    | `foqos/foqos.entitlements`                           |
| `FoqosDeviceMonitor`   | App Extension (`com.apple.product-type.app-extension`) | `dev.ambitionsoftware.foqos.FoqosDeviceMonitor` | `FoqosDeviceMonitor/Info.plist`       | `FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements` |
| `FoqosShieldConfig`    | App Extension (`com.apple.product-type.app-extension`) | `dev.ambitionsoftware.foqos.FoqosShieldConfig`  | `FoqosShieldConfig/Info.plist`        | `FoqosShieldConfig/FoqosShieldConfig.entitlements`   |
| `FoqosWidgetExtension` | App Extension (`com.apple.product-type.app-extension`) | `dev.ambitionsoftware.foqos.FoqosWidget`        | `FoqosWidget/Info.plist`              | `FoqosWidget/FoqosWidgetExtension.entitlements`      |
| `foqosTests`           | Unit Tests (`com.apple.product-type.bundle.unit-test`) | `dev.ambitionsoftware.foqosTests`               | (generated; no `INFOPLIST_FILE` set)  | (none)                                               |
| `foqosUITests`         | UI Tests (`com.apple.product-type.bundle.ui-testing`)  | `dev.ambitionsoftware.foqosUITests`             | (generated; no `INFOPLIST_FILE` set)  | (none)                                               |

### Capabilities / Entitlements by target

#### `foqos` (main app)
Entitlements (`Foqos/foqos.entitlements`):
- App Groups: `group.dev.ambitionsoftware.foqos` (`com.apple.security.application-groups`)
- Family Controls: enabled (`com.apple.developer.family-controls = true`)
- NFC tag scanning: `TAG` format (`com.apple.developer.nfc.readersession.formats`)
- Associated Domains: `applinks:foqos.app` (`com.apple.developer.associated-domains`)
- Also present in entitlements:
  - `com.apple.security.app-sandbox = true`
  - `com.apple.security.files.user-selected.read-only = true`

Info.plist / build-settings (from `project.pbxproj` + `Foqos/Info.plist`):
- Background Modes: `fetch`, `processing` (`UIBackgroundModes` in `Foqos/Info.plist`)
- BGTask identifiers: `com.foqos.backgroundprocessing` (`BGTaskSchedulerPermittedIdentifiers` in `Foqos/Info.plist`)
- Live Activities support: enabled via `INFOPLIST_KEY_NSSupportsLiveActivities = YES` (pbxproj)

#### `FoqosDeviceMonitor` (Device Activity monitor extension)
Info.plist (`FoqosDeviceMonitor/Info.plist`):
- Extension point: `com.apple.deviceactivity.monitor-extension`

Entitlements (`FoqosDeviceMonitor/FoqosDeviceMonitor.entitlements`):
- App Groups: `group.dev.ambitionsoftware.foqos`
- Family Controls: enabled (`com.apple.developer.family-controls = true`)

Code evidence:
- Imports `DeviceActivity` and `ManagedSettings` in `FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift`.

#### `FoqosShieldConfig` (Managed Settings shield configuration extension)
Info.plist (`FoqosShieldConfig/Info.plist`):
- Extension point: `com.apple.ManagedSettingsUI.shield-configuration-service`

Entitlements (`FoqosShieldConfig/FoqosShieldConfig.entitlements`):
- App Groups: `group.dev.ambitionsoftware.foqos`

Code evidence:
- Uses `ThemeManager.shared.themeColor` inside `ShieldConfigurationExtension` (see `FoqosShieldConfig/ShieldConfigurationExtension.swift`), implying a shared theme preference (see “Shared data boundaries”).

#### `FoqosWidgetExtension` (WidgetKit extension)
Info.plist (`FoqosWidget/Info.plist`):
- Extension point: `com.apple.widgetkit-extension`

Entitlements (`FoqosWidget/FoqosWidgetExtension.entitlements`):
- App Groups: `group.dev.ambitionsoftware.foqos`

Code evidence:
- Live Activity widget exists: `FoqosWidget/FoqosWidgetLiveActivity.swift` uses `ActivityKit` and `ActivityConfiguration`.
- Widget reads shared profile/session snapshots via `SharedData` in multiple widget files (e.g. `FoqosWidget/ProfileSelectionIntent.swift`, `FoqosWidget/Providers/ProfileControlProvider.swift`).

#### `foqosTests`, `foqosUITests`
- No entitlements configured in pbxproj.
- Product types are test bundles (unit/UI).

### Privacy strings checklist (expected Info.plist keys)

Because `GENERATE_INFOPLIST_FILE = YES`, verify both:
- `Foqos/Info.plist` (checked into repo)
- `project.pbxproj` build settings (`INFOPLIST_KEY_*`) that inject keys at build time

| Capability / feature        | Expected key(s)                                               | Status    | Where it’s set / how it’s derived                                                                                                       |
| --------------------------- | ------------------------------------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| NFC tag scanning            | `NFCReaderUsageDescription`                                   | Confirmed | `project.pbxproj` has `INFOPLIST_KEY_NFCReaderUsageDescription = "This app uses NFC to scan tags for item identification."`             |
| Camera (QR scanning)        | `NSCameraUsageDescription`                                    | Confirmed | `project.pbxproj` has `INFOPLIST_KEY_NSCameraUsageDescription = "We need camera access to scan QR codes to active/deactivate profiles"` |
| Live Activities             | `NSSupportsLiveActivities`                                    | Confirmed | `project.pbxproj` has `INFOPLIST_KEY_NSSupportsLiveActivities = YES`                                                                    |
| Background processing/fetch | `UIBackgroundModes` and `BGTaskSchedulerPermittedIdentifiers` | Confirmed | `Foqos/Info.plist` includes both keys                                                                                                   |

### Shared data boundaries

Confirmed shared container / suite:
- All shipping (non-test) targets include the same App Group in entitlements:
  - `group.dev.ambitionsoftware.foqos`

Confirmed shared UserDefaults suite usage:
- `Foqos/Models/Shared.swift` stores snapshots in `UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos")`.
- `Foqos/Utils/ThemeManager.swift` uses `@AppStorage(..., store: UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos"))`.
- `FoqosShieldConfig/ShieldConfigurationExtension.swift` reads `ThemeManager.shared.themeColor`, implying the shield extension can reflect the user’s theme via the App Group suite.
- The widget extension references `SharedData` (e.g. `SharedData.profileSnapshots`), implying the widget reads the app’s persisted snapshots.

## Unconfirmed

- Whether `com.apple.security.app-sandbox` / `com.apple.security.files.user-selected.read-only` (present in `Foqos/foqos.entitlements`) are intended for any non-iOS build variant, or are simply leftover keys.
- Whether the project uses Push Notifications (no `aps-environment` key found in the inspected entitlements).
- Whether the project uses iCloud / Keychain sharing / Sign in with Apple capabilities (no such entitlements observed in the inspected `.entitlements` files).
- Whether the Device Activity monitor extension reads/writes shared state via the App Group (the extension has the App Group entitlement, but `DeviceActivityMonitorExtension.swift` doesn’t show `UserDefaults(suiteName:)` usage).
- Whether the lowercase `foqos/...` paths in `project.pbxproj` cause build failures on case-sensitive file systems (they won’t on most developer Macs, but can in CI).

## How to confirm

- Push notifications:
  - Search entitlements for `aps-environment`.
- iCloud / Keychain sharing / other capabilities:
  - Search entitlements for `com.apple.developer.icloud-*`, `keychain-access-groups`, `com.apple.developer.applesignin`.
- Sandbox-related entitlements relevance:
  - Check `SUPPORTED_PLATFORMS` / `SUPPORTS_MACCATALYST` and whether any macOS target exists in `project.pbxproj`.
  - Inspect build settings per configuration for `CODE_SIGN_ENTITLEMENTS` and platform-specific overrides.
- Device monitor shared state:
  - Search `FoqosDeviceMonitor/**/*.swift` for `UserDefaults(suiteName:` and `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:`.
- Case-sensitive path risk:
  - Try building on a case-sensitive APFS volume (or CI runner configured as such) and watch for missing file errors referencing `foqos/Info.plist` or `foqos/foqos.entitlements`.

## Key takeaways

- Targets: 1 app (`foqos`), 3 app extensions (DeviceActivity monitor, ManagedSettingsUI shield config, WidgetKit), plus unit/UI test bundles.
- All shipping targets share a single App Group: `group.dev.ambitionsoftware.foqos`.
- The app explicitly declares NFC + Camera usage descriptions via pbxproj-injected Info.plist keys, and declares background `fetch`/`processing` modes in `Foqos/Info.plist`.
- Widgets + shield configuration are wired to reflect shared state (snapshots/theme) via the App Group defaults suite.
