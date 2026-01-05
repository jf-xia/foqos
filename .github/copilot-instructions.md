# Foqos AI Coding Instructions

## 🏗 Architecture & Core Concepts
- **Project Type**: iOS App with Extensions (DeviceActivityMonitor, ShieldConfiguration, Widget).
- **Core Domain**: Focus/Productivity app using Apple's Screen Time API (`FamilyControls`, `ManagedSettings`, `DeviceActivity`).
- **Data Flow**:
  - **SwiftData**: Primary persistence for `BlockedProfiles` and `BlockedProfileSession`.
  - **App Groups**: Uses `UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos")` to share lightweight state (snapshots) between the main App and Extensions.
  - **State Management**: Heavily relies on `ObservableObject` singletons injected via `.environmentObject` (e.g., `RequestAuthorizer`, `StrategyManager`).

## 🧩 Key Components
- **`foqosApp.swift`**: App entry point. Sets up `ModelContainer`, `AppDependencyManager`, and injects environment objects.
- **`StrategyManager`**: Central orchestrator for focus sessions. Handles Manual, NFC, QR, and Timer strategies.
- **`AppBlockerUtil`**: Wrapper around `ManagedSettingsStore` to apply/remove restrictions.
- **`DeviceActivityMonitorExtension`**: Handles system-triggered events (interval start/end) for scheduled blocking.
- **`RequestAuthorizer`**: Manages `FamilyControls` authorization (Scope: `.individual`).

## 🛠 Developer Workflows & Patterns
- **Dependency Injection**: Use `AppDependencyManager.shared` to register and resolve dependencies (especially for `ModelContainer` in App Intents).
- **Concurrency**: Use `Task` and `MainActor` for UI updates. Most utility classes (e.g., `RequestAuthorizer`) dispatch updates to main thread explicitly.
- **Entitlements**: Features like App Blocking and NFC require specific entitlements. Always check `*.entitlements` when debugging permission issues.
- **Testing**:
  - **Simulator Limitations**: Family Controls and NFC often fail on Simulators. Prefer physical device testing for these features.
  - **Preview**: Use `Preview Content` assets for SwiftUI previews.

## ⚠️ Project-Specific Conventions
- **Shared Data**: When modifying data models, ensure `SharedData` snapshots are updated if the data needs to be accessed by Extensions.
- **Error Handling**: Most Utils print errors to console. For critical user-facing errors, expose state to the UI.
- **Universal Links**: Handled via `NavigationManager` in `foqosApp.swift`.

## 📂 Important Directories
- `Foqos/Utils/`: Core logic helpers (`AppBlockerUtil`, `NFCScannerUtil`).
- `Foqos/Models/`: SwiftData models (`BlockedProfiles`) and logic (`Strategies/`).
- `FoqosDeviceMonitor/`: Background activity monitoring logic.
- `docs/hlbpa/`: High-level architecture documentation.
