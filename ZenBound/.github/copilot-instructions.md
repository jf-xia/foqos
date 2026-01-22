# ZenBound - iOS Screen Time Management App

## Development Practices

- Language: Swift 6+ with SwiftUI and SwiftData.
- Minimum deployment target: iOS 17.6+.
- Skills:
  - planning-with-files: Use when starting complex multi-step tasks, research projects, or any task requiring >5 tool calls.
- MCP
  - apple-docs-mcp: research documentation for Apple frameworks and APIs.
  - github(date>2023-01-01, star>20, language=swift): find code examples and best practices on GitHub.
  - mobile-mcp: test on simulators for code changes after building iOS apps and open iPhone 17 (26.2) simulator.

## Frameworks and structures

├── ZenBound
│ ├── ZenBoundApp.swift: main entry point, sets up the app environment, background task and ModelContainer.
│ ├── DemoUI: ignore, demo views for testing features during development.
│ │ ├── ...
│ ├── Models
│ │ ├── BlockedProfiles.swift
│ │ ├── BlockedProfileSessions.swift
│ │ ├── Schedule.swift
│ │ ├── Shared.swift
│ │ ├── Strategies
│ │ │ ├── BlockingStrategy.swift
│ │ │ ├── Data
│ │ │ │ └── StrategyTimerData.swift
│ │ │ ├── ManualBlockingStrategy.swift
│ │ │ └── ShortcutTimerBlockingStrategy.swift
│ │ └── Timers
│ │ ├── BreakTimerActivity.swift
│ │ ├── ScheduleTimerActivity.swift
│ │ ├── StrategyTimerActivity.swift
│ │ ├── TimerActivity.swift
│ │ └── TimerActivityUtil.swift
│ ├── Utils
│ │ ├── AppBlockerUtil.swift
│ │ ├── DeviceActivityCenterUtil.swift
│ │ ├── FamilyActivityUtil.swift
│ │ ├── FocusMessages.swift
│ │ ├── LiveActivityManager.swift
│ │ ├── ProfileInsightsUtil.swift
│ │ ├── RatingManager.swift
│ │ ├── RequestAuthorizer.swift: class RequestAuthorizer { isAuthorized, authorizationStatus, checkAuthorizationStatus(), requestAuthorization(), revokeAuthorization(), getAuthorizationStatus() -> AuthorizationStatus }
│ │ ├── StrategyManager.swift
│ │ ├── ThemeManager.swift
│ │ └── TimersUtil.swift
├── monitor
│ └── DeviceActivityMonitorExtension.swift
├── shieldAction
│ └── ShieldActionExtension.swift
├── shieldConfig
│ └── ShieldConfigurationExtension.swift
└── widget
└── widgetBundle.swift
