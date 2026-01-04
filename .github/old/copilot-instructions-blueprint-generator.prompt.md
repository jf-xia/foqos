---
description: '技术不可知的蓝图生成器，用于创建全面的 copilot-instructions.md 文件，通过分析现有代码库模式并避免假设，指导 GitHub Copilot 生成与项目标准、架构模式和精确技术版本一致的代码。'
agent: 'agent'
---

# Copilot 指令蓝图生成器

## 配置变量
${PROJECT_TYPE="Auto-detect|.NET|Java|JavaScript|TypeScript|React|Angular|Python|Multiple|Other"} <!-- 主要技术 -->
${ARCHITECTURE_STYLE="Layered|Microservices|Monolithic|Domain-Driven|Event-Driven|Serverless|Mixed"} <!-- 架构风格 -->
${CODE_QUALITY_FOCUS="Maintainability|Performance|Security|Accessibility|Testability|All"} <!-- 质量优先级 -->
${DOCUMENTATION_LEVEL="Minimal|Standard|Comprehensive"} <!-- 文档要求 -->
${TESTING_REQUIREMENTS="Unit|Integration|E2E|TDD|BDD|All"} <!-- 测试方法 -->
${VERSIONING="Semantic|CalVer|Custom"} <!-- 版本控制方式 -->

## 生成的提示

"生成一份全面的 copilot-instructions.md 文件，用来引导 GitHub Copilot 生成与我们项目标准、架构和技术版本完全一致的代码。指令必须严格基于代码库中实际的代码模式，避免做任何假设。按照以下方法执行：

### 1. 核心指令结构

```markdown
# GitHub Copilot 指令

## 优先准则

在为本仓库生成代码时：

1. **版本兼容性**：始终检测并遵守项目所使用的语言、框架和库的精确版本
2. **上下文文件**：优先参考 .github/copilot 目录中定义的模式和标准
3. **代码库模式**：当上下文文件没有提供具体指引时，扫描代码库以寻找既定模式
4. **架构一致性**：保持我们的 ${ARCHITECTURE_STYLE} 架构风格和既定边界
5. **代码质量**：在所有生成代码中优先考虑 ${CODE_QUALITY_FOCUS == "All" ? "可维护性、性能、安全性、可访问性与可测试性" : CODE_QUALITY_FOCUS}

## 技术版本检测

在生成代码之前，扫描代码库以识别：

1. **语言版本**：检测项目中使用的确切编程语言版本
   - 检查项目文件、配置文件和包管理器
   - 查找语言特定的版本指示（例如 .NET 项目中的 <LangVersion>）
   - 不要使用超出检测版本的语言特性

2. **框架版本**：识别所用框架的确切版本
   - 检查 package.json、.csproj、pom.xml、requirements.txt 等
   - 在生成代码时遵守版本约束
   - 不要建议在检测框架版本中不可用的功能

3. **库版本**：记录关键库和依赖的确切版本
   - 生成与这些特定版本兼容的代码
   - 不要使用在检测版本中不可用的 API 或特性

## 上下文文件

优先参考 .github/copilot 目录下的以下文件（若存在）：

- **architecture.md**：系统架构指引
- **tech-stack.md**：技术版本与框架详情
- **coding-standards.md**：代码风格与格式标准
- **folder-structure.md**：项目组织指南
- **exemplars.md**：示例代码模式

## 代码库扫描指令

当上下文文件未提供具体指引时：

1. 找到与要修改或创建的文件相似的文件
2. 分析以下模式：
   - 命名约定
   - 代码组织
   - 错误处理
   - 日志方法
   - 文档风格
   - 测试模式
   
3. 遵循代码库中最一致的模式
4. 当存在冲突模式时，优先采用较新的文件或测试覆盖率更高的文件中的模式
5. 不要引入代码库中未出现的模式

## 代码质量标准

${CODE_QUALITY_FOCUS.includes("Maintainability") || CODE_QUALITY_FOCUS == "All" ? `### 可维护性
- 编写自说明代码，使用清晰命名
- 遵循代码库中既定的命名和组织规范
- 遵循既有模式以保持一致性
- 保持函数职责单一
- 限制函数复杂度与长度，与现有模式一致` : ""}

${CODE_QUALITY_FOCUS.includes("Performance") || CODE_QUALITY_FOCUS == "All" ? `### 性能
- 遵循现有的内存和资源管理模式
- 与现有模式匹配处理计算密集型操作的方式
- 遵循已有的异步操作模式
- 在代码库证据中一致地应用缓存
- 根据代码库中可见的模式进行优化` : ""}

${CODE_QUALITY_FOCUS.includes("Security") || CODE_QUALITY_FOCUS == "All" ? `### 安全
- 遵循现有的输入验证模式
- 应用代码库中使用的相同消毒/清理技术
- 使用与现有代码一致的参数化查询
- 遵循既有的认证与授权模式
- 按代码库中现有做法处理敏感数据` : ""}

${CODE_QUALITY_FOCUS.includes("Accessibility") || CODE_QUALITY_FOCUS == "All" ? `### 可访问性
- 遵循代码库中现有的可访问性模式
- 在组件中按照现有用法匹配 ARIA 属性
- 保持与现有代码一致的键盘导航支持
- 遵循现有的色彩与对比度规范
- 按照代码库中一致的文本替代（alt text）模式应用` : ""}

${CODE_QUALITY_FOCUS.includes("Testability") || CODE_QUALITY_FOCUS == "All" ? `### 可测试性
- 遵循已建立的可测试代码模式
- 与现有代码的依赖注入方法保持一致
- 应用管理依赖的相同模式
- 遵循既有的模拟（mock）和测试替身模式
- 匹配现有测试中使用的测试风格` : ""}

## 文档要求

${DOCUMENTATION_LEVEL == "Minimal" ? 
`- 与现有代码中的注释级别和风格保持一致
- 根据代码库中现有模式进行文档说明
- 对非显而易见的行为按现有模式进行记录
- 使用与代码库中相同的参数说明格式` : ""}

${DOCUMENTATION_LEVEL == "Standard" ? 
`- 遵循代码库中存在的文档格式和风格
- 匹配现有代码的 XML/JSDoc 风格与完整性
- 对参数、返回值和异常按相同风格进行注释
- 遵循现有代码中示例用法的模式
- 匹配类级文档的风格与内容` : ""}

${DOCUMENTATION_LEVEL == "Comprehensive" ? 
`- 遵循代码库中最为详细的文档模式
- 与最详尽文件保持相同风格和完整性
- 精确记录设计决策的说明
- 遵循现有文档的链接与引用模式
- 匹配现有文件中详尽的说明层级` : ""}

## 测试方法

${TESTING_REQUIREMENTS.includes("Unit") || TESTING_REQUIREMENTS == "All" ? 
`### 单元测试
- 匹配现有单元测试的结构与风格
- 遵循统一的测试类与方法命名规范
- 使用现有测试中的断言模式
- 应用代码库中使用的模拟方法
- 遵循现有的测试隔离模式` : ""}

${TESTING_REQUIREMENTS.includes("Integration") || TESTING_REQUIREMENTS == "All" ? 
`### 集成测试
- 遵循代码库中相同的集成测试模式
- 匹配现有的测试数据准备与清理方式
- 使用相同的方法测试组件交互
- 遵循现有的系统行为验证模式` : ""}

${TESTING_REQUIREMENTS.includes("E2E") || TESTING_REQUIREMENTS == "All" ? 
`### 端到端测试
- 匹配现有的 E2E 测试结构与模式
- 遵循既定的 UI 测试模式
- 应用相同的方法来验证用户旅程` : ""}

${TESTING_REQUIREMENTS.includes("TDD") || TESTING_REQUIREMENTS == "All" ? 
`### 测试驱动开发
- 遵循代码库中显现的 TDD 模式
- 匹配现有测试中测试用例的演进方式
- 在测试通过后应用相同的重构模式` : ""}

${TESTING_REQUIREMENTS.includes("BDD") || TESTING_REQUIREMENTS == "All" ? 
`### 行为驱动开发
- 匹配现有测试中 Given-When-Then 的结构
- 遵循相同的行为描述模式
- 在测试中保持一致的业务关注度` : ""}

## 技术特定指南

${PROJECT_TYPE == ".NET" || PROJECT_TYPE == "Auto-detect" || PROJECT_TYPE == "Multiple" ? `### .NET 指南
- 检测并严格遵守项目中使用的具体 .NET 版本
- 仅使用与检测版本兼容的 C# 语言特性
- 精确复用代码库中出现的 LINQ 使用模式
- 匹配现有代码中的 async/await 使用模式
- 应用代码库中使用的依赖注入方法
- 使用与现有代码一致的集合类型与使用方式` : ""}

${PROJECT_TYPE == "Java" || PROJECT_TYPE == "Auto-detect" || PROJECT_TYPE == "Multiple" ? `### Java 指南
- 检测并遵守项目中使用的具体 Java 版本
- 遵循代码库中存在的相同设计模式
- 匹配现有代码中的异常处理模式
- 使用与现有代码一致的集合类型与处理方式
- 应用代码库中显现的依赖注入模式` : ""}

${PROJECT_TYPE == "JavaScript" || PROJECT_TYPE == "TypeScript" || PROJECT_TYPE == "Auto-detect" || PROJECT_TYPE == "Multiple" ? `### JavaScript/TypeScript 指南
- 检测并遵守项目中使用的 ECMAScript/TypeScript 版本
- 遵循与现有代码相同的模块导入/导出模式
- 匹配 TypeScript 类型定义的现有模式
- 使用与现有代码一致的异步模式（Promise、async/await）
- 遵循相似文件中的错误处理模式` : ""}

${PROJECT_TYPE == "React" || PROJECT_TYPE == "Auto-detect" || PROJECT_TYPE == "Multiple" ? `### React 指南
- 检测并遵守项目中使用的 React 版本
- 匹配现有组件的结构模式
- 遵循现有代码中的 hooks 与生命周期使用方式
- 应用项目中使用的状态管理方法
- 匹配现有代码中 prop 类型与验证模式` : ""}

${PROJECT_TYPE == "Angular" || PROJECT_TYPE == "Auto-detect" || PROJECT_TYPE == "Multiple" ? `### Angular 指南
- 检测并遵守项目中使用的 Angular 版本
- 遵循现有代码中组件与模块的模式
- 精确复用已有代码中的装饰器使用方式
- 应用代码库中使用的 RxJS 模式
- 遵循组件通信的既定模式` : ""}

${PROJECT_TYPE == "Python" || PROJECT_TYPE == "Auto-detect" || PROJECT_TYPE == "Multiple" ? `### Python 指南
- 检测并遵守项目中使用的 Python 版本
- 遵循现有模块中相同的导入组织方式
- 如果项目使用类型注解，匹配现有的类型注解风格
- 应用现有代码中的错误处理模式
- 遵循现有模块组织模式` : ""}

## 版本控制指南

${VERSIONING == "Semantic" ? 
`- 遵循代码库中应用的语义化版本控制模式
- 匹配现有的破坏性更改说明方式
- 采用与项目中一致的弃用声明方式` : ""}

${VERSIONING == "CalVer" ? 
`- 遵循代码库中应用的日历版本控制模式
- 匹配现有的变更记录格式
- 使用相同的方法突出重要变更` : ""}

${VERSIONING == "Custom" ? 
`- 匹配代码库中观察到的自定义版本模式
- 使用项目文档中一致的变更日志格式
- 应用项目中使用的相同打标签约定` : ""}

## 一般最佳实践

- 精确遵循现有代码中的命名约定
- 匹配类似文件的代码组织模式
- 应用与现有代码一致的错误处理方式
- 遵循现有的测试方法
- 匹配现有代码中的日志记录模式
- 使用代码库中现有的配置方法

## 项目特定指引

- 在生成任何代码之前彻底扫描代码库
- 严格保持现有的架构边界
- 匹配周围代码的风格与模式
- 在有疑问时，优先以与现有代码一致性为准，而非外部最佳实践或较新的语言特性
```

### 2. 代码库分析指令

在创建 copilot-instructions.md 文件之前，先分析代码库以：

1. **识别确切技术版本**：
   - ${PROJECT_TYPE == "Auto-detect" ? "通过扫描文件扩展名和配置文件检测所有编程语言、框架和库" : `重点关注 ${PROJECT_TYPE} 技术`}
   - 从项目文件、package.json、.csproj 等提取精确版本信息
   - 记录版本约束与兼容性要求

2. **了解架构**：
   - 分析文件夹结构与模块组织
   - 识别清晰的分层边界与组件关系
   - 记录组件间的通信模式

3. **记录代码模式**：
   - 编目不同代码元素的命名约定
   - 注意文档风格与完整性
   - 记录错误处理模式
   - 映射测试方法与覆盖情况

4. **注意质量标准**：
   - 识别实际采用的性能优化技术
   - 记录实现的安全实践
   - 注意已存在的可访问性特性（如适用）
   - 记录代码库中明显的代码质量模式

### 3. 实施说明

最终的 copilot-instructions.md 应当：
- 放置在 .github/copilot 目录下
- 仅引用代码库中实际存在的模式与标准
- 包含明确的版本兼容性要求
- 避免规定代码库中未出现的实践
- 提供来自代码库的具体示例
- 在对 Copilot 有效指导的同时保持简洁

重要：只包含基于代码库中实际观察到的指引。明确指示 Copilot 在存在疑问时优先考虑与现有代码的一致性，而不是外部最佳实践或更新的语言特性。"

## 预期输出

一份全面的 copilot-instructions.md 文件，用来指导 GitHub Copilot 生成完全兼容你现有技术版本并遵循既定模式与架构的代码。