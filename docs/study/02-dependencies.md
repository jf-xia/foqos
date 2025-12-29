# 02 — Dependencies

## Context
Inspected:
- SwiftPM lockfile: [foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved](../../foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved)
- Xcode project: [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)
- Source evidence for imports:
  - [Foqos/Components/Strategy/QRCodeScanner.swift](../../Foqos/Components/Strategy/QRCodeScanner.swift)
  - [Foqos/Utils/PhysicalReader.swift](../../Foqos/Utils/PhysicalReader.swift)
  - [Foqos/Utils/NFCScannerUtil.swift](../../Foqos/Utils/NFCScannerUtil.swift)
  - [Foqos/Utils/RequestAuthorizer.swift](../../Foqos/Utils/RequestAuthorizer.swift)
  - [FoqosWidget/FoqosWidgetLiveActivity.swift](../../FoqosWidget/FoqosWidgetLiveActivity.swift)
  - [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](../../FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift)
  - [FoqosShieldConfig/ShieldConfigurationExtension.swift](../../FoqosShieldConfig/ShieldConfigurationExtension.swift)
- Product-level summary: [README.md](../../README.md)

Notes:
- This repo contains a SwiftPM `Package.resolved`, but no `Package.swift`; dependencies are configured in Xcode and resolved by SwiftPM.

## Confirmed

### 1) Dependency manager detection (Confirmed)

- Swift Package Manager (SwiftPM) is used.
  - Evidence: [foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved](../../foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved)
  - Evidence: [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj) contains `XCRemoteSwiftPackageReference` / `XCSwiftPackageProductDependency` entries.
- CocoaPods is not used in this repo (no `Podfile` / `Podfile.lock` present).
- Carthage is not used in this repo (no `Cartfile` / `Cartfile.resolved` present).

### 2) Third-party dependencies

#### CodeScanner
- Name: CodeScanner
- Where declared:
  - SwiftPM pin: [foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved](../../foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved)
    - Identity: `codescanner`
    - Location: `https://github.com/twostraws/CodeScanner`
    - Version: `2.5.2` (revision pinned)
  - Xcode SwiftPM reference: [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)
    - `repositoryURL = "https://github.com/twostraws/CodeScanner"`
    - requirement: `upToNextMajorVersion` with `minimumVersion = 2.5.2`
- Where used (examples):
  - `import CodeScanner` in [Foqos/Components/Strategy/QRCodeScanner.swift](../../Foqos/Components/Strategy/QRCodeScanner.swift)
  - `import CodeScanner` in [Foqos/Utils/PhysicalReader.swift](../../Foqos/Utils/PhysicalReader.swift)
  - `import CodeScanner` in QR strategy models (e.g. [Foqos/Models/Strategies/QRManualBlockingStrategy.swift](../../Foqos/Models/Strategies/QRManualBlockingStrategy.swift))
- Why it exists (capability):
  - Provides a SwiftUI-friendly QR scanning view used for “QR Blocking” flows (also called out in [README.md](../../README.md)).
- Risk / upgrade notes:
  - Permissions: QR scanning implies camera usage; the project injects `NSCameraUsageDescription` via build settings in [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj).
  - Supply-chain: as an external package, updates should be reviewed (especially major versions) for API changes and camera/session handling changes.
  - Removal path (fallback): if CodeScanner becomes problematic, a replacement would likely be a small in-house wrapper on `AVFoundation` (Unconfirmed; depends on desired UI/UX parity).

### 3) Apple framework hotspots

This project leans heavily on Apple “Screen Time / Family Controls” APIs plus SwiftUI + extensions.

- SwiftUI
  - Hotspots: almost all UI code (e.g. [Foqos/foqosApp.swift](../../Foqos/foqosApp.swift), [Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift), widget & extension views)
- SwiftData
  - Hotspots: app + intents using persistence (e.g. [Foqos/foqosApp.swift](../../Foqos/foqosApp.swift), [Foqos/Intents/StartProfileIntent.swift](../../Foqos/Intents/StartProfileIntent.swift))
- FamilyControls
  - Hotspots: profile selection + authorization + blocking UI (e.g. [Foqos/Views/HomeView.swift](../../Foqos/Views/HomeView.swift), [Foqos/Utils/RequestAuthorizer.swift](../../Foqos/Utils/RequestAuthorizer.swift), [FoqosWidget/Views/ProfileWidgetEntryView.swift](../../FoqosWidget/Views/ProfileWidgetEntryView.swift))
- DeviceActivity
  - Hotspots: monitoring extension + debugging (e.g. [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](../../FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift), [Foqos/Views/DebugView.swift](../../Foqos/Views/DebugView.swift))
- ManagedSettings / ManagedSettingsUI
  - Hotspots: shielding + app/web blocking (e.g. [Foqos/Utils/AppBlockerUtil.swift](../../Foqos/Utils/AppBlockerUtil.swift), [FoqosShieldConfig/ShieldConfigurationExtension.swift](../../FoqosShieldConfig/ShieldConfigurationExtension.swift))
- CoreNFC
  - Hotspots: NFC tag scanning/writing + “physical unblock” flows (e.g. [Foqos/Utils/NFCScannerUtil.swift](../../Foqos/Utils/NFCScannerUtil.swift), [Foqos/Utils/NFCWriter.swift](../../Foqos/Utils/NFCWriter.swift), [Foqos/Utils/PhysicalReader.swift](../../Foqos/Utils/PhysicalReader.swift))
- ActivityKit + WidgetKit
  - Hotspots: Live Activities & widget extension (e.g. [FoqosWidget/FoqosWidgetLiveActivity.swift](../../FoqosWidget/FoqosWidgetLiveActivity.swift), [FoqosWidget/FoqosWidgetBundle.swift](../../FoqosWidget/FoqosWidgetBundle.swift))
- AppIntents
  - Hotspots: App Intents / Shortcuts glue (e.g. [Foqos/Intents/StartProfileIntent.swift](../../Foqos/Intents/StartProfileIntent.swift), [FoqosWidget/ProfileSelectionIntent.swift](../../FoqosWidget/ProfileSelectionIntent.swift))
- BackgroundTasks + UserNotifications
  - Hotspots: timers, background processing, notifications (e.g. [Foqos/foqosApp.swift](../../Foqos/foqosApp.swift), [Foqos/Utils/TimersUtil.swift](../../Foqos/Utils/TimersUtil.swift))
- StoreKit
  - Hotspots: ratings/tips/in-app purchase related surfaces (e.g. [Foqos/Utils/RatingManager.swift](../../Foqos/Utils/RatingManager.swift), [Foqos/Utils/TipManager.swift](../../Foqos/Utils/TipManager.swift), and `Tip for developer.storekit`)
- Charts
  - Hotspots: insights UI (e.g. [Foqos/Views/ProfileInsightsView.swift](../../Foqos/Views/ProfileInsightsView.swift))
- CoreImage
  - Hotspots: QR code generation UI (e.g. [Foqos/Components/Strategy/QRCodeView.swift](../../Foqos/Components/Strategy/QRCodeView.swift))
- OSLog
  - Hotspots: monitoring/logging (e.g. [FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift](../../FoqosDeviceMonitor/DeviceActivityMonitorExtension.swift), [Foqos/Models/Timers/TimerActivity.swift](../../Foqos/Models/Timers/TimerActivity.swift))

### 4) Upgrade and risk notes (project-level)

- Deployment targets are high and differ by target (Confirmed):
  - Main app target `foqos`: `IPHONEOS_DEPLOYMENT_TARGET = 17.6` in [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj)
  - Widget extension: `IPHONEOS_DEPLOYMENT_TARGET = 18.2`
  - Shield config extension: `IPHONEOS_DEPLOYMENT_TARGET = 18.5`
  - Device monitor extension: `IPHONEOS_DEPLOYMENT_TARGET = 18.0`
  - Risk: this can be intentional, but it can also lead to surprising App Store compatibility and build matrix constraints if not managed deliberately.
- README states `iOS 16.0+`, but pbxproj shows `17.6+` for the app target (Confirmed mismatch).
  - Evidence: Requirements section in [README.md](../../README.md) vs build settings in [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj).
- The core feature set depends on Screen Time / Family Controls APIs (Confirmed via imports and entitlements).
  - Risk: these APIs can be sensitive to entitlement correctness and OS behavior changes; regression testing across iOS versions is important.

## Unconfirmed

- Whether there are any additional third-party dependencies pulled indirectly via the CodeScanner package (Package.resolved lists only one top-level pin; transitive dependencies would appear as additional pins if present).
- Whether any dependency is conditionally included for specific build configurations (Debug/Release) beyond what is visible in the inspected pbxproj excerpts.

## How to confirm

- Confirm all SwiftPM dependencies (including transitives):
  - Re-check [foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved](../../foqos.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved) for multiple `pins`.
- Confirm which targets link which packages:
  - In [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj), search for `packageProductDependencies` under each `PBXNativeTarget`.
- Confirm Apple frameworks “hotspots” and call sites:
  - Search Swift sources for `import DeviceActivity|FamilyControls|ManagedSettings|CoreNFC|ActivityKit|WidgetKit|SwiftData|AppIntents`.
- Confirm and reconcile deployment targets vs README:
  - Inspect `XCBuildConfiguration` blocks for each target in [foqos.xcodeproj/project.pbxproj](../../foqos.xcodeproj/project.pbxproj) and decide what the public minimum iOS version should be.

## Key takeaways

- Dependency surface is intentionally small: SwiftPM + a single third-party package (CodeScanner).
- Most complexity (and risk) comes from Apple system frameworks/capabilities: Family Controls / DeviceActivity / ManagedSettings + extensions (Widget, Shield, Monitor).
- There is a documented minimum iOS version mismatch (README vs pbxproj) worth resolving.
