# ZenBound 屏幕时间管理应用开发计划

## 项目概述
基于 Foqos 项目架构，开发一个全新的屏幕使用时间管理应用 ZenBound，包含宠物猫养成、任务系统、成就激励和多种应用组模式。

## 阶段计划

### Phase 1: 基础架构搭建 [in_progress]
- [x] 项目结构分析
- [ ] 配置 entitlements 和 App Groups
- [ ] 创建核心数据模型 (SwiftData)
- [ ] 创建 SharedData 用于 App Group 通信
- [ ] 创建授权管理器 (RequestAuthorizer)
- [ ] 创建应用屏蔽工具 (AppBlockerUtil)

### Phase 2: 应用组模式 (Group Modes) [not_started]
- [ ] 专注组 (Focus Group) - 番茄工作法
- [ ] 严格组 (Strict Group) - 时间限制
- [ ] 娱乐组 (Entertainment Group) - 假期模式

### Phase 3: 宠物系统 [not_started]
- [ ] 宠物猫状态模型
- [ ] 宠物技能系统
- [ ] 奖励进度追踪

### Phase 4: 任务系统 [not_started]
- [ ] 任务模型和管理器
- [ ] 打卡功能
- [ ] 任务历史记录

### Phase 5: 成就激励系统 [not_started]
- [ ] 成就徽章模型
- [ ] 奖励兑换系统
- [ ] 每日/每周任务进度

### Phase 6: Shield 互动 [not_started]
- [ ] 自定义 Shield UI
- [ ] Shield Action 处理
- [ ] 替代活动建议

### Phase 7: UI 视图开发 [not_started]
- [ ] 主页视图
- [ ] 配置页面
- [ ] 宠物视图
- [ ] 任务视图
- [ ] 成就视图

## 技术架构

### 核心依赖
- SwiftUI + SwiftData
- FamilyControls + ManagedSettings + DeviceActivity
- App Groups 跨进程通信
- WidgetKit (Live Activity)

### 目录结构
```
ZenBound/
├── ZenBound/
│   ├── Models/
│   │   ├── Pet/
│   │   ├── Task/
│   │   ├── Achievement/
│   │   ├── GroupMode/
│   │   └── Shared.swift
│   ├── Utils/
│   │   ├── AppBlockerUtil.swift
│   │   ├── RequestAuthorizer.swift
│   │   ├── SessionManager.swift
│   │   └── DeviceActivityUtil.swift
│   ├── Views/
│   │   ├── Home/
│   │   ├── Pet/
│   │   ├── Task/
│   │   ├── Achievement/
│   │   └── Settings/
│   └── ZenBoundApp.swift
├── monitor/
├── shieldConfig/
├── shieldAction/
└── widget/
```

## 错误记录
| Error | Attempt | Resolution |
| ----- | ------- | ---------- |
| -     | -       | -          |

## 最后更新
2026-01-21 - 初始计划创建
