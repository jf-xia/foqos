# 娱乐组配置功能测试计划

**测试设备**: EmilyiPhone (iOS 26.2)  
**测试应用**: ZenBound  
**测试日期**: 2026-01-26  
**功能**: 娱乐组配置 (Entertainment Group Configuration)

---

## 🎯 测试目标

验证 ZenBound 应用中的娱乐组配置功能的完整性和稳定性，包括：
- 权限检查和授权流程
- App 选择功能
- 每小时/每日时间限制设置
- 激活和监控功能
- 数据持久化和跨进程通信

---

## 📋 核心数据结构

### EntertainmentConfig (数据模型)
位置: [ZenBound/Models/Shared.swift](ZenBound/Models/Shared.swift#L179-L195)

```swift
struct EntertainmentConfig: Codable, Equatable {
    var isActive: Bool = false
    var selectedActivity: FamilyActivitySelection
    var hourlyLimitMinutes: Int = 15              // 每小时限制（分钟）
    var dailyLimitMinutes: Int = 120              // 每日总限制（分钟）
    var restDurationMinutes: Int = 45             // 强制休息时长
    var enableHourlyLimit: Bool = true            // 启用每小时限制
    var currentHourUsageMinutes: Int = 0          // 当前小时已用时间
    var lastResetHour: Int = -1                   // 上次重置的小时
    var todayTotalUsageMinutes: Int = 0           // 今日总使用时间
    var lastResetDate: Date?                      // 上次重置日期
    var shieldMessage: String = "Enjoy your time!"
    var enableWeekends: Bool = true               // 周末生效
}
```

### 存储位置
- **App Group Suite**: `group.com.zenbound.data`
- **Key**: `entertainmentConfig`

---

## 🧪 测试场景

### 测试场景 1: 权限检查
**预期结果**: 应用能正确检查并请求屏幕时间权限

- [ ] 初始化时检查权限状态
- [ ] 权限未授予时显示请求界面
- [ ] 权限授予后能够正常配置
- [ ] 权限被拒绝时提示用户在设置中开启

**验证方法**:
1. 打开 ZenBound 应用
2. 导航到 "Scenarios" → "Entertainment Group Configuration"
3. 观察权限检查日志信息
4. 如未授权，点击 "Request Authorization" 按钮
5. 在系统弹窗中选择 "Allow" 或 "Don't Allow"

---

### 测试场景 2: App 选择
**预期结果**: 能够正确选择和显示指定的 App 和类别

- [ ] FamilyActivityPicker 正常打开
- [ ] 能够选择多个 App
- [ ] 能够选择 App 类别（Games, Social, Entertainment）
- [ ] 选择的 App 能正确保存

**验证方法**:
1. 在权限检查后进入 App 选择步骤
2. 点击 "Select Entertainment Apps" 按钮
3. 在弹出的 App Picker 中选择 App（如 TikTok, Instagram, etc.）
4. 选择类别（勾选 Entertainment, Social 等）
5. 确认选择并返回

---

### 测试场景 3: 每小时限制配置
**预期结果**: 时间限制设置正确，并能在运行时正确重置

**时间配置测试**:
- [ ] 每小时可用时长选择器工作正常（10/15/20/30 分钟）
- [ ] 休息时长随之调整（60 - 可用时长）
- [ ] 每小时计时器正确工作

**验证方法**:
1. 进入 "Hourly Limit Settings" 部分
2. 选择不同的每小时时长（例如 15 分钟）
3. 观察可视化时间分配图表
4. 切换 "Enable Hourly Limit" 开关
5. 在日志中验证设置变更记录

---

### 测试场景 4: 每日限制配置
**预期结果**: 每日总时长限制正确配置和显示

- [ ] 每日时长限制选择（60/90/120/180/240/300 分钟）
- [ ] 可用次数计算正确 (每日配额 ÷ 单次限制)
- [ ] 每日配额在日期变更时重置

**验证方法**:
1. 进入 "Daily Time Limit Settings" 部分
2. 调整 "Daily Total Time Limit" (例如 120 分钟)
3. 调整 "Single Session Time Limit" (例如 30 分钟)
4. 观察右侧信息卡片显示的可用次数 (120÷30 = 4次)

---

### 测试场景 5: 延长使用功能
**预期结果**: 允许用户在达到限制后延长使用时间

- [ ] 延长使用开关能正常工作
- [ ] 延长次数限制（1/2/3/5 次/天）正确配置
- [ ] 每次延长时间选择（5/10/15/20/30 分钟）
- [ ] 每日最多额外获得的时间计算正确

**验证方法**:
1. 进入 "Extension Settings" 部分
2. 启用 "Allow Extension Usage" 开关
3. 设置 "Extension Count Limit" 为 2 次/天
4. 设置 "Time Per Extension" 为 10 分钟
5. 验证摘要信息: "每天最多可额外获得 20 分钟"

---

### 测试场景 6: 强制休息设置
**预期结果**: 在达到单次限制时强制休息

- [ ] 强制休息开关工作正常
- [ ] 休息时长配置（30/45/50/55 分钟）
- [ ] 休息时屏蔽所有 App 的选项
- [ ] 休息提醒消息选择

**验证方法**:
1. 进入 "Rest Enforcement Settings" 部分
2. 启用 "Force Rest After Single Session" 开关
3. 选择休息时长（例如 45 分钟）
4. 可选: 启用 "Block All Apps During Rest"
5. 选择休息提醒消息

---

### 测试场景 7: 活动任务设置
**预期结果**: 用户可通过完成活动任务获得额外娱乐时间

- [ ] 活动任务开关工作正常
- [ ] 任务列表显示可用任务
- [ ] 每个任务的奖励时间配置（5/10/15/20 分钟）
- [ ] 总奖励时间计算正确

**验证方法**:
1. 进入 "Activity Tasks" 部分
2. 启用 "Enable Activity Tasks" 开关
3. 在任务选择中勾选任务（例如 3 个任务）
4. 设置 "Reward Time Per Task" 为 10 分钟
5. 验证摘要: "完成 3 个任务可获得 30 分钟额外时间"

---

### 测试场景 8: 激活和监控
**预期结果**: 配置能够正确激活并进行实时监控

**激活测试**:
- [ ] 点击 "Activate Configuration" 按钮能正确激活配置
- [ ] 激活后显示 "Configuration Active" 状态
- [ ] 配置信息正确保存到 SharedData
- [ ] 日志显示激活成功

**监控测试**:
- [ ] 可以启动使用模拟器
- [ ] 添加虚拟使用时长观察时间累计
- [ ] 定时器正确倒数
- [ ] 达到限制时能正确显示通知

**验证方法**:
1. 完成配置后进入 "Activation & Testing" 部分
2. 点击 "Activate" 按钮
3. 观察日志输出: "✅ Entertainment configuration activated"
4. 点击 "Start Usage Simulation" 进行测试
5. 选择模拟使用时长，观察累计情况

---

### 测试场景 9: 数据持久化
**预期结果**: 配置数据能正确保存和恢复

- [ ] 配置激活后能正确保存到 SharedData
- [ ] 应用重启后配置数据保持
- [ ] 跨进程间数据同步（Widget 能读取主 App 配置）
- [ ] 每小时和每日使用时间能正确持久化和重置

**验证方法**:
1. 配置并激活娱乐组设置
2. 进入 Settings 并完全杀死应用
3. 重新打开应用，导航回配置页面
4. 验证配置是否被保留
5. 检查 Widget 是否显示正确的配置信息

---

### 测试场景 10: 时间重置逻辑
**预期结果**: 每小时和每日时间计数器能正确重置

**每小时重置**:
- [ ] 在新的小时开始时自动重置本小时使用时间
- [ ] 记录最后重置的小时值

**每日重置**:
- [ ] 在新的一天开始时自动重置每日使用时间
- [ ] 记录最后重置的日期

**验证方法**:
1. 激活配置后检查 `lastResetHour` 和 `lastResetDate` 值
2. 系统时间更改（设置）模拟跨小时
3. 触发时间检查，验证是否重置
4. 检查日志中的重置记录

---

### 测试场景 11: Shield 集成
**预期结果**: 达到时间限制时能正确显示 Shield

- [ ] 达到每小时限制时显示 Shield
- [ ] Shield 显示自定义消息
- [ ] Shield 按钮能延长使用时间
- [ ] Shield 颜色和样式配置正确

**验证方法**:
1. 配置时间限制为较短时间（如 1 分钟）
2. 激活配置
3. 打开被屏蔽的 App
4. 观察 Shield 显示
5. 测试延长按钮功能

---

### 测试场景 12: 周末功能
**预期结果**: 支持周末配置生效切换

- [ ] 周末生效开关工作正常
- [ ] 系统能正确识别当前日期是否为周末
- [ ] 周末时能正确应用或不应用限制

**验证方法**:
1. 启用 "Weekend Effect" 开关
2. 更改系统日期到周末
3. 验证配置是否生效
4. 更改系统日期到工作日
5. 验证限制是否改变

---

## 🐛 已知问题和优化点

### 1. **使用时间计数精度**
- **问题**: 当前 `currentHourUsageMinutes` 是整数，可能无法精确追踪秒级使用时间
- **优化建议**: 
  - 使用 `TimeInterval` 替代整数分钟
  - 在 UI 中显示分:秒格式

### 2. **时间重置逻辑**
- **问题**: `lastResetHour` 和 `lastResetDate` 在应用冷启动时可能不准确
- **优化建议**:
  - 在应用启动时调用 `resetEntertainmentHourlyUsage()` 和 `resetEntertainmentDailyUsage()`
  - 添加后台任务定期检查时间重置

### 3. **并发问题**
- **问题**: `updateEntertainmentUsage()` 不是线程安全的
- **优化建议**:
  - 添加 `@MainActor` 标注或使用 `DispatchQueue`
  - 或使用原子操作保证数据一致性

### 4. **Extension 通信延迟**
- **问题**: 主 App 更新配置到 SharedData 后，Extension 可能有延迟
- **优化建议**:
  - 使用 `NotificationCenter.default` 发送更新通知
  - 考虑使用 `NSFileCoordinator` 进行更可靠的跨进程通信

### 5. **Shield 配置文案稳定性**
- **问题**: 当前通过日期 seed 生成文案，同一天同一 title 应该相同，但可能出现不一致
- **优化建议**:
  - 存储已生成的文案到 SharedData，确保一致性

---

## 📊 测试结果记录

| 测试场景 | 预期结果 | 实际结果 | 状态 | 备注 |
|---------|---------|---------|------|------|
| 1. 权限检查 | ✅ 正常工作 | | | |
| 2. App 选择 | ✅ 正常工作 | | | |
| 3. 每小时限制 | ✅ 正常工作 | | | |
| 4. 每日限制 | ✅ 正常工作 | | | |
| 5. 延长使用 | ✅ 正常工作 | | | |
| 6. 强制休息 | ✅ 正常工作 | | | |
| 7. 活动任务 | ✅ 正常工作 | | | |
| 8. 激活监控 | ✅ 正常工作 | | | |
| 9. 数据持久化 | ✅ 正常工作 | | | |
| 10. 时间重置 | ✅ 正常工作 | | | |
| 11. Shield 集成 | ✅ 正常工作 | | | |
| 12. 周末功能 | ✅ 正常工作 | | | |

---

## 🔧 优化代码清单

### 高优先级 (需要立即修复)
1. [ ] 添加线程安全保护到 `updateEntertainmentUsage()`
2. [ ] 应用启动时调用时间重置函数
3. [ ] 添加错误处理到 JSON 编解码操作

### 中优先级 (建议改进)
4. [ ] 将使用时间从分钟改为 `TimeInterval` 支持秒级精度
5. [ ] 添加 `NotificationCenter` 跨进程更新通知
6. [ ] 优化 Shield 文案生成和存储

### 低优先级 (未来优化)
7. [ ] 添加更详细的日志记录和分析
8. [ ] 支持自定义休息消息
9. [ ] 添加使用时间分析报告

---

## 📝 执行命令

```bash
# 在真机上构建
cd /Users/jianfengxia/work/foqos/ZenBound
xcodebuild -scheme ZenBound -configuration Debug \
  -destination 'id=00008101-001D48321A00001E' \
  -derivedDataPath ./DerivedData install

# 查看应用日志
log stream --predicate 'eventMessage contains[cd] "Entertainment"' --level debug
```

