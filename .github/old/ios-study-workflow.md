# iOS 開源 App「逐步吃透」工作流（Copilot 版）

本工作流的目標是把“我看懂了”變成可驗證、可回放的產出。

## 產出約定（強烈建議）

把所有學習輸出放到：
- `docs/study/00-project-map.md`
- `docs/study/01-targets-and-capabilities.md`
- `docs/study/02-dependencies.md`
- `docs/study/03-module-map.md`
- `docs/study/04-feature-cards/`（每個 feature 一張卡）
- `docs/study/05-file-notes/`（逐檔摘要與建議註釋）
- `docs/study/06-clone-guides/`（如何做類似功能）
- `docs/study/99-open-questions.md`

> 你可以把這些檔案當成你的「專案記憶庫」。

## 核心原則（避免“看起來像”但其實錯）

- 證據驅動：每個結論都要能指向一個檔案/目錄/設定（例如 `*.pbxproj`、`*.entitlements`、`Info.plist`、`Package.resolved`）。
- 分清已確認/待確認：不確定就標註「待確認」並寫出“如何確認”。
- 先入口後細節：先找 app 啟動入口與主要 user flow，再鑽深。
- 先副作用邊界：iOS 專案最容易踩坑的是權限/背景任務/extension/通知/隱私。

## 建議步驟（按順序跑）

### Step 0：冷啟動掃描（10–20 分鐘）

使用 prompt：`.github/prompts/ios-repo-triage.prompt.md`
- 目標：產出 `docs/study/00-project-map.md`
- 關鍵輸入：README、目錄結構、Xcode 工程（`*.xcodeproj` / `project.pbxproj`）

### Step 1：Targets / Schemes / Capabilities（最重要）

使用 prompt：`.github/prompts/ios-targets-capabilities-map.prompt.md`
- 目標：產出 `docs/study/01-targets-and-capabilities.md`
- 你要搞清楚：
  - 有哪些 targets（App、Widget、Shield/Extension、Intents、Tests 等）
  - 每個 target 的 entitlements / capabilities
  - 哪些系統框架會引入“副作用”（FamilyControls、DeviceActivity、BackgroundTasks…）

### Step 2：依賴與工具鏈

使用 prompt：`.github/prompts/ios-dependency-audit.prompt.md`
- 目標：產出 `docs/study/02-dependencies.md`
- 你要搞清楚：SPM/Pods/Carthage/手動引入？每個依賴用在哪？

### Step 3：模組視圖（UI/狀態/資料/副作用）

使用 prompt：`.github/prompts/ios-module-map.prompt.md`
- 目標：產出 `docs/study/03-module-map.md`
- 你要搞清楚：
  - UI（SwiftUI / UIKit）層如何組織
  - 狀態管理（Observable、Reducer、Store、Environment、DI）
  - 資料層（SwiftData/CoreData/Files/UserDefaults/Keychain/Network）
  - 副作用（通知、背景、NFC、家庭控制、Widget、StoreKit）邊界

### Step 4：Feature 卡（每個功能模塊一張）

使用 prompt：`.github/prompts/ios-feature-slice-learning-card.prompt.md`
- 目標：在 `docs/study/04-feature-cards/` 建立多個 feature card
- 每張卡至少包含：入口、資料流、關鍵 API、風險點、可測邊界、學習任務

### Step 5：逐檔摘要與“建議註釋”（不破壞原碼）

使用 prompt：`.github/prompts/ios-file-by-file-notes.prompt.md`
- 目標：在 `docs/study/05-file-notes/` 產出逐檔筆記
- 原則：不要批量往原始碼塞註釋；先把“想加的註釋”以建議形式寫到筆記裡

### Step 6：如何做類似功能（可遷移的能力）

使用 prompt：`.github/prompts/ios-similar-feature-implementation-guide.prompt.md`
- 目標：在 `docs/study/06-clone-guides/` 產出可復用指南
- 內容：最小實作路徑、依賴、權限、狀態/資料設計、測試策略、常見坑

## 什麼時候用 Agent？

- 想“一次跑完整流程”時，用 `.github/agents/ios-project-onboarding.agent.md`
- 想把某個 feature 變成“可復刻的實作藍圖”時，用 `.github/agents/ios-feature-replication-coach.agent.md`
