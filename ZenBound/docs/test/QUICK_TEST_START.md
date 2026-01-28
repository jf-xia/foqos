# 🎬 娱乐组配置测试 - 快速启动指南

## 🚀 立即开始测试

### 第一步：启动应用

在 EmilyiPhone 真机上：

```
1. 找到 ZenBound 应用
2. 点击打开
3. 等待应用完全加载（约 2-3 秒）
```

### 第二步：导航到测试页面

```
应用主界面 → 点击右上角菜单 (☰) 或向下滚动
          ↓
选择 "Scenarios" 或 "Demo" 区域
          ↓
找到 "Entertainment Group Configuration" 
          ↓
点击进入
```

### 第三步：开始测试场景 1 - 权限检查

**预期**: 应该看到一个"Request Authorization"按钮或权限状态

**检查点**:
- ✅ 应用是否正确显示权限检查步骤
- ✅ 按钮是否可以点击
- ✅ 系统是否弹出权限请求对话框

**如果看到错误**:
1. 检查日志：`log stream --predicate 'eventMessage contains[cd] "Entertainment"' --level debug`
2. 查看 Console.app 中的任何崩溃信息
3. 记录在 TEST_RESULTS_RECORD.md 中

---

## 📋 按顺序测试的 9 个场景

### 📌 场景 1：权限检查 ⭐⭐⭐ 高优先级

**时间**: ~2 分钟  
**目标**: 验证屏幕时间权限可以正确请求

```
步骤 1: 观察当前权限状态
步骤 2: 如果未授予，点击 "Request Authorization"
步骤 3: 在系统对话框中选择 "Allow"
步骤 4: 验证权限状态更新为 "✓ Granted"
```

**通过条件**:
- [ ] 权限状态正确显示
- [ ] 系统对话框出现
- [ ] 授予后可以继续

**失败处理**: 如果权限拒绝，重试或检查 Settings > Privacy > Screen Time

---

### 📌 场景 2：App 选择 ⭐⭐ 中优先级

**时间**: ~3 分钟  
**目标**: 选择要限制的应用

```
步骤 1: 滚动到 "Select Apps" 部分
步骤 2: 点击 "Choose Apps with FamilyActivityPicker"
步骤 3: 在弹出的选择器中选择：
        - Games（选至少 2 个游戏）
        - 或 Social（选至少 1 个社交应用）
步骤 4: 点击完成返回
步骤 5: 验证选择的应用数量显示正确
```

**通过条件**:
- [ ] FamilyActivityPicker 正常打开
- [ ] 可以正确选择应用
- [ ] 已选应用数量显示正确

---

### 📌 场景 3：每小时限制配置 ⭐⭐⭐ 高优先级

**时间**: ~2 分钟  
**目标**: 配置每小时限制（推荐 15 分钟）

```
步骤 1: 滚动到 "Time Limits - Hourly"
步骤 2: 启用 "Enable Hourly Limit" 开关
步骤 3: 选择每小时使用时长：15 分钟
步骤 4: 观察时间分配可视化：
        - 绿色部分：15 分钟（可用）
        - 灰色部分：45 分钟（休息）
步骤 5: 验证总计：15 + 45 = 60 分钟
```

**通过条件**:
- [ ] 开关正确启用
- [ ] 可以选择时间
- [ ] 可视化显示准确

---

### 📌 场景 4：每日限制配置 ⭐⭐⭐ 高优先级

**时间**: ~2 分钟  
**目标**: 配置每日限制（推荐 120 分钟）

```
步骤 1: 滚动到 "Time Limits - Daily"
步骤 2: 设置每日总时长：120 分钟
步骤 3: 设置单次使用时长：30 分钟
步骤 4: 观察显示的可用使用次数：
        - 应显示 4 次（120 ÷ 30 = 4）
```

**通过条件**:
- [ ] 每日限制可以设置
- [ ] 计算正确（4 次）
- [ ] 数值显示准确

---

### 📌 场景 5：激活配置 ⭐⭐⭐ 高优先级

**时间**: ~1 分钟  
**目标**: 激活配置并启动监控

```
步骤 1: 滚动到 "Activation & Testing"
步骤 2: 点击 "Activate Configuration" 按钮
步骤 3: 观察：
        - 按钮变为 "Deactivate Configuration"
        - 状态指示器变为绿色
        - 日志输出 "✅ Configuration activated successfully"
步骤 4: 查看日志，应显示启动了 24 个小时的监控
```

**通过条件**:
- [ ] 按钮状态改变
- [ ] 状态指示器更新
- [ ] 所有 24 小时监控启动

---

### 📌 场景 6：使用时间模拟 ⭐⭐ 中优先级

**时间**: ~3 分钟  
**目标**: 验证时间累计和进度条

```
步骤 1: 保持在 "Activation & Testing" 部分
步骤 2: 在文本框中输入 5
步骤 3: 点击 "Add 5 Minutes to Current Hour"
步骤 4: 重复 3 次：
        - 点击 4 次（5 分钟 × 3 = 15 分钟，达到每小时限制）
步骤 5: 观察：
        - 进度条从 0% → 100%
        - 时间显示：5 → 10 → 15
        - 达到限制时显示警告
```

**通过条件**:
- [ ] 时间正确累计
- [ ] 进度条实时更新
- [ ] 达到限制有通知

---

### 📌 场景 7：Shield 显示 ⭐⭐ 中优先级

**时间**: ~2 分钟  
**目标**: 验证限制时 Shield 正确显示

```
步骤 1: 从演示应用返回主屏幕
步骤 2: 打开之前选择的被限制应用（例如：游戏）
步骤 3: 观察是否显示 Shield 屏幕：
        - 半透明黑色背景
        - 白色消息文本
        - "OK" 或关闭按钮
步骤 4: 验证消息内容：
        - "Daily limit reached" 或类似信息
        - 显示剩余时间信息（如有）
步骤 5: 点击按钮关闭 Shield
```

**通过条件**:
- [ ] Shield 正确显示
- [ ] 样式和消息清晰
- [ ] 可以正确关闭

**备注**: 仅当已添加足够使用时间来达到限制时才会显示 Shield

---

### 📌 场景 8：时间重置 ⭐⭐⭐ 高优先级

**时间**: ~5 分钟 或需要等待/改时间  
**目标**: 验证每小时和每日自动重置

```
方法 A - 自然等待（推荐）:
步骤 1: 记录当前时间，例如 2:45 PM
步骤 2: 在配置页等待直到下一个整点，例如 3:00 PM
步骤 3: 观察日志输出中是否出现 "🔄 Hourly usage reset"
步骤 4: 验证使用时间重置为 0

方法 B - 手动改时间（快速）:
步骤 1: 打开 Settings > General > Date & Time
步骤 2: 关闭 "Set Automatically"
步骤 3: 改为下一个小时（例如：2:45 → 3:00）
步骤 4: 等待 3 秒，观察日志
步骤 5: 返回配置页验证重置
步骤 6: 改为下一个日期测试每日重置
```

**通过条件**:
- [ ] 小时变化时自动重置
- [ ] 日期变化时自动重置
- [ ] 日志有重置记录

---

### 📌 场景 9：数据持久化 ⭐⭐⭐ 高优先级

**时间**: ~3 分钟  
**目标**: 验证配置在应用重启后保持

```
步骤 1: 记录当前配置：
        - 每小时限制：15 分钟
        - 每日限制：120 分钟
        - 当前使用：X 分钟
        - 激活状态：激活

步骤 2: 完全关闭应用（向上滑动卡片或强制关闭）
        - 或从 Settings > General > iPhone Storage 卸载
        - 或通过 Xcode 停止应用

步骤 3: 重新启动应用（点击图标）

步骤 4: 导航回 Scenarios > Entertainment Group Configuration

步骤 5: 验证所有数据保存：
        - 时间限制值相同
        - 使用时间保持不变
        - 激活状态恢复
```

**通过条件**:
- [ ] 配置完全保存
- [ ] 使用数据持久化
- [ ] 激活状态恢复

---

## 🔍 监控日志

### 收集日志的命令

打开 Terminal 并运行：

```bash
# 查看所有 Entertainment 相关日志
log stream --predicate 'eventMessage contains[cd] "Entertainment"' --level debug

# 或查看更详细的日志
log stream --predicate 'eventMessage contains[cd] "Entertainment" OR processImagePath contains "ZenBound"' --level debug --color --style=compact
```

### 预期日志输出示例

**激活配置时**:
```
✅ Configuration activated successfully
📊 Starting hourly monitoring with 24 hours
🕐 Hour 0: Monitor started
🕐 Hour 1: Monitor started
...
```

**添加使用时间时**:
```
📈 Usage added: 5 minutes
⏱️ Current hour usage: 15 / 15 minutes
🚨 Hour limit reached!
```

**时间重置时**:
```
🔄 Hourly usage reset at 15:00
📅 Daily usage reset on 2026-01-26
```

---

## 🛠️ 快速故障排除

### 问题 1：应用崩溃或无法打开

**解决步骤**:
1. 在 Xcode 中重新构建：`⌘ + B`
2. 重新安装到设备：`⌘ + R`
3. 检查 Xcode Console 中的错误信息

### 问题 2：权限请求不显示

**解决步骤**:
1. 检查 ZenBound.entitlements 中是否有 `com.apple.developer.family-controls`
2. 在 Settings > Privacy > Screen Time 中重置权限
3. 卸载应用后重新安装

### 问题 3：Shield 不显示

**解决步骤**:
1. 确保应用已激活
2. 确保已添加了使用时间（至少 15 分钟）
3. 检查 ShieldActionExtension 是否正确签名

### 问题 4：时间不重置

**解决步骤**:
1. 检查 DeviceActivity 监控是否真的启动（日志中 24/24）
2. 确认系统时间更改已被识别
3. 检查 Shared.swift 中的重置逻辑日志

### 问题 5：数据在重启后丢失

**解决步骤**:
1. 确保 UserDefaults 使用了 App Group（group.com.zenbound.data）
2. 检查 entertainmentConfig 的 getter/setter 实现
3. 在 Xcode 设置中验证 App Group 是否启用

---

## 📊 快速检查清单

在开始各场景前，检查这些:

- [ ] App 已安装在 EmilyiPhone
- [ ] iOS 版本是 26.2 或更高
- [ ] 有屏幕时间权限（或可以授予）
- [ ] Xcode 项目已成功构建（无崩溃错误）
- [ ] 能打开 Scenarios 菜单
- [ ] 有 Terminal 窗口运行日志监控命令

---

## 📈 测试进度追踪

完成每个场景后，更新此表:

| # | 场景 | 状态 | 问题数 | 备注 |
|---|------|------|--------|------|
| 1 | 权限检查 | ⬜ | - | |
| 2 | App 选择 | ⬜ | - | |
| 3 | 每小时限制 | ⬜ | - | |
| 4 | 每日限制 | ⬜ | - | |
| 5 | 激活配置 | ⬜ | - | |
| 6 | 使用模拟 | ⬜ | - | |
| 7 | Shield 显示 | ⬜ | - | |
| 8 | 时间重置 | ⬜ | - | |
| 9 | 数据持久化 | ⬜ | - | |

**图例**: ⬜ = 未开始, 🟨 = 进行中, ✅ = 通过, ❌ = 失败

---

## 💡 Pro Tips

1. **并行运行日志**: 在一个 Terminal 标签页运行日志，在另一个标签页运行 Xcode
2. **截图记录**: 对于每个失败的场景，截图并保存，用于后续调试
3. **逐个完成**: 不要跳过场景，按顺序测试可以更容易发现问题根源
4. **记录时间**: 每个场景记录开始和结束时间，用于性能分析
5. **保存数据**: 定期将结果保存到 TEST_RESULTS_RECORD.md

---

**所有文件位置**:
- 📝 详细测试计划：[ENTERTAINMENT_GROUP_TEST_PLAN.md](ENTERTAINMENT_GROUP_TEST_PLAN.md)
- 📊 优化报告：[ENTERTAINMENT_GROUP_OPTIMIZATION_REPORT.md](ENTERTAINMENT_GROUP_OPTIMIZATION_REPORT.md)
- 📋 结果记录：[TEST_RESULTS_RECORD.md](TEST_RESULTS_RECORD.md)
- 🎯 详细执行指南：[TEST_EXECUTION_GUIDE.md](TEST_EXECUTION_GUIDE.md)

**开始测试**: 现在在真机上打开 ZenBound → Scenarios → Entertainment Group Configuration！🚀

