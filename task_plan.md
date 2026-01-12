# Task Plan: Foqos 项目完整重构

## Goal
对 Foqos iOS 应用进行全面重构，包括：(1) 深入分析每个代码文件的角色和流程；(2) 为所有关键代码添加详细注释；(3) 识别架构问题和改进机会；(4) 制定阶段性重构计划并逐步实施。

## Current Phase
Phase 1: 规划和现状分析

## Phases

### Phase 1: 规划和现状分析 ✅
**目标**: 建立规划框架，整理现有分析成果
- [x] 学习 planning-with-files 方法论
- [x] 查看现有文档（ARCHITECTURE_OVERVIEW.md, REFACTORING_ANALYSIS.md等）
- [x] 创建规划文件（task_plan.md, findings.md, progress.md）
- [x] 确定分析范围和优先级
- **Status:** complete

### Phase 2: 核心业务逻辑深度分析
**目标**: 深入理解和注释核心组件
- [ ] 分析 foqosApp.swift - 应用入口和依赖注入
- [ ] 分析 StrategyManager.swift (963行) - 会话管理核心
  - [ ] 理解策略模式的实现
  - [ ] 分析会话生命周期管理
  - [ ] 识别重构机会
- [ ] 分析 AppBlockerUtil.swift - 屏蔽执行引擎
- [ ] 分析 BlockedProfiles.swift (429行) - 数据模型
  - [ ] 理解数据关系
  - [ ] 识别模型复杂度问题
- [ ] 分析所有 BlockingStrategy 实现（9种策略）
- [ ] 为以上文件添加详细中英文注释
- **Status:** not-started
- **预计时间:** 2-3 天

### Phase 3: 系统集成和扩展分析
**目标**: 理解 App 与系统/Extensions 的交互
- [ ] 分析 DeviceActivityMonitorExtension - 系统触发逻辑
- [ ] 分析 ShieldConfigurationExtension - Shield UI 定制
- [ ] 分析 FoqosWidget 和 LiveActivity - Widget 集成
- [ ] 分析 SharedData - App Group 通信机制
- [ ] 分析 App Intents (Shortcuts 支持)
- [ ] 理解权限流程（RequestAuthorizer）
- [ ] 为以上文件添加详细注释
- **Status:** not-started
- **预计时间:** 1-2 天

### Phase 4: UI 层和支持工具分析
**目标**: 完善对 Views、Components、Utils 的理解
- [ ] 分析主要 Views（HomeView, Dashboard, ProfileView, SessionView）
- [ ] 分析 Components（BlockedProfileCards, Strategy 组件等）
- [ ] 分析 Utils 工具类（15+ 个）
  - [ ] DeviceActivityCenterUtil
  - [ ] NFCScannerUtil
  - [ ] TimersUtil
  - [ ] LiveActivityManager
  - [ ] 其他工具类
- [ ] 为关键文件添加注释
- **Status:** not-started
- **预计时间:** 2 天

### Phase 5: 问题总结和重构计划制定
**目标**: 整合分析结果，制定可执行的重构计划
- [ ] 更新 findings.md 中的所有发现
- [ ] 汇总架构问题和代码异味
- [ ] 评估技术债务的优先级
- [ ] 制定详细的重构计划
  - [ ] 阶段划分
  - [ ] 风险评估
  - [ ] 测试策略
  - [ ] 回滚方案
- [ ] 创建重构 Roadmap 文档
- **Status:** not-started
- **预计时间:** 1 天

### Phase 6: 与用户讨论和计划优化
**目标**: 确保计划符合用户需求和项目实际
- [ ] 向用户展示分析成果
- [ ] 讨论重构优先级和范围
- [ ] 调整计划基于用户反馈
- [ ] 确定下一步行动
- **Status:** not-started
- **预计时间:** 按需

### Phase 7: 执行重构（按计划逐步实施）
**目标**: 根据最终计划开始实际重构工作
- [ ] Phase 7.1: 建立测试基础设施
- [ ] Phase 7.2: 拆分 StrategyManager（P0 问题）
- [ ] Phase 7.3: 重构 BlockedProfiles 模型（P0 问题）
- [ ] Phase 7.4: 引入统一的依赖注入（P0 问题）
- [ ] Phase 7.5: 其他 P1/P2 问题的重构
- **Status:** not-started
- **预计时间:** 待定（基于讨论结果）

## Decision Log

| 决策                            | 理由                                                                  | 日期       |
| ------------------------------- | --------------------------------------------------------------------- | ---------- |
| 使用 planning-with-files 方法论 | 复杂任务需要持久化的工作记忆，避免上下文丢失                          | 2026-01-12 |
| 优先分析核心业务逻辑（Phase 2） | StrategyManager 和 BlockedProfiles 是系统的心脏，理解它们是重构的基础 | 2026-01-12 |
| 为代码添加中英文注释            | 提高代码可读性，帮助理解复杂逻辑，方便未来维护                        | 2026-01-12 |

## Errors Encountered

| Error | Phase | Resolution |
| ----- | ----- | ---------- |
| -     | -     | -          |

## Notes

- 项目已有相当完善的文档基础（ARCHITECTURE_OVERVIEW.md, REFACTORING_ANALYSIS.md 等）
- 需要将文档分析转化为实际的代码级理解
- 重构是长期任务，需要分阶段、小步快跑、频繁测试
- 关键是在添加注释的过程中深入理解每个文件的作用

## Next Actions

1. ✅ 创建 findings.md 和 progress.md
2. 开始 Phase 2：分析 foqosApp.swift
3. 每完成一个主要组件分析，更新 findings.md
4. 遵循 2-Action Rule：每 2 次文件读取后，立即记录发现
