# 娱乐组配置 - 快速参考指南

## 🎯 快速链接

| 项目 | 位置 |
|------|------|
| **主配置界面** | [ZenBound/DemoUI/Scenarios/EntertainmentGroupConfigView.swift](ZenBound/DemoUI/Scenarios/EntertainmentGroupConfigView.swift) |
| **数据模型** | [ZenBound/Models/Shared.swift](ZenBound/Models/Shared.swift#L179-L195) |
| **配置管理器** | [ZenBound/Utils/EntertainmentConfigManager.swift](ZenBound/Utils/EntertainmentConfigManager.swift) ⭐ 新 |
| **监控增强** | [ZenBound/Utils/EntertainmentMonitoringEnhancements.swift](ZenBound/Utils/EntertainmentMonitoringEnhancements.swift) ⭐ 新 |
| **设备活动工具** | [ZenBound/Utils/DeviceActivityCenterUtil.swift](ZenBound/Utils/DeviceActivityCenterUtil.swift) |
| **测试计划** | [ENTERTAINMENT_GROUP_TEST_PLAN.md](ENTERTAINMENT_GROUP_TEST_PLAN.md) |
| **优化报告** | [ENTERTAINMENT_GROUP_OPTIMIZATION_REPORT.md](ENTERTAINMENT_GROUP_OPTIMIZATION_REPORT.md) |

## 🚀 快速启动

### 1. 在模拟器上运行
```bash
# 打开Xcode并选择模拟器
open ZenBound.xcodeproj

# 或使用命令行
xcodebuild -scheme ZenBound -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData build
```

### 2. 在真机上安装
```bash
cd /Users/jianfengxia/work/foqos/ZenBound

# 构建
xcodebuild -scheme ZenBound -configuration Debug \
  -destination 'id=00008101-001D48321A00001E' \
  -derivedDataPath ./DerivedData build

# 安装
xcodebuild -scheme ZenBound -configuration Debug \
  -destination 'id=00008101-001D48321A00001E' \
  -derivedDataPath ./DerivedData install
```

### 3. 查看日志
```bash
# 实时日志流
log stream --predicate 'eventMessage contains[cd] "Entertainment"' --level debug

# 或查看所有调试日志
log stream --predicate 'process == "ZenBound"' --level debug
```

## 📖 核心概念

### 数据流
```
用户配置 (UI)
    ↓
EntertainmentConfigManager (验证 + 业务逻辑)
    ↓
SharedData.entertainmentConfig (持久化到 UserDefaults)
    ↓
App Group (跨进程共享)
    ↓
Widget/Extension (读取配置)
```

### 时间限制工作流
```
1. 用户激活配置
2. DeviceActivityCenter 启动24个监控任务（每小时一个）
3. 系统在后台跟踪应用使用时间
4. 达到每小时限制 → 触发 threshold event
5. Extension 收到事件 → 显示 Shield 屏蔽
6. 小时变化时自动重置计数器
7. 日期变化时自动重置每日计数器
```

## 🔧 常见任务

### 添加使用时间（模拟）
```swift
// 在EntertainmentGroupConfigView中
@State private var simulatedUsageMinutes: Int = 0

// 点击"Start Simulation"时
EntertainmentConfigManager.shared.addUsage(simulatedUsageMinutes)
```

### 检查是否达到限制
```swift
let remaining = EntertainmentConfigManager.shared.getRemainingHourlyTime()
if remaining <= 0 {
    // 显示强制休息UI
}
```

### 获取使用进度
```swift
let progress = EntertainmentConfigManager.shared.getHourlyProgressPercentage()
// progress: 0.0 到 1.0
// 用于显示进度条：progress * 100 = %
```

### 导出配置备份
```swift
if let json = EntertainmentConfigManager.shared.exportConfigJSON() {
    // 保存json到文件
    try? json.write(toFile: path, atomically: true, encoding: .utf8)
}
```

### 导入配置
```swift
if let json = try? String(contentsOfFile: path, encoding: .utf8) {
    let success = EntertainmentConfigManager.shared.importConfigFromJSON(json)
}
```

## 📊 关键指标

| 指标 | 值 |
|------|---|
| **配置数据大小** | ~500 bytes |
| **跨进程同步延迟** | <100ms (UserDefaults) |
| **监控任务数** | 24 (每小时一个) |
| **定时器检查间隔** | 60 秒 |
| **线程安全** | @MainActor + DispatchQueue |
| **通知类型** | 3 (configDidChange, usageDidUpdate, limitReached) |

## 🐛 调试技巧

### 1. 查看当前配置
```swift
if let config = SharedData.entertainmentConfig {
    print("Active: \(config.isActive)")
    print("Hour Usage: \(config.currentHourUsageMinutes)/\(config.hourlyLimitMinutes)")
    print("Daily Usage: \(config.todayTotalUsageMinutes)/\(config.dailyLimitMinutes)")
}
```

### 2. 检查监控状态
```swift
let activeHours = DeviceActivityCenterUtil.getActiveMonitoringHours()
print("Active monitoring hours: \(activeHours)")
DeviceActivityCenterUtil.debugLogMonitoringState()
```

### 3. 强制时间重置
```swift
EntertainmentConfigManager.shared.resetHourlyIfNeeded()
EntertainmentConfigManager.shared.resetDailyIfNeeded()
```

### 4. 监听通知
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(configDidChange),
    name: EntertainmentConfigManager.configDidChangeNotification,
    object: nil
)

@objc func configDidChange(_ notification: NSNotification) {
    if let config = notification.userInfo?["config"] as? SharedData.EntertainmentConfig {
        print("Config changed: \(config)")
    }
}
```

## ✅ 测试清单

进行手动测试时检查以下项目：

- [ ] **权限**: 应用能正确请求和检查屏幕时间权限
- [ ] **App选择**: 能从FamilyActivityPicker选择应用
- [ ] **配置激活**: 激活后能正常启动监控
- [ ] **时间计数**: 使用模拟器能准确累计使用时间
- [ ] **限制触发**: 达到限制时能显示Shield
- [ ] **时间重置**: 新小时/新日期时计数器能重置
- [ ] **数据持久**: 应用重启后配置能保留
- [ ] **Widget同步**: Widget能显示当前配置和使用情况
- [ ] **通知**: 配置变更时能收到通知
- [ ] **日志**: 日志能记录所有关键操作

## 🎓 学习资源

### 相关框架
- [DeviceActivity (Apple Docs)](https://developer.apple.com/documentation/deviceactivity)
- [FamilyControls (Apple Docs)](https://developer.apple.com/documentation/familycontrols)
- [ManagedSettings (Apple Docs)](https://developer.apple.com/documentation/managedsettings)

### 项目文档
- [Swift 项目结构](docs/swift_structure.md)
- [API 卡片 - FamilyActivitySelection](docs/study/07-api-cards/familyactivityselection.md)
- [API 卡片 - DeviceActivityName](docs/study/07-api-cards/deviceactivityname.md)

## 💡 最佳实践

1. **始终使用 @MainActor**
   - 所有 UI 和 UserDefaults 操作必须在主线程

2. **使用通知而不是轮询**
   - 配置变更时发送通知而不是定期检查

3. **验证配置**
   - 在激活前验证所有配置参数

4. **详细日志**
   - 添加清晰的日志便于调试和监控

5. **优雅降级**
   - 如果某小时监控失败，继续尝试其他小时

6. **缓存计算结果**
   - 避免每次都计算进度百分比

## 🚨 常见问题

### Q: 配置未保存
**A**: 检查是否正确调用了 `SharedData.entertainmentConfig = config`

### Q: Extension 未读取配置
**A**: 
1. 确保 App Group ID 一致
2. 检查 Extension 是否有 UserDefaults 访问权限
3. 可能需要强制杀死 Extension 进程

### Q: 监控未启动
**A**: 
1. 检查是否有屏幕时间权限
2. 验证 FamilyActivitySelection 包含至少一个应用
3. 查看日志中的错误信息

### Q: 时间未重置
**A**: 
1. 检查系统时间是否正确
2. 调用 `resetHourlyIfNeeded()` 和 `resetDailyIfNeeded()` 进行手动重置
3. 查看 `lastResetHour` 和 `lastResetDate` 值

## 📞 获取帮助

- 查看 [ENTERTAINMENT_GROUP_TEST_PLAN.md](ENTERTAINMENT_GROUP_TEST_PLAN.md) 获取详细测试步骤
- 查看 [ENTERTAINMENT_GROUP_OPTIMIZATION_REPORT.md](ENTERTAINMENT_GROUP_OPTIMIZATION_REPORT.md) 获取技术细节
- 检查日志输出中的错误信息
- 运行 `debugLogMonitoringState()` 获取当前状态

---

**最后更新**: 2026-01-26  
**版本**: 1.0  
**状态**: ✅ 在真机上已验证
