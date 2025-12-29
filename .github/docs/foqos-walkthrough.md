# 案例走讀：awaseem/foqos（以“吃透”為目標）

> 注意：本文件是“走讀方法模板”。你在實際走讀時，請用 prompt 去讀取倉庫內的檔案，並把結論寫到 `docs/study/`。凡是沒有文件證據的點，都標為「待確認」。

## 0. 你應該先知道的（技術特徵）

foqos 類型的 iOS App 往往同時具備：
- SwiftUI 作為主要 UI 框架
- SwiftData 作為本地資料層（或同類）
- 多種“系統級副作用”框架：
  - FamilyControls / ManagedSettings / DeviceActivity（家庭控制與使用情況）
  - WidgetKit +（可選）ActivityKit（Widget / Live Activities）
  - App Intents（Siri / Shortcuts / 系統交互入口）
  - BackgroundTasks（背景刷新/處理）
  - StoreKit（內購/訂閱）
  - CoreNFC（NFC 能力）
- 可能存在第三方掃碼依賴（例如 CodeScanner）

這意味著：**targets/capabilities 與 entitlements** 幾乎一定是“第一優先級”。

## 1. 建議你按這個順序吃透

### Step 1：Targets + Capabilities（先畫地圖）

用 `.github/prompts/ios-targets-capabilities-map.prompt.md` 生成：
- `docs/study/01-targets-and-capabilities.md`

你要特別關注：
- App 本體 target
- Widget / Live Activity target
- Intents / AppIntents 擴展（如有）
- 任何 Shield/DeviceActivity/FamilyControls 相關 extension（如有）
- entitlements：Family Controls、App Groups、Background Modes、NFC、Push 等

### Step 2：入口與狀態流

用 `.github/prompts/ios-repo-triage.prompt.md` 生成：
- `docs/study/00-project-map.md`

在 SwiftUI 專案裡，入口通常出現在：
- `@main` App struct
- 根 view（比如 `ContentView` 或 `RootView`）
- 依賴注入/環境對象（Environment / Observable / Store）

### Step 3：模組拆解（把“系統框架副作用”圈起來）

用 `.github/prompts/ios-module-map.prompt.md` 生成：
- `docs/study/03-module-map.md`

建議你按“副作用域”切模組：
- FamilyControls/DeviceActivity/ManagedSettings（策略/授權/資料流）
- WidgetKit/ActivityKit（時間線、狀態來源、資料共享 App Group）
- App Intents（意圖定義、參數、觸發點、權限）
- CoreNFC（Session 生命週期、錯誤處理、隱私文案）
- BackgroundTasks（註冊、排程、執行限制、與資料層互動）
- StoreKit（產品拉取、購買流程、狀態同步）

### Step 4：為每個功能模塊產出 Feature Card

對 foqos 這類專案，你至少要有這些 Feature Card：
- “家庭控制/屏蔽策略”卡
- “使用情況/活動數據”卡
- “Widget/Live Activity 展示”卡
- “Shortcuts/AppIntents 入口”卡
- “掃碼（如有）”卡
- “NFC（如有）”卡
- “訂閱/內購（如有）”卡

用 `.github/prompts/ios-feature-slice-learning-card.prompt.md` 在 `docs/study/04-feature-cards/` 逐個生成。

## 2. 你最容易忽略的坑位清單

- 多 target 的資料共享：App Groups、SwiftData 容器位置、UserDefaults suite、檔案路徑
- 隱私與權限文案：`Info.plist`（NFC、FamilyControls 等）
- 背景任務的“看起來能跑”：真機/系統條件/時間限制，必須證據化
- SwiftUI 狀態：主線程隔離、Observable 更新、避免在 view 裡做重副作用
- StoreKit：交易狀態、離線/恢復購買、服務端驗證（如有）

## 3. 從 foqos 抽象出“可復刻能力”

用 `.github/prompts/ios-similar-feature-implementation-guide.prompt.md` 分別為：
- FamilyControls/ManagedSettings 策略
- WidgetKit/ActivityKit 展示
- App Intents 入口
生成 `docs/study/06-clone-guides/` 的指南。
