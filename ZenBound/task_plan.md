# ZenBound 应用场景开发计划

> 创建时间: 2026-01-23
> 最后更新: 2026-01-27

## 📋 当前任务: 内容与隐私权限制场景

### Phase 1: 扩展 AppBlockerUtil - `in_progress`
- [x] 添加内容限制相关方法 (App Store, Media, Siri, Game Center)
- [x] 添加隐私权限相关方法 (Contacts, Calendar, Photos)
- [x] 添加系统变更相关方法 (Passcode, Account, Cellular, DateTime)

### Phase 2: 创建场景页面 UI - `in_progress`
- [x] 创建 ContentPrivacyRestrictionsScenarioView.swift
- [x] 实现 iTunes 与 App Store 购买设置
- [x] 实现内容限制设置
- [x] 实现隐私权限设置
- [x] 实现系统变更设置
- [x] 添加日志输出

### Phase 3: 集成到场景首页 - `in_progress`
- [x] 在 ScenariosHomeView 添加入口
- [ ] 编译项目

### Phase 4: 测试 - `not_started`
- [ ] 使用 Mobile MCP 进行测试
- [ ] 记录测试结果

---

## 📋 历史任务目标

根据项目现有功能和逻辑，组合10种不同的应用场景，在DemoUI中开发实施，每个场景包含：
- 场景描述和使用说明
- 相关函数的引用/依赖
- 改进建议

## 🎯 10种应用场景概览

| #   | 场景名称     | 核心功能组合                                              | 状态 |
| --- | ------------ | --------------------------------------------------------- | ---- |
| 1   | 工作专注模式 | BlockedProfiles + ManualBlockingStrategy + LiveActivity   | ✅    |
| 2   | 学习计划模式 | Schedule + ScheduleTimerActivity + ProfileInsights        | ✅    |
| 3   | 社交媒体戒断 | AppBlockerUtil + StrategyManager + FocusMessages          | ✅    |
| 4   | 睡前数字戒断 | Schedule + BreakTimerActivity + TimersUtil                | ✅    |
| 5   | 番茄工作法   | ShortcutTimerBlockingStrategy + BreakTimer + Notification | ✅    |
| 6   | 家庭共享管理 | FamilyActivityUtil + SharedData + MultiProfile            | ✅    |
| 7   | 紧急解锁机制 | EmergencyUnblock + StrategyManager + StrictMode           | ✅    |
| 8   | 会话数据分析 | ProfileInsightsUtil + Sessions + Charts                   | ✅    |
| 9   | NFC物理解锁  | PhysicalUnlock + NFCTagId + BlockingStrategy              | ✅    |
| 10  | 快捷指令集成 | AppIntents + DeepLink + BackgroundSession                 | ✅    |

## 📁 文件结构

```
ZenBound/DemoUI/
├── Scenarios/                    # 新建：10种场景目录
│   ├── ScenariosHomeView.swift   # 场景入口导航
│   ├── WorkFocusScenarioView.swift
│   ├── StudyPlanScenarioView.swift
│   ├── SocialMediaDetoxScenarioView.swift
│   ├── BedtimeDigitalDetoxScenarioView.swift
│   ├── PomodoroTechniqueScenarioView.swift
│   ├── FamilySharingScenarioView.swift
│   ├── EmergencyUnlockScenarioView.swift
│   ├── SessionAnalyticsScenarioView.swift
│   ├── NFCPhysicalUnlockScenarioView.swift
│   └── ShortcutsIntegrationScenarioView.swift
└── DemoHomeView.swift            # 更新：添加场景入口
```

## 🔧 各场景详细设计

### 场景1: 工作专注模式
**核心功能**: 一键启动工作专注，屏蔽干扰应用，显示Live Activity
**依赖组件**:
- `BlockedProfiles` - 配置管理
- `ManualBlockingStrategy` - 手动控制
- `LiveActivityManager` - 实时活动显示
- `AppBlockerUtil` - 应用屏蔽
- `StrategyManager` - 会话协调

### 场景2: 学习计划模式
**核心功能**: 设置每周学习日程，自动启动屏蔽
**依赖组件**:
- `BlockedProfileSchedule` - 日程配置
- `ScheduleTimerActivity` - 日程计时器
- `DeviceActivityCenterUtil` - 活动调度
- `ProfileInsightsUtil` - 学习统计

### 场景3: 社交媒体戒断
**核心功能**: 专门针对社交媒体的屏蔽配置
**依赖组件**:
- `FamilyActivityUtil` - 选择社交应用
- `AppBlockerUtil` - 屏蔽执行
- `FocusMessages` - 激励消息
- `StrategyManager` - 戒断管理

### 场景4: 睡前数字戒断
**核心功能**: 睡前时段自动屏蔽，帮助改善睡眠
**依赖组件**:
- `BlockedProfileSchedule` - 睡前时间段
- `TimersUtil` - 睡前提醒
- `BreakTimerActivity` - 短暂休息
- `SharedData` - 数据同步

### 场景5: 番茄工作法
**核心功能**: 25分钟专注 + 5分钟休息循环
**依赖组件**:
- `ShortcutTimerBlockingStrategy` - 定时策略
- `StrategyTimerData` - 时长配置
- `BreakTimerActivity` - 休息计时
- `TimersUtil` - 通知调度

### 场景6: 家庭共享管理
**核心功能**: 管理多个配置文件，家庭成员共享
**依赖组件**:
- `FamilyActivityUtil` - 家庭活动
- `SharedData` - 跨进程共享
- `BlockedProfiles` - 多配置管理
- `RequestAuthorizer` - 权限管理

### 场景7: 紧急解锁机制
**核心功能**: 严格模式下的紧急解锁功能
**依赖组件**:
- `StrategyManager.emergencyUnblock()` - 紧急解锁
- `enableStrictMode` - 严格模式
- `emergencyUnblocksRemaining` - 解锁次数
- `getNextResetDate()` - 重置周期

### 场景8: 会话数据分析
**核心功能**: 展示专注会话的统计和趋势
**依赖组件**:
- `ProfileInsightsUtil` - 统计工具
- `ProfileInsightsMetrics` - 指标数据
- `dailyAggregates()` - 每日汇总
- `hourlyAggregates()` - 每小时汇总

### 场景9: NFC物理解锁
**核心功能**: 使用NFC标签物理解锁屏蔽
**依赖组件**:
- `physicalUnblockNFCTagId` - NFC标签ID
- `BlockedProfiles` - 配置NFC
- `BlockingStrategy` - 解锁策略
- `StrategyManager` - 验证解锁

### 场景10: 快捷指令集成
**核心功能**: 通过Siri快捷指令控制屏蔽
**依赖组件**:
- `toggleSessionFromDeeplink()` - 深链接控制
- `startSessionFromBackground()` - 后台启动
- `stopSessionFromBackground()` - 后台停止
- `getProfileDeepLink()` - 生成链接

## ✅ 进度跟踪

- [x] 创建 Scenarios 目录
- [x] 创建 ScenariosHomeView.swift
- [x] 实现场景1-3
- [x] 实现场景4-6
- [x] 实现场景7-10
- [x] 更新 DemoHomeView.swift
- [x] 测试所有场景
- [x] 修复编译错误（ZbWidgetAttributes, LiveActivityManager, ShortcutsIntegrationScenarioView）
- [x] 配置 widgetExtension Info.plist

---

## 🎮 娱乐组配置 - 完整开发 (2025-01-23)

### 已实现功能

#### Step 1: 权限检查
- ✅ 检测 `AuthorizationCenter.shared.authorizationStatus` 状态
- ✅ "检查权限" 按钮触发权限状态检测
- ✅ "请求授权" 按钮调用 `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
- ✅ 权限状态实时更新 UI（已授权/未授权/待定）
- ✅ 权限说明文字提供用户指导

#### Step 2: 选择娱乐 App
- ✅ 使用 `FamilyActivityPicker` 选择要限制的 App
- ✅ 显示已选择 App 数量
- ✅ 提供娱乐类分类建议（社交媒体、视频流媒体、游戏）
- ✅ 权限未授权时显示提示，禁用选择功能

#### Step 3: 每小时15分钟限制
- ✅ 默认设置每小时可用时长为 **15分钟**
- ✅ 可切换启用/禁用每小时限制
- ✅ 时长选择器（5/10/15/20/30分钟）
- ✅ 每日总时长限制设置（默认120分钟）
- ✅ **时间分布可视化**：绿色（可用）+ 灰色（休息）进度条
- ✅ 计算并显示每日使用次数和总可用时间

#### Step 4: 激活与测试
- ✅ 激活前置条件检查（权限 + App选择）
- ✅ 激活/停用配置按钮
- ✅ 调用 `AppBlockerUtil.activateRestrictions()` / `deactivateRestrictions()`
- ✅ **使用模拟功能**：1秒=1分钟加速测试
- ✅ 模拟进度显示和实时计时

#### 日志输出
- ✅ 初始化日志：权限检查结果
- ✅ 操作日志：授权请求、App选择、配置变更
- ✅ 激活日志：激活/停用操作及结果
- ✅ 模拟日志：使用时间、触发限制等

#### 测试用例说明
| ID     | 名称             | 状态    | 描述                                 |
| ------ | ---------------- | ------- | ------------------------------------ |
| TC-001 | 权限请求流程     | Ready   | 验证从未授权到授权的完整流程         |
| TC-002 | App选择功能      | Ready   | 验证 FamilyActivityPicker 选择和计数 |
| TC-003 | 每小时15分钟限制 | Ready   | 验证默认设置和时间分布计算           |
| TC-004 | 强制休息验证     | Planned | 验证达到15分钟后的强制休息触发       |
| TC-005 | 模拟器快速测试   | Ready   | 使用加速计时器验证完整流程           |

### 代码变更

**文件**: `ZenBound/DemoUI/Scenarios/EntertainmentGroupConfigView.swift`

新增组件：
- `ConfigurationStep` 枚举 - 4步骤流程管理
- `StepProgressView` - 步骤进度指示器
- `StatusCardView` - 状态卡片显示
- `AuthorizationCheckSectionView` - 权限检查区块
- `AppSelectionSectionView` - App选择区块
- `HourlyLimitSectionView` - 每小时限制设置
- `HourlyTimeVisualization` - 时间分布可视化
- `ActivationTestSectionView` - 激活测试区块
- `TestCasesDocumentationView` - 测试用例文档

### 模拟器验证

- ✅ 编译成功 (BUILD SUCCEEDED)
- ✅ 部署到 iPhone 17 (26.2) 模拟器
- ✅ UI 正常显示，所有组件可见
- ✅ 权限请求弹窗正常触发
- ✅ 测试用例列表可展开查看详情
- ✅ 日志输出区域显示初始化日志

---

## 💼 工作专注/学习计划/番茄工作法 - 完整流程开发 ✅ (2026-01-27)

### 开发目标

增强现有的三个场景视图，实现完整的端到端流程：
1. **WorkFocusScenarioView** - 工作专注模式 ✅
2. **StudyPlanScenarioView** - 学习计划模式 ✅
3. **PomodoroTechniqueScenarioView** - 番茄工作法 ✅

### 完整流程需求

#### Step 1: 权限检查
- ✅ 复用 AuthorizationCheckSectionView 组件
- ✅ Screen Time 授权检测
- ✅ 权限状态实时更新 UI

#### Step 2: 选择要屏蔽的 App
- ✅ FamilyActivityPicker 集成
- ✅ 显示已选择数量
- ✅ 权限联动

#### Step 3: 默认限制设置
- ✅ 工作专注: 手动开始/结束
- ✅ 学习计划: 每周日程自动触发
- ✅ 番茄工作法: 25分钟专注 + 5分钟休息

#### Step 4: 日志输出
- ✅ 权限检查日志
- ✅ App选择日志
- ✅ 激活/停用日志
- ✅ 模拟测试日志

#### Step 5: 测试用例说明
- ✅ 每个场景包含测试用例表格
- ✅ 模拟器快速测试支持

### 文件修改

| 文件                                | 变更                                      | 状态 |
| ----------------------------------- | ----------------------------------------- | ---- |
| WorkFocusScenarioView.swift         | 增加权限检查、App选择、完整流程、测试用例 | ✅    |
| StudyPlanScenarioView.swift         | 增加权限检查、App选择、日程激活、测试用例 | ✅    |
| PomodoroTechniqueScenarioView.swift | 增加权限检查、App选择、完整番茄循环       | ✅    |
| DemoComponents.swift                | 提取共享组件避免重复定义                  | ✅    |

### 构建验证

- ✅ xcodebuild 编译成功
- ✅ 共享组件已添加到 DemoComponents.swift
- ✅ 移除各场景中的重复组件定义

---

## 🍅 专注组配置 - 完整开发 ✅ (2026-01-27)

### 核心功能设计

专注组使用番茄工作法，帮助用户在专注期间屏蔽干扰应用，完成后自动进入休息阶段。

**文件**: `ZenBound/DemoUI/Scenarios/FocusGroupConfigView.swift`

#### Step 1: 权限检查
- ✅ 复用 AuthorizationCheckSectionView 组件
- ✅ Screen Time 授权检测
- ✅ 权限请求流程

#### Step 2: 选择干扰 App
- ✅ 使用 FamilyActivityPicker 选择专注期间要屏蔽的 App
- ✅ 显示已选择 App 数量
- ✅ 权限状态联动

#### Step 3: 番茄时钟设置
- ✅ 番茄时长: 15/25/30/45/60 分钟
- ✅ 休息时长: 5/10/15/20 分钟
- ✅ 番茄周期: 1-6 个
- ✅ 时间摘要显示（总专注、总休息、总时长）

#### Step 4: 专注限制设置
- ✅ 专注期间禁用通知
- ✅ 专注期间禁止所有App
- ✅ 番茄结束前5分钟提醒
- ✅ 休息结束前1分钟提醒
- ✅ 完成番茄后获取额外娱乐时间奖励

#### Step 5: 激活与测试
- ✅ 激活前置条件检查（权限 + App选择）
- ✅ 激活/停用配置按钮
- ✅ 番茄会话模拟器（1秒=1分钟）
- ✅ 番茄/休息阶段切换显示
- ✅ Live Activity 状态预览

#### 测试用例说明
| ID      | 名称             | 状态    | 描述                                 |
| ------- | ---------------- | ------- | ------------------------------------ |
| TC-F001 | 权限请求流程     | Ready   | 验证从未授权到授权的完整流程         |
| TC-F002 | App选择功能      | Ready   | 验证 FamilyActivityPicker 选择和计数 |
| TC-F003 | 番茄时钟配置     | Ready   | 验证时长设置和时间摘要计算           |
| TC-F004 | 番茄周期模拟     | Ready   | 模拟完整的番茄-休息-番茄循环         |
| TC-F005 | 额外娱乐时间奖励 | Planned | 验证完成番茄后娱乐时间增加           |
| TC-F006 | 提前提醒功能     | Planned | 验证5分钟/1分钟提前提醒触发          |

---

## 🔒 严格组配置 - 完整开发 ✅ (2026-01-27)

### 核心功能设计

严格组限制App当天的使用时间范围和使用时长，达到限制后完全阻止用户继续使用，直到第二天重置。

**文件**: `ZenBound/DemoUI/Scenarios/StrictGroupConfigView.swift`

#### Step 1: 权限检查
- ✅ 复用 AuthorizationCheckSectionView 组件
- ✅ Screen Time 授权检测

#### Step 2: 选择限制 App
- ✅ 使用 FamilyActivityPicker 选择要严格限制的 App
- ✅ 选择限制网站
- ✅ 关键词屏蔽功能

#### Step 3: 时间限制设置
- ✅ 每日总时长限制 (5-180 分钟)
- ✅ 单次使用时长限制 (5-60 分钟)
- ✅ 今日剩余时间显示
- ✅ 达到限制后完全阻止

#### Step 4: 时间段调度
- ✅ 全天启用开关
- ✅ 自定义生效时间段
- ✅ 选择生效日期（周一至周日）
- ✅ 多时间段支持

#### Step 5: 紧急解锁设置
- ✅ 紧急解锁开关
- ✅ 每周解锁次数限制 (1/2/3/5/10 次)
- ✅ 解锁次数追踪
- ✅ 重置周期显示

#### Step 6: 激活与测试
- ✅ 激活前置条件检查
- ✅ 严格模式激活
- ✅ 使用时间追踪模拟
- ✅ 紧急解锁模拟

#### 测试用例说明
| ID      | 名称         | 状态    | 描述                           |
| ------- | ------------ | ------- | ------------------------------ |
| TC-S001 | 权限请求流程 | Ready   | 验证从未授权到授权的完整流程   |
| TC-S002 | App选择功能  | Ready   | 验证 App/网站/关键词选择       |
| TC-S003 | 每日时长限制 | Ready   | 验证累计使用时间追踪和限制触发 |
| TC-S004 | 单次时长限制 | Ready   | 验证连续使用时间限制           |
| TC-S005 | 时间段调度   | Ready   | 验证自定义时间段生效           |
| TC-S006 | 紧急解锁流程 | Ready   | 验证紧急解锁次数消耗和重置     |
| TC-S007 | 第二天重置   | Planned | 验证午夜自动重置使用时间       |
