# ZenBound 10种应用场景开发计划

> 创建时间: 2026-01-23

## 📋 任务目标

根据项目现有功能和逻辑，组合10种不同的应用场景，在DemoUI中开发实施，每个场景包含：
- 场景描述和使用说明
- 相关函数的引用/依赖
- 改进建议

## 🎯 10种应用场景概览

| # | 场景名称 | 核心功能组合 | 状态 |
|---|---------|-------------|------|
| 1 | 工作专注模式 | BlockedProfiles + ManualBlockingStrategy + LiveActivity | ✅ |
| 2 | 学习计划模式 | Schedule + ScheduleTimerActivity + ProfileInsights | ✅ |
| 3 | 社交媒体戒断 | AppBlockerUtil + StrategyManager + FocusMessages | ✅ |
| 4 | 睡前数字戒断 | Schedule + BreakTimerActivity + TimersUtil | ✅ |
| 5 | 番茄工作法 | ShortcutTimerBlockingStrategy + BreakTimer + Notification | ✅ |
| 6 | 家庭共享管理 | FamilyActivityUtil + SharedData + MultiProfile | ✅ |
| 7 | 紧急解锁机制 | EmergencyUnblock + StrategyManager + StrictMode | ✅ |
| 8 | 会话数据分析 | ProfileInsightsUtil + Sessions + Charts | ✅ |
| 9 | NFC物理解锁 | PhysicalUnlock + NFCTagId + BlockingStrategy | ✅ |
| 10 | 快捷指令集成 | AppIntents + DeepLink + BackgroundSession | ✅ |

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

- [ ] 创建 Scenarios 目录
- [ ] 创建 ScenariosHomeView.swift
- [ ] 实现场景1-3
- [ ] 实现场景4-6
- [ ] 实现场景7-10
- [ ] 更新 DemoHomeView.swift
- [ ] 测试所有场景
