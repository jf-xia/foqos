# ZenBound 10种应用场景开发计划

> 创建时间: 2026-01-23

## 📋 任务目标

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
