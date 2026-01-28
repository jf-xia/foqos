# Findings & Decisions

## Requirements
- 用户请求：使用 MCP 在 EmilyiPhone 真机上执行娱乐组配置测试，并按照现有测试指南完成验证并记录结果。

## Research Findings
- 快速步骤：QUICK_TEST_START.md 提供 9 个场景的顺序检查，重点覆盖权限、App 选择、每小时/每日限制、激活、Shield 触发与模拟。
- 真机速查：QUICK_TEST_GUIDE_EMILYIPHONE.md 聚焦 3 个核心场景（权限检查、App 选择、时间限制配置），给出 UI 预期与日志验证要点。
- 测试计划：ENTERTAINMENT_GROUP_TEST_PLAN.md 列出验证目标、存储位置（App Group `group.com.zenbound.data`，key `entertainmentConfig`）和多项场景（激活、监控、数据持久化等）。
- 代码/数据位置：主配置界面在 ZenBound/DemoUI/Scenarios/EntertainmentGroupConfigView.swift；数据模型在 ZenBound/Models/Shared.swift（EntertainmentConfig）。

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 使用 MCP mobile 工具驱动 EmilyiPhone 进行手动验证 | 与用户需求一致，设备在线可用 |
| 执行顺序以 QUICK_TEST_START.md 的 9 场景为主、并结合 EmilyiPhone 快速指南的 3 核心场景 | 覆盖高优先级路径，减少漏测 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| go-ios `ios tunnel start` 需 root，`--userspace` 模式端口 60105 已被占用，`ios runwda` 缺少 xctestconfig | 待确认是否可用 sudo 或提供 WDA xctestconfig，或释放端口/使用现有 userspace tunnel (60151) |

## Resources
- QUICK_TEST_START.md
- QUICK_TEST_GUIDE_EMILYIPHONE.md
- ENTERTAINMENT_GROUP_TEST_PLAN.md
- ENTERTAINMENT_GROUP_QUICK_REFERENCE.md
- ZenBound/DemoUI/Scenarios/EntertainmentGroupConfigView.swift
- ZenBound/Models/Shared.swift

## Visual/Browser Findings
- 无（本次仅阅读文本资料）
