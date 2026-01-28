# 🚀 EmilyiPhone 娱乐组配置快速测试指南

**⏱️ 预计测试时间**: 10-15 分钟  
**📱 设备**: EmilyiPhone (iPhone 13, iOS 26.2)  
**✅ 应用状态**: 已安装并运行中 (PID: 1577)

---

## 快速测试命令行

应用已在以下位置部署：
```
Bundle ID: com.lxt.ZenBound
Installation: file:///private/var/containers/Bundle/Application/DD507050-0AF9-4E79-A0EF-AAFB94611095/ZenBound.app/
```

如需重新启动应用：
```bash
# 在 Mac 上执行（如果应用不响应）
xcrun devicectl device list
xcrun devicectl device copy-item --device 1F28CA54-127E-5FCB-9284-B3228E18982C \
  ~/path/to/app.app \
  /private/var/containers/Bundle/Application/
```

---

## 🎯 测试步骤总结

### 第 1 步: 打开应用主界面

**在 EmilyiPhone 屏幕上**:
1. 找到 ZenBound 应用（应该已打开）
2. 如果未打开，点击应用图标

**预期**: 看到 ZenBound 主界面

---

### 第 2 步: 导航到测试场景

**路径**:
```
ZenBound 主界面
    ↓
点击菜单 (☰) 或向下滚动
    ↓
选择 "Scenarios" 或 "Demo" 区域
    ↓
点击 "Entertainment Group Configuration"
```

**预期**: 进入娱乐组配置测试页面

---

### 第 3 步: 执行三个测试场景

#### 🔐 场景 1: 权限检查 (2 分钟)

```
看到的界面:
├── Step 1: Authorization Check
│   ├── 权限状态 (✅ Authorized 或 ❌ Not Authorized)
│   └── [Request Authorization] 按钮
│
操作:
1. 检查权限状态
   - 如果显示 ✅ Authorized → 跳到第 2 步
   - 如果显示 ❌ Not Authorized → 执行步骤 2
   
2. 点击 [Request Authorization] 按钮
   
3. 系统弹窗出现:
   "ZenBound" 想访问您的屏幕时间
   
4. 点击 [Allow]
   
5. 验证: 状态应该更新为 ✅ Authorized

验证成功标准:
✅ 权限状态显示为已授予
✅ 日志显示: "✅ Screen Time authorization successful"
✅ 可继续到下一步
```

---

#### 🎮 场景 2: App 选择 (3-4 分钟)

```
看到的界面:
├── Step 2: App Selection
│   ├── 显示已选应用数量 (如果有的话)
│   └── [Select Entertainment Apps] 按钮
│
操作:
1. 点击 [Select Entertainment Apps]
   
2. FamilyActivityPicker 弹出窗口显示:
   - 可用应用列表
   - 应用类别 (如果有)
   
3. 选择应用 (勾选 3-5 个):
   - Instagram ✓
   - TikTok ✓
   - YouTube ✓
   - Facebook ✓
   - WeChat/QQ ✓
   
4. 或选择类别:
   - Entertainment ✓
   - Social ✓
   
5. 点击 [Done]
   
6. 验证结果:
   - 返回配置页面
   - 显示已选应用数量
   - 日志显示选择信息

验证成功标准:
✅ FamilyActivityPicker 成功打开
✅ 能选择多个应用和类别
✅ 返回后正确显示选择摘要
✅ 日志显示: "✅ Entertainment apps selected: X apps, Y categories"
```

---

#### ⏰ 场景 3: 时间限制配置 (3-5 分钟)

```
看到的界面:
├── Step 3: Time Limits Configuration
│   ├── Hourly Limit Settings
│   │   ├── [10] [15] [20] [30] 分钟选择按钮
│   │   └── 时间分配图表
│   ├── Enable Hourly Limit 开关
│   ├── Daily Limit Settings
│   │   └── 每日限制滑块
│   ├── Enable on Weekends 开关
│   └── 其他设置
│
操作:
1. 在 Hourly Limit Settings 中:
   - 点击 [15 分钟] 按钮
   - 观察图表更新 (应显示可用时间与休息时间)
   
2. 在 "Enable Hourly Limit" 中:
   - 打开开关 (ON)
   - 观察 UI 变化
   - 关闭开关 (OFF)
   - 观察 UI 变化
   
3. 在 Daily Limit 中:
   - 调整滑块到 120 分钟左右
   - 观察值的更新
   
4. 在周末设置中:
   - 打开 "Enable on Weekends" 开关
   
5. 向下滚动查看日志:
   - 应该看到配置变更的日志
   
6. 验证:
   - 所有设置显示正确
   - 日志显示配置信息

验证成功标准:
✅ 时间选择器正常工作
✅ 图表随时长选择正确更新
✅ 所有开关正常工作
✅ 日志显示配置信息:
   - "✅ Hourly limit set to: 15 minutes"
   - "✅ Daily limit configured: 120 minutes"
   - "✅ Hourly limit monitoring enabled"
```

---

## 📝 填写测试结果

在手机上完成测试后，填写下表:

| 测试项 | 状态 | 问题描述 |
|--------|------|--------|
| 权限检查 - 权限请求 | [ ] PASS [ ] FAIL | _________________ |
| 权限检查 - 权限授予 | [ ] PASS [ ] FAIL | _________________ |
| App 选择 - 打开 Picker | [ ] PASS [ ] FAIL | _________________ |
| App 选择 - 选择应用 | [ ] PASS [ ] FAIL | _________________ |
| App 选择 - 结果显示 | [ ] PASS [ ] FAIL | _________________ |
| 时间限制 - 选择器工作 | [ ] PASS [ ] FAIL | _________________ |
| 时间限制 - 图表更新 | [ ] PASS [ ] FAIL | _________________ |
| 时间限制 - 开关工作 | [ ] PASS [ ] FAIL | _________________ |
| 时间限制 - 日志显示 | [ ] PASS [ ] FAIL | _________________ |

---

## 🔍 故障排除快速参考

### 应用未打开？
```
解决:
1. 尝试从 Spotlight 搜索: 向右滑动，输入 "ZenBound"
2. 或进入设置 > 屏幕时间，检查是否已启用
3. 重启手机
```

### 权限弹窗未出现？
```
解决:
1. 确保手机已解锁
2. 检查是否在后台运行其他系统任务
3. 尝试重新点击 "Request Authorization"
4. 进入 设置 > 屏幕时间，检查是否启用
```

### App Picker 无法打开？
```
解决:
1. 确保权限已授予
2. 重启应用
3. 检查 Family Sharing 是否已配置
```

### 看不到日志？
```
解决:
1. 向下滚动页面
2. 等待 1-2 秒
3. 检查页面底部是否有日志区域
```

---

## 📊 测试统计

- **总测试场景**: 3 个
- **总测试用例**: 9 个
- **预计所需时间**: 10-15 分钟
- **设备**: 1 个 (EmilyiPhone)
- **应用版本**: Debug Build
- **构建状态**: ✅ 成功

---

## ✅ 完成标志

所有测试完成时应该看到:
```
✅ 场景 1: 权限检查 - PASSED
✅ 场景 2: App 选择 - PASSED  
✅ 场景 3: 时间限制配置 - PASSED

总体结果: ✅ 所有测试通过
```

---

**开始时间**: 2026-01-26 22:16:30  
**应用状态**: 🟢 运行中  
**祝您测试顺利！** 🎉
