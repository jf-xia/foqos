# ScreenTime Authorization Implementation Guide

## 1. TL;DR
Implement a `ScreenTimeAuthorizer` class to handle Apple's FamilyControls authorization for **Individual** (current device) scope. This is the foundational step for any app needing to block apps or track device activity. It requires the `Family Controls` capability in Xcode and must be called early in the app lifecycle.

## 2. Contract & Non-goals
### Contract
- **Goal**: Request and maintain authorization status for the `FamilyControls` framework.
- **Scope**: Strictly `.individual` (for Focus/Productivity apps running on the user's own device).
- **Output**: Expose a reactive `isAuthorized` boolean and the raw `AuthorizationStatus` to the UI.
- **Thread Safety**: All UI updates must occur on the `MainActor`.

### Non-goals
- **Parental Controls**: Do not implement `.child` authorization or Family Sharing logic.
- **Remote Management**: No MDM or server-side profile management.
- **Complex Error Recovery**: Basic error logging is sufficient; no complex "Open Settings" deep linking logic is required for this baseline.

## 3. Usage Scenarios
### Scenario 1: First Launch Authorization
- **User Action**: User opens the app for the first time or taps a "Grant Permission" button.
- **System Behavior**: iOS presents a system sheet asking to "Allow [App] to manage restrictions on this device".
- **App Behavior**: Upon approval, `isAuthorized` becomes `true`, unlocking features.

### Scenario 2: Status Check on Resume
- **User Action**: User returns to the app after changing settings.
- **App Behavior**: The app checks `AuthorizationCenter.shared.authorizationStatus` to ensure permissions are still valid.

## 4. Reference Analysis
Based on `RequestAuthorizer.swift` and project usage:
- **Pattern**: `ObservableObject` (SwiftUI) or `@Observable` (Swift 5.9+).
- **Concurrency**: Uses `Task` and `await` for the async authorization call.
- **State Management**: Updates `isAuthorized` on `MainActor` to prevent UI glitches.
- **Dependency Injection**: Typically injected via `.environmentObject` to be accessible by all views (e.g., Settings, Onboarding).

## 5. External Dependencies & APIs
### Framework: `FamilyControls`
- **Class**: `AuthorizationCenter`
- **Singleton**: `AuthorizationCenter.shared`
- **Method**: `requestAuthorization(for: MemberType)`
  - **Parameter**: `.individual` (Critical for this use case).
- **Property**: `authorizationStatus` (Returns `.notDetermined`, `.denied`, `.approved`).

### Entitlements (Critical)
- **Key**: `com.apple.developer.family-controls`
- **Value**: `YES` (Boolean)
- **Note**: Must be added via Xcode "Signing & Capabilities" -> "+ Capability" -> "Family Controls".

## 6. Integration Guide

### Prerequisites
1.  **Xcode Project**: Ensure the target has the **Family Controls** capability enabled.
2.  **Provisioning Profile**: Must support Family Controls (automatic signing usually handles this).

### Module Implementation (`ScreenTimeAuthorizer`)
Create a class responsible for the authorization lifecycle.

```swift
import FamilyControls
import SwiftUI

class ScreenTimeAuthorizer: ObservableObject {
    @Published var isAuthorized: Bool = false

    // Request access for the current device owner
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run { self.isAuthorized = true }
            } catch {
                print("Authorization failed: \(error)")
                // Handle denial or cancellation
            }
        }
    }
}
```

### UI Integration
1.  **Initialize**: Create the instance at the App root (`@StateObject`).
2.  **Inject**: Pass it down via `.environmentObject`.
3.  **Consume**: In your Views, observe `isAuthorized` to show/hide the "Grant Permission" button.

## 7. Configuration & Extension Points
- **Scope**: Hardcoded to `.individual`. If the app pivots to Parental Control later, this parameter needs to be configurable.
- **Error Handling**: Currently prints to console. Can be extended to publish an `errorMessage` string for user alerts.

## 8. Edge Cases & Pitfalls
- **Simulator Support**: Family Controls often fail or behave inconsistently on Simulators. **Always verify on a physical device.**
- **Revocation**: Users can revoke permission in iOS Settings > Screen Time. The app should check status on `scenePhase` changes (active/background).
- **Sandboxing**: Without the Entitlement, the API call will fail silently or crash.

## 9. Acceptance Criteria
- [ ] The app builds without errors.
- [ ] Tapping the authorization trigger shows the system Screen Time permission sheet.
- [ ] Accepting the permission updates the UI state to "Authorized".
- [ ] Denying the permission logs an error and keeps the UI in "Unauthorized" state.

## 10. Verification Checklist
- [ ] **Entitlement Check**: Verify `foqos.entitlements` (or your app's entitlement file) contains `com.apple.developer.family-controls`.
- [ ] **Physical Device**: Run on a real iPhone/iPad (iOS 15+ or 16+ depending on requirements).
- [ ] **System Settings**: Verify the app appears in iOS Settings > Screen Time > Apps with Screen Time Access.

## 11. Appendix: Search Queries
- **Apple Docs**: `AuthorizationCenter requestAuthorization individual`
- **GitHub**: `path:*.entitlements com.apple.developer.family-controls`
