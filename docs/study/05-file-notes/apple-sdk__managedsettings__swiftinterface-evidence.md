# Apple SDK evidence — ManagedSettings / ManagedSettingsUI

## Context
This file is auto-generated from the local iOS Simulator SDK `.swiftinterface` files.
It exists to make API-shape claims in `docs/study/07-api-cards/` verifiable within this repo.

## How to regenerate
Run: `python3 scripts/extract_managedsettings_sdk_evidence.py`

## ManagedSettings.ManagedSettingsStore
Source: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/ManagedSettings.framework/Modules/ManagedSettings.swiftmodule/arm64-apple-ios-simulator.swiftinterface`

### Needle: `public class ManagedSettingsStore`
- L386: `public class ManagedSettingsStore : Combine.ObservableObject {`

### Needle: `public var shield`
- L423: `public var shield: ManagedSettings.ShieldSettings`

### Needle: `public var webContent`
- L427: `public var webContent: ManagedSettings.WebContentSettings`

### Needle: `public var application`
- L337: `public var applications: Swift.Set<ManagedSettings.ApplicationToken>? {`
- L344: `public var applicationCategories: ManagedSettings.ShieldSettings.ActivityCategoryPolicy<ManagedSettings.Application>? {`
- L407: `public var application: ManagedSettings.ApplicationSettings`

### Needle: `public func clearAllSettings()`
- L430: `public func clearAllSettings()`

## ManagedSettings.ShieldSettings
Source: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/ManagedSettings.framework/Modules/ManagedSettings.swiftmodule/arm64-apple-ios-simulator.swiftinterface`

### Needle: `public struct ShieldSettings`
- L335: `public struct ShieldSettings : ManagedSettings.ManagedSettingsGroup {`

### Needle: `public var applications:`
- L337: `public var applications: Swift.Set<ManagedSettings.ApplicationToken>? {`

### Needle: `public var applicationCategories:`
- L344: `public var applicationCategories: ManagedSettings.ShieldSettings.ActivityCategoryPolicy<ManagedSettings.Application>? {`

### Needle: `public var webDomains:`
- L351: `public var webDomains: Swift.Set<ManagedSettings.WebDomainToken>? {`

### Needle: `public var webDomainCategories:`
- L358: `public var webDomainCategories: ManagedSettings.ShieldSettings.ActivityCategoryPolicy<ManagedSettings.WebDomain>? {`

### Needle: `public enum ActivityCategoryPolicy`
- L232: `public enum ActivityCategoryPolicy<Activity> : Swift.Equatable {`

## ManagedSettings.WebContentSettings
Source: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/ManagedSettings.framework/Modules/ManagedSettings.swiftmodule/arm64-apple-ios-simulator.swiftinterface`

### Needle: `public struct WebContentSettings`
- L541: `public struct WebContentSettings : ManagedSettings.ManagedSettingsGroup {`

### Needle: `public enum FilterPolicy`
- L542: `public enum FilterPolicy : Swift.Equatable {`

### Needle: `public var blockedByFilter:`
- L550: `public var blockedByFilter: ManagedSettings.WebContentSettings.FilterPolicy? {`

## ManagedSettings.ShieldActionDelegate
Source: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/ManagedSettings.framework/Modules/ManagedSettings.swiftmodule/arm64-apple-ios-simulator.swiftinterface`

### Needle: `open class ShieldActionDelegate`
- L200: `@objc open class ShieldActionDelegate : ObjectiveC.NSObject {`

### Needle: `open func handle(action:`
- L201: `open func handle(action: ManagedSettings.ShieldAction, for application: ManagedSettings.ApplicationToken, completionHandler: @escaping (ManagedSettings.ShieldActionResponse) -> Swift.Void)`
- L202: `open func handle(action: ManagedSettings.ShieldAction, for category: ManagedSettings.ActivityCategoryToken, completionHandler: @escaping (ManagedSettings.ShieldActionResponse) -> Swift.Void)`
- L203: `open func handle(action: ManagedSettings.ShieldAction, for webDomain: ManagedSettings.WebDomainToken, completionHandler: @escaping (ManagedSettings.ShieldActionResponse) -> Swift.Void)`

### Needle: `ShieldActionResponse`
- L178: `public enum ShieldActionResponse : Swift.Int {`
- L201: `open func handle(action: ManagedSettings.ShieldAction, for application: ManagedSettings.ApplicationToken, completionHandler: @escaping (ManagedSettings.ShieldActionResponse) -> Swift.Void)`
- L202: `open func handle(action: ManagedSettings.ShieldAction, for category: ManagedSettings.ActivityCategoryToken, completionHandler: @escaping (ManagedSettings.ShieldActionResponse) -> Swift.Void)`
- L203: `open func handle(action: ManagedSettings.ShieldAction, for webDomain: ManagedSettings.WebDomainToken, completionHandler: @escaping (ManagedSettings.ShieldActionResponse) -> Swift.Void)`
- L580: `extension ManagedSettings.ShieldActionResponse : Swift.Equatable {}`
- L586: `extension ManagedSettings.ShieldActionResponse : Swift.Hashable {}`
- L592: `extension ManagedSettings.ShieldActionResponse : Swift.RawRepresentable {}`

## ManagedSettingsUI.ShieldConfigurationDataSource
Source: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/ManagedSettingsUI.framework/Modules/ManagedSettingsUI.swiftmodule/arm64-apple-ios-simulator.swiftinterface`

### Needle: `ShieldConfigurationDataSource`
- L20: `@objc open class ShieldConfigurationDataSource : ObjectiveC.NSObject {`

### Needle: `configuration(shielding application:`
- L21: `open func configuration(shielding application: ManagedSettings.Application) -> ManagedSettingsUI.ShieldConfiguration`
- L22: `open func configuration(shielding application: ManagedSettings.Application, in category: ManagedSettings.ActivityCategory) -> ManagedSettingsUI.ShieldConfiguration`

### Needle: `configuration(shielding webDomain:`
- L23: `open func configuration(shielding webDomain: ManagedSettings.WebDomain) -> ManagedSettingsUI.ShieldConfiguration`
- L24: `open func configuration(shielding webDomain: ManagedSettings.WebDomain, in category: ManagedSettings.ActivityCategory) -> ManagedSettingsUI.ShieldConfiguration`
