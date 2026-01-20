# 📋 Foqos 項目重構計劃草案

## 🎯 重構目標

1. **降低複雜度**：拆分大型類（StrategyManager 1265行，BlockedProfiles 429行）
2. **提高可測試性**：引入依賴注入，便於單元測試
3. **增強可維護性**：統一錯誤處理，改善代碼結構
4. **保證數據一致性**：優化雙寫同步機制
5. **保持功能完整**：所有重構必須保持現有功能

## 📊 當前架構問題總結

### P0 問題（必須解決）

| 問題 | 當前狀態 | 影響 | 優先級 |
|------|----------|------|--------|
| StrategyManager 職責過多 | 1265行，8-10個職責 | 難以測試、維護、理解 | 🔴 最高 |
| BlockedProfiles 屬性過多 | 22+屬性，20+初始化參數 | 初始化複雜，職責不清 | 🔴 最高 |
| 雙寫同步機制脆弱 | 手動同步，無事務保證 | 數據不一致風險 | 🔴 高 |

### P1 問題（應該解決）

| 問題 | 當前狀態 | 影響 | 優先級 |
|------|----------|------|--------|
| Strategy 回調內存泄漏風險 | 每次重新注入閉包 | 潛在內存泄漏 | 🟡 中高 |
| 缺乏單元測試 | 無測試基礎設施 | 重構風險高 | 🟡 中高 |
| 錯誤處理不統一 | print/errorMessage 混用 | 調試困難 | 🟡 中 |

## 🗺 重構路線圖

### 階段 1：建立測試基礎（1-2週）

**目標**：在重構前建立安全網

**任務**：
1. ✅ 創建 Unit Test Target
2. ✅ 設置 Mock 框架
3. ✅ 為核心業務邏輯編寫集成測試
   - AppBlockerUtil 測試
   - SharedData 同步測試
   - BlockedProfiles CRUD 測試
4. ✅ 建立 CI 流程（可選）

**驗收標準**：
- 核心功能有測試覆蓋
- 測試可以在 CI 中運行
- 重構前所有測試通過

**風險**：
- 某些依賴系統框架（FamilyControls）難以 Mock
- **緩解**：使用協議抽象，創建測試替身

---

### 階段 2：拆分 StrategyManager（2-3週）

**目標**：將 1265 行的 God Object 拆分為職責清晰的多個管理器

#### 2.1 設計新架構

**拆分方案**：

```swift
// 1. SessionCoordinator - 會話協調器（主入口）
class SessionCoordinator {
  private let strategyRegistry: StrategyRegistry
  private let timerManager: TimerManager
  private let breakManager: BreakManager
  private let stateSyncCoordinator: StateSyncCoordinator
  private let emergencyUnlockManager: EmergencyUnlockManager
  
  @Published var activeSession: BlockedProfileSession?
  @Published var isBlocking: Bool = false
  @Published var errorMessage: String?
  
  // 主要公開接口
  func toggleBlocking(context: ModelContext, profile: BlockedProfiles)
  func startSession(context: ModelContext, profile: BlockedProfiles)
  func endSession(context: ModelContext)
}

// 2. StrategyRegistry - 策略註冊表
class StrategyRegistry {
  private var strategies: [any BlockingStrategy] = []
  
  func register(_ strategy: any BlockingStrategy)
  func getStrategy(id: String) -> any BlockingStrategy?
  func allStrategies() -> [any BlockingStrategy]
}

// 3. TimerManager - 計時器管理
class TimerManager: ObservableObject {
  @Published var elapsedTime: TimeInterval = 0
  @Published var isTimerRunning: Bool = false
  
  func startTimer(for session: BlockedProfileSession)
  func stopTimer()
  func pauseTimer()
  func resumeTimer()
}

// 4. BreakManager - 休息模式管理
class BreakManager {
  @Published var isBreakActive: Bool = false
  @Published var breakTimeRemaining: Int = 0
  
  func startBreak(context: ModelContext, session: BlockedProfileSession)
  func endBreak(context: ModelContext, session: BlockedProfileSession)
  func scheduleBreakReminder(minutes: Int)
}

// 5. StateSyncCoordinator - 狀態同步協調器
class StateSyncCoordinator {
  func syncToWidget()
  func syncToLiveActivity(session: BlockedProfileSession?)
  func syncToSharedData(profile: BlockedProfiles, session: BlockedProfileSession?)
  func syncAll()
}

// 6. EmergencyUnlockManager - 緊急解鎖管理
class EmergencyUnlockManager {
  @Published var emergencyUnblockCount: Int = 0
  @Published var emergencyUnblockCooldownDate: Date?
  
  func canEmergencyUnblock() -> Bool
  func emergencyUnblock(context: ModelContext, session: BlockedProfileSession)
  func resetQuota()
}

// 7. BackgroundSessionManager - 後台會話管理
class BackgroundSessionManager {
  func startSessionFromBackground(profileId: UUID, context: ModelContext, duration: Int?)
  func stopSessionFromBackground(profileId: UUID, context: ModelContext)
  func handleDeepLink(url: URL)
}
```

#### 2.2 遷移策略

**遷移步驟**（小步快跑）：

1. **Week 1-2: 提取工具類**
   - ✅ 創建新的管理器類
   - ✅ 實現基礎功能
   - ✅ 編寫單元測試
   - ⚠️ 保留 StrategyManager，不破壞現有代碼

2. **Week 3-4: 逐步遷移調用方**
   - ✅ 更新 Views 調用新的 SessionCoordinator
   - ✅ 更新 App Intents 調用
   - ✅ 更新 Widget 調用
   - ✅ 運行所有測試

3. **Week 5: 清理舊代碼**
   - ✅ 刪除 StrategyManager
   - ✅ 更新文檔
   - ✅ 最終測試

**向後兼容策略**：
- 在過渡期，StrategyManager 可以作為 Facade，內部調用新管理器
- 逐個遷移調用方，不一次性破壞所有代碼

---

### 階段 3：重構 BlockedProfiles 數據模型（1-2週）

**目標**：拆分為多個子模型，降低複雜度

#### 3.1 新的數據模型設計

```swift
// 核心模型
@Model
class BlockedProfile {
  @Attribute(.unique) var id: UUID
  var name: String
  var order: Int
  var createdAt: Date
  var updatedAt: Date
  
  // 關聯
  var strategy: ProfileStrategy
  var settings: ProfileSettings
  var selectedActivity: FamilyActivitySelection
  
  @Relationship var sessions: [BlockedProfileSession]
}

// 策略配置
@Model
class ProfileStrategy {
  var strategyId: String
  var strategyData: Data?
  var physicalUnlock: PhysicalUnlockConfig?
}

// 物理解鎖配置
@Model
class PhysicalUnlockConfig {
  var nfcTagId: String?
  var qrCodeId: String?
}

// 功能設置
@Model
class ProfileSettings {
  var enableLiveActivity: Bool
  var enableBreaks: Bool
  var breakTimeInMinutes: Int
  var enableStrictMode: Bool
  var disableBackgroundStops: Bool
  
  var reminder: ReminderConfig?
  var webFilter: WebFilterConfig?
  var schedule: BlockedProfileSchedule?
}

// 提醒配置
@Model
class ReminderConfig {
  var timeInSeconds: UInt32
  var customMessage: String?
}

// 網頁過濾配置
@Model
class WebFilterConfig {
  var domains: [String]
  var enableAllowMode: Bool
  var enableSafariBlocking: Bool
}
```

#### 3.2 數據遷移策略

**遷移步驟**：

1. **創建遷移腳本**
   ```swift
   class ProfileMigrationV1toV2 {
     func migrate(context: ModelContext) {
       let oldProfiles = try? context.fetch(FetchDescriptor<OldBlockedProfiles>())
       
       for oldProfile in oldProfiles ?? [] {
         let newProfile = BlockedProfile(
           id: oldProfile.id,
           name: oldProfile.name,
           ...
         )
         
         let strategy = ProfileStrategy(
           strategyId: oldProfile.blockingStrategyId,
           ...
         )
         
         newProfile.strategy = strategy
         
         context.insert(newProfile)
       }
       
       try? context.save()
     }
   }
   ```

2. **在 App 啟動時執行遷移**
   ```swift
   @main
   struct foqosApp: App {
     init() {
       if needsMigration() {
         ProfileMigrationV1toV2().migrate(context: container.mainContext)
       }
     }
   }
   ```

3. **提供回滾機制**
   - 保留舊數據 1 個版本
   - 提供降級路徑（如果需要）

#### 3.3 引入 Builder Pattern

**簡化初始化**：

```swift
class BlockedProfileBuilder {
  private var profile: BlockedProfile
  
  init(name: String) {
    profile = BlockedProfile(name: name)
  }
  
  func withStrategy(id: String, data: Data? = nil) -> Self {
    profile.strategy = ProfileStrategy(strategyId: id, strategyData: data)
    return self
  }
  
  func withReminder(seconds: UInt32, message: String? = nil) -> Self {
    profile.settings.reminder = ReminderConfig(
      timeInSeconds: seconds,
      customMessage: message
    )
    return self
  }
  
  func withWebFilter(domains: [String], allowMode: Bool = false) -> Self {
    profile.settings.webFilter = WebFilterConfig(
      domains: domains,
      enableAllowMode: allowMode
    )
    return self
  }
  
  func build() -> BlockedProfile {
    return profile
  }
}

// 使用示例
let profile = BlockedProfileBuilder(name: "Work Focus")
  .withStrategy(id: NFCTimerBlockingStrategy.id)
  .withReminder(seconds: 3600)
  .withWebFilter(domains: ["twitter.com"], allowMode: false)
  .build()
```

---

### 階段 4：優化 Strategy 回調機制（1週）

**目標**：消除內存泄漏風險，改用 Delegate 模式

#### 4.1 新的 Strategy 協議設計

```swift
// Strategy Delegate
protocol BlockingStrategyDelegate: AnyObject {
  func strategyDidStartSession(_ strategy: BlockingStrategy, session: BlockedProfileSession)
  func strategyDidEndSession(_ strategy: BlockingStrategy, profile: BlockedProfiles)
  func strategy(_ strategy: BlockingStrategy, didEncounterError message: String)
}

// 更新後的協議
protocol BlockingStrategy {
  static var id: String { get }
  var name: String { get }
  var description: String { get }
  var iconType: String { get }
  var color: Color { get }
  var hidden: Bool { get }
  
  weak var delegate: BlockingStrategyDelegate? { get set }
  
  func getIdentifier() -> String
  func startBlocking(context: ModelContext, profile: BlockedProfiles, forceStart: Bool?) -> (any View)?
  func stopBlocking(context: ModelContext, session: BlockedProfileSession) -> (any View)?
}
```

#### 4.2 遷移步驟

1. ✅ 更新 BlockingStrategy 協議
2. ✅ 更新所有 9 個策略實現
3. ✅ SessionCoordinator 實現 BlockingStrategyDelegate
4. ✅ 測試所有策略

---

### 階段 5：統一狀態同步機制（1週）

**目標**：建立統一的數據同步協調器

#### 5.1 StateSyncCoordinator 設計

```swift
class StateSyncCoordinator {
  // 單一同步入口
  func syncSessionState(
    profile: BlockedProfiles,
    session: BlockedProfileSession?,
    isBreakActive: Bool = false
  ) {
    // 1. 同步到 SharedData
    syncToSharedData(profile: profile, session: session)
    
    // 2. 同步到 Widget
    syncToWidget()
    
    // 3. 同步到 Live Activity
    syncToLiveActivity(session: session, isBreakActive: isBreakActive)
    
    // 4. 觸發通知（如需要）
    scheduleNotificationsIfNeeded(profile: profile, session: session)
  }
  
  private func syncToSharedData(profile: BlockedProfiles, session: BlockedProfileSession?) {
    // 更新 ProfileSnapshot
    SharedData.setSnapshot(profile.toSnapshot(), for: profile.id.uuidString)
    
    // 更新 SessionSnapshot
    if let session = session {
      SharedData.createActiveSharedSession(for: session.toSnapshot())
    } else {
      SharedData.flushActiveSession()
    }
  }
  
  private func syncToWidget() {
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
  }
  
  private func syncToLiveActivity(session: BlockedProfileSession?, isBreakActive: Bool) {
    if let session = session {
      LiveActivityManager.shared.startOrUpdate(session: session, isBreakActive: isBreakActive)
    } else {
      LiveActivityManager.shared.end()
    }
  }
}
```

#### 5.2 優點

- ✅ 單一真相來源
- ✅ 事務性同步（要麼全部成功，要麼回滾）
- ✅ 易於測試
- ✅ 易於添加新的同步目標

---

### 階段 6：統一錯誤處理（1週）

**目標**：建立統一的錯誤處理和日誌機制

#### 6.1 錯誤類型定義

```swift
enum FoqosError: LocalizedError {
  case profileNotFound(UUID)
  case sessionNotActive
  case strategyNotFound(String)
  case authorizationDenied
  case emergencyUnlockQuotaExceeded
  case physicalUnlockTagMismatch(expected: String, got: String)
  case timerDurationInvalid(Int)
  
  var errorDescription: String? {
    switch self {
    case .profileNotFound(let id):
      return "Profile \(id) not found"
    case .sessionNotActive:
      return "No active blocking session"
    case .strategyNotFound(let id):
      return "Strategy \(id) not found"
    case .authorizationDenied:
      return "Screen Time authorization denied"
    case .emergencyUnlockQuotaExceeded:
      return "Emergency unlock quota exceeded"
    case .physicalUnlockTagMismatch(let expected, let got):
      return "Wrong unlock tag. Expected: \(expected), Got: \(got)"
    case .timerDurationInvalid(let minutes):
      return "Invalid timer duration: \(minutes) minutes"
    }
  }
}
```

#### 6.2 統一日誌系統

```swift
import OSLog

extension Logger {
  static let session = Logger(subsystem: "com.foqos.app", category: "Session")
  static let strategy = Logger(subsystem: "com.foqos.app", category: "Strategy")
  static let sync = Logger(subsystem: "com.foqos.app", category: "Sync")
  static let timer = Logger(subsystem: "com.foqos.app", category: "Timer")
}

// 使用示例
Logger.session.info("Starting session for profile: \(profile.id)")
Logger.session.error("Failed to start session: \(error.localizedDescription)")
```

---

## 📅 時間估算

| 階段 | 工作量 | 時間估算 |
|------|--------|----------|
| 1. 建立測試基礎 | 中 | 1-2 週 |
| 2. 拆分 StrategyManager | 大 | 2-3 週 |
| 3. 重構 BlockedProfiles | 中 | 1-2 週 |
| 4. 優化 Strategy 回調 | 小 | 1 週 |
| 5. 統一狀態同步 | 小 | 1 週 |
| 6. 統一錯誤處理 | 小 | 1 週 |
| **總計** | | **7-10 週** |

## ⚠️ 風險管理

| 風險 | 概率 | 影響 | 緩解措施 |
|------|------|------|----------|
| 破壞現有功能 | 中 | 高 | 建立完善測試，小步快跑 |
| 數據遷移失敗 | 低 | 高 | 提供回滾機制，保留舊數據 |
| 性能下降 | 低 | 中 | 性能測試，對比重構前後 |
| Extension 兼容性問題 | 中 | 中 | 充分測試 Extension 場景 |
| 開發時間超預期 | 中 | 中 | 分階段交付，優先 P0 |

## ✅ 驗收標準

### 功能驗收
- [ ] 所有現有功能正常工作
- [ ] 所有 9 種策略正常工作
- [ ] Extensions 正常觸發
- [ ] Widget 和 Live Activity 正常更新
- [ ] App Intents 和 Shortcuts 正常工作

### 代碼質量驗收
- [ ] 沒有超過 300 行的類
- [ ] 測試覆蓋率 > 60%
- [ ] 所有 P0 問題已解決
- [ ] 代碼符合 Swift 最佳實踐

### 性能驗收
- [ ] App 啟動時間無明顯增加
- [ ] 會話啟動/停止響應時間 < 1 秒
- [ ] 內存使用無明顯增加

## 📝 下一步行動

1. **與用戶討論此計劃**
   - 確認重構範圍和優先級
   - 確認時間表是否可接受
   - 討論是否有其他關注點

2. **如果計劃獲批**
   - 創建詳細的任務分解（GitHub Issues）
   - 開始階段 1：建立測試基礎
   - 建立每週進度報告機制

3. **如果需要調整**
   - 根據反饋修改計劃
   - 重新評估優先級和時間表

---

**創建日期**：2026-01-13
**最後更新**：2026-01-13
**狀態**：草案，待用戶審核
