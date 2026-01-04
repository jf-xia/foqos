---
description: "为 GitHub Copilot 生成迁移与代码演进说明。分析两个项目版本（分支、提交或发布）之间的差异，创建精确说明，帮助 Copilot 在技术迁移、重大重构或框架升级期间保持一致性。"
agent: "agent"
---

# 迁移与代码演进说明生成器

## 配置变量

```
${MIGRATION_TYPE="Framework Version|Architecture Refactoring|Technology Migration|Dependencies Update|Pattern Changes"}
<!-- 迁移或演进的类型 -->

${SOURCE_REFERENCE="branch|commit|tag"}
<!-- 源参考点（变更前状态） -->

${TARGET_REFERENCE="branch|commit|tag"}
<!-- 目标参考点（变更后状态） -->

${ANALYSIS_SCOPE="Entire project|Specific folder|Modified files only"}
<!-- 分析范围 -->

${CHANGE_FOCUS="Breaking Changes|New Conventions|Obsolete Patterns|API Changes|Configuration"}
<!-- 变化关注点 -->

${AUTOMATION_LEVEL="Conservative|Balanced|Aggressive"}
<!-- 为 Copilot 建议的自动化级别 -->

${GENERATE_EXAMPLES="true|false"}
<!-- 是否包含转换示例 -->

${VALIDATION_REQUIRED="true|false"}
<!-- 应用前是否需要验证 -->
```

## 生成的提示

```
"分析两个项目状态之间的代码演进，生成可供 GitHub Copilot 使用的精确迁移说明。请遵循以下方法：

### 阶段 1：比较状态分析

#### 结构性变更检测
- 比较 ${SOURCE_REFERENCE} 与 ${TARGET_REFERENCE} 之间的文件夹结构
- 识别被移动、重命名或删除的文件
- 分析配置文件的变更
- 记录新增和移除的依赖项

#### 代码转换分析
${MIGRATION_TYPE == "Framework Version" ?
  "- 识别框架版本间的 API 变更
   - 分析所使用的新特性
   - 记录已弃用的方法/属性
   - 注意语法或约定的改变" : ""}

${MIGRATION_TYPE == "Architecture Refactoring" ?
  "- 分析架构模式的改变
   - 识别引入的新抽象
   - 记录职责的重新分配
   - 注意数据流的更改" : ""}

${MIGRATION_TYPE == "Technology Migration" ?
  "- 分析一种技术被另一种替代的情况
   - 识别功能等价项
   - 记录 API 与语法的变化
   - 注意新增依赖与配置" : ""}

#### 转换模式提取
- 识别反复出现的转换
- 分析从旧格式到新格式的转换规则
- 记录例外和特殊情况
- 创建“前/后”对应矩阵

### 阶段 2：迁移说明生成

创建一个 `.github/copilot-migration-instructions.md` 文件，结构如下：

\`\`\`markdown
# GitHub Copilot 迁移说明

## 迁移上下文
- **类型**: ${MIGRATION_TYPE}
- **从**: ${SOURCE_REFERENCE}
- **到**: ${TARGET_REFERENCE}
- **日期**: [GENERATION_DATE]
- **范围**: ${ANALYSIS_SCOPE}

## 自动转换规则

### 1. 强制性转换
${AUTOMATION_LEVEL != "Conservative" ?
  "[自动转换规则]
   - **旧模式**: [OLD_CODE]
   - **新模式**: [NEW_CODE]
   - **触发条件**: 检测到该模式时
   - **动作**: 自动应用的转换" : ""}

### 2. 需验证的转换
${VALIDATION_REQUIRED == "true" ?
  "[需验证的转换]
   - **检测到的模式**: [DESCRIPTION]
   - **建议的转换**: [NEW_APPROACH]
   - **所需验证**: [VALIDATION_CRITERIA]
   - **替代项**: [ALTERNATIVE_OPTIONS]" : ""}

### 3. API 对应关系
${CHANGE_FOCUS == "API Changes" || MIGRATION_TYPE == "Framework Version" ?
  "[API 对应表]
   | 旧 API   | 新 API   | 说明     | 示例        |
   | --------- | --------- | --------- | -------------- |
   | [OLD_API] | [NEW_API] | [CHANGES] | [CODE_EXAMPLE] | " : ""} |

### 4. 推荐采用的新模式
[检测到的新兴模式]
- **模式**: [PATTERN_NAME]
- **何时使用**: [WHEN_TO_USE]
- **实现方式**: [HOW_TO_IMPLEMENT]
- **优点**: [ADVANTAGES]

### 5. 需避免的过时模式
[检测到的过时模式]
- **过时模式**: [OLD_PATTERN]
- **为何避免**: [REASONS]
- **替代方案**: [NEW_PATTERN]
- **迁移步骤**: [CONVERSION_STEPS]

## 按文件类型的具体说明

${GENERATE_EXAMPLES == "true" ?
  "### 配置文件
   [配置转换示例]

   ### 主要源码文件
   [源码转换示例]

   ### 测试文件
   [测试转换示例]" : ""}

## 验证与安全

### 自动控制点
- 每次转换后需执行的验证
- 验证通过的测试项目
- 需监控的性能指标
- 需执行的兼容性检查

### 手动升级
需要人工介入的情况：
- [复杂情况列表]
- [架构决策]
- [业务影响]

## 迁移监控

### 跟踪指标
- 自动迁移的代码比例
- 需要手动验证的次数
- 自动转换错误率
- 每文件平均迁移时间

### 错误上报
如何向 Copilot 报告不正确的转换：
- 提高规则的反馈模式
- 记录需要例外处理的情况
- 调整说明的方式

\`\`\`

### 阶段 3：上下文示例生成

${GENERATE_EXAMPLES == "true" ?
  "#### 转换示例
   对于每个识别到的模式，生成：

   \`\`\`
   // 变更前 (${SOURCE_REFERENCE})
   [OLD_CODE_EXAMPLE]

   // 变更后 (${TARGET_REFERENCE})
   [NEW_CODE_EXAMPLE]

   // COPILOT 指示
   当检测到此模式 [TRIGGER] 时，将其转换为 [NEW_PATTERN]，并按照以下步骤执行: [STEPS]
   \`\`\`" : ""}

### 阶段 4：验证与优化

#### 说明测试
- 在测试代码上应用说明
- 验证转换的一致性
- 根据结果调整规则
- 记录例外与边缘情况

#### 迭代优化
${AUTOMATION_LEVEL == "Aggressive" ?
  "- 精细化规则以最大化自动化
   - 降低误报率
   - 提高转换准确性
   - 记录经验教训" : ""}

### 最终结果

让 GitHub Copilot 能够：
1. **自动应用** 相同的转换到未来的修改中
2. **与新采用的约定保持一致**
3. **通过自动建议避免过时模式**
4. **利用已有经验加速未来迁移**
5. **降低错误率**，通过自动化重复性转换提高可靠性

这些说明将 Copilot 转变为一位智能迁移助手，能够在未来持续且可靠地复现你的技术演进决策。
"
```
