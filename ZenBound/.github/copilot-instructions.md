# ZenBound AI Coding Agent Instructions

## Project Overview
ZenBound is an iOS 18+ app using Apple's Screen Time API (Family Controls framework) to monitor and control device activity. Built with SwiftUI and SwiftData for iOS 26.2+, Swift 5.0.

## Architecture

### Multi-Extension Structure
This project consists of 4 main targets with distinct responsibilities:

1. **ZenBound** (Main App) - `ZenBound/ZenBoundApp.swift`
   - SwiftUI app with SwiftData persistence
   - Manages CloudKit sync (see `ZenBound.entitlements`)
   - Remote notifications enabled (`Info.plist` background modes)
   - Bundle ID: `com.lxt.ZenBound`

2. **monitor** - `monitor/DeviceActivityMonitorExtension.swift`
   - DeviceActivity extension for background monitoring
   - Handles interval start/end events, threshold warnings
   - Extension principal class: `DeviceActivityMonitorExtension`
   - Requires Family Controls entitlement

3. **shieldAction** - `shieldAction/ShieldActionExtension.swift`
   - Handles user actions when shield is active (primary/secondary buttons)
   - Manages responses for apps, web domains, and categories
   - Default behavior: `.close` for primary, `.defer` for secondary

4. **shieldConfig** - `shieldConfig/ShieldConfigurationExtension.swift`
   - Customizes shield appearance using ManagedSettingsUI
   - Returns `ShieldConfiguration` for apps/domains/categories

5. **widget** - `widget/widgetBundle.swift`
   - WidgetKit bundle containing: widget, widgetControl, widgetLiveActivity
   - Uses App Intents for configuration
   - Timeline-based updates (hourly by default)

### Critical Extension Requirements
- All extensions require `com.apple.developer.family-controls` entitlement
- Extensions must be embedded in main app (check `project.pbxproj` for relationships)
- NSExtensionPrincipalClass in Info.plist must match the Swift class name

## Key Frameworks & APIs

### Screen Time API Usage
- **DeviceActivity**: Background monitoring, interval-based activities
- **ManagedSettings**: App/web blocking via shields
- **ManagedSettingsUI**: Custom shield UI
- **FamilyControls**: Authorization framework (parental controls)

### Data & Persistence
- **SwiftData**: Primary persistence layer with CloudKit integration
- Schema defined in `ZenBoundApp.sharedModelContainer`
- Currently empty schema (marked with `//todo`)

## Development Workflows

### Building & Running
```bash
# Open in Xcode
open ZenBound.xcodeproj

# Build all targets
xcodebuild -scheme ZenBound -configuration Debug build

# Run tests
xcodebuild test -scheme ZenBound -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing Extensions
- Extensions cannot be run directly - they activate when conditions are met
- Use Device Activity schedule APIs to trigger DeviceActivityMonitor
- Test shields by blocking apps via ManagedSettings.shield
- Console logging may be limited; use Unified Logging (`os_log`)

### Debugging Tips
- Extensions run in separate processes - attach debugger via Debug → Attach to Process
- Check Console.app for extension logs (filter by process name)
- Shield extensions require active Family Controls authorization

## Project Conventions

### File Organization
- Each target has its own folder at project root (no nested structure)
- Extensions use simple class names matching their type (e.g., `ShieldActionExtension`)
- Widgets follow Apple's template structure with separated bundle/entry views

### SwiftUI Patterns
- View names use PascalCase (e.g., `widgetEntryView`)
- Widget kinds use lowercase string identifiers (e.g., `"widget"`)
- Preview macros for all widget types with sample data

### Extension Patterns
- Always call `super` first in overridden extension methods
- Use completion handlers for asynchronous shield actions
- Handle `@unknown default` cases for future API additions

### Naming Conventions
- Bundle IDs follow pattern: `com.lxt.ZenBound[.extension]`
- Widget configuration intents: `ConfigurationAppIntent`
- Timeline entries: `SimpleEntry` with date + configuration

## Common Pitfalls

### Family Controls Authorization
- Request authorization before accessing Screen Time APIs
- Missing entitlements cause silent failures - check all `.entitlements` files
- Parental controls must be enabled on device/simulator

### Extension Lifecycle
- DeviceActivityMonitor callbacks may not fire immediately
- Test with generous time intervals during development
- Extensions have limited execution time - avoid heavy operations

### CloudKit & SwiftData
- Empty schema requires migration before use
- Test CloudKit container setup in Apple Developer portal
- iCloud container identifiers currently empty - configure before deployment

## Integration Points

### Main App ↔ Extensions
- Extensions operate independently; use App Groups for shared data
- Currently no App Groups configured - add if shared state needed
- Consider using UserDefaults with suite name or shared containers

### Widget ↔ Main App
- Widgets use App Intents for interactive configurations
- Timeline updates controlled by `timeline(for:in:)` implementation
- Currently updates every hour (see `widget.swift` line 24-33)

## TODO Markers
The codebase has `//todo` markers indicating incomplete sections:
- [ZenBound/ZenBoundApp.swift](ZenBound/ZenBoundApp.swift#L14): SwiftData schema definition
- [ZenBound/ZenBoundApp.swift](ZenBound/ZenBoundApp.swift#L26): Main view content

When implementing these, ensure:
- Schema includes all necessary models for app functionality
- Main view requests Family Controls authorization on first launch
- CloudKit sync properly configured with defined schema
