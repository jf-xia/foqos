# ScreenTime 授权实现指南

## 1. 核心摘要 (TL;DR)
实现一个 `ScreenTimeAuthorizer` 类，用于处理 Apple `FamilyControls` 框架的授权请求，范围限定为 **Individual**（当前设备）。这是任何需要通过 Screen Time API 阻止应用或追踪设备活动的 App 的基础步骤。必须在 Xcode 中开启 `Family Controls` 能力，并在应用生命周期早期调用。

## 2. 能力定义与非目标
### 能力契约
- **目标**：请求并维护 `FamilyControls` 框架的授权状态。
- **范围**：严格限定为 `.individual`（适用于在用户自己设备上运行的专注/效率类 App）。
- **输出**：向 UI 暴露响应式的 `isAuthorized` 布尔值和原始 `AuthorizationStatus`。
- **线程安全**：所有 UI 状态更新必须在 `MainActor` 上执行。

### 非目标
- **家长控制**：不实现 `.child` 授权或家庭共享逻辑。
- **远程管理**：不涉及 MDM 或服务端配置文件管理。
- **复杂错误恢复**：仅需基础错误日志；不需要实现复杂的“跳转到设置”引导逻辑。

## 3. 适用场景
### 场景 1：首次启动授权
- **用户行为**：用户首次打开 App 或点击“授予权限”按钮。
- **系统行为**：iOS 弹出系统级弹窗，询问“允许 [App] 管理此设备上的限制”。
- **App 行为**：用户批准后，`isAuthorized` 变为 `true`，解锁相关功能。

### 场景 2：恢复运行时检查状态
- **用户行为**：用户更改系统设置后返回 App。
- **App 行为**：App 检查 `AuthorizationCenter.shared.authorizationStatus` 以确保权限仍然有效。

## 4. 参考实现分析
基于 `RequestAuthorizer.swift` 及项目内使用情况：
- **模式**：`ObservableObject` (SwiftUI) 或 `@Observable` (Swift 5.9+)。
- **并发**：使用 `Task` 和 `await` 处理异步授权调用。
- **状态管理**：在 `MainActor` 上更新 `isAuthorized` 以避免 UI 故障。
- **依赖注入**：通常通过 `.environmentObject` 注入，以便所有视图（如设置页、引导页）都能访问。

## 5. 外部依赖与 API 清单
### 框架：`FamilyControls`
- **类**：`AuthorizationCenter`
- **单例**：`AuthorizationCenter.shared`
- **方法**：`requestAuthorization(for: MemberType)`
  - **参数**：`.individual`（对此用例至关重要）。
- **属性**：`authorizationStatus`（返回 `.notDetermined`, `.denied`, `.approved`）。

### Entitlements 授权文件（关键）
- **Key**: `com.apple.developer.family-controls`
- **Value**: `YES` (Boolean)
- **注意**：必须通过 Xcode "Signing & Capabilities" -> "+ Capability" -> "Family Controls" 添加。

## 6. 集成指南

### 前置条件
1.  **Xcode 项目**：确保 Target 已开启 **Family Controls** 能力。
2.  **Provisioning Profile**：必须支持 Family Controls（自动签名通常会自动处理）。

### 模块实现 (`ScreenTimeAuthorizer`)
创建一个负责授权生命周期的类。

```swift
import FamilyControls
import SwiftUI

class ScreenTimeAuthorizer: ObservableObject {
    @Published var isAuthorized: Bool = false

    // 请求当前设备所有者的权限
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run { self.isAuthorized = true }
            } catch {
                print("Authorization failed: \(error)")
                await MainActor.run { self.isAuthorized = false }
            }
        }
    }
}
```

### UI 集成
1.  **初始化**：在 App 根入口创建实例 (`@StateObject`)。
2.  **注入**：通过 `.environmentObject` 向下传递。
3.  **消费**：在视图中观察 `isAuthorized`，以决定显示/隐藏“授予权限”按钮。

## 7. 配置与扩展点
- **范围 (Scope)**：硬编码为 `.individual`。如果 App 后续转向家长控制方向，需将此参数改为可配置。
- **错误处理**：当前仅打印日志。可扩展为发布 `errorMessage` 字符串以供用户弹窗提示。

## 8. 边界情况与常见坑
- **模拟器支持**：Family Controls 在模拟器上经常失败或行为不一致。**务必在真机上验证。**
- **权限撤销**：用户可以在 iOS 设置 > 屏幕使用时间 中撤销权限。App 应在 `scenePhase` 变化（活跃/后台）时检查状态。
- **沙盒限制**：如果没有正确配置 Entitlement，API 调用将静默失败或崩溃。

## 9. 验收标准
- [ ] App 编译无报错。
- [ ] 点击授权触发点能弹出系统的 Screen Time 权限请求页。
- [ ] 同意权限后，UI 状态更新为“已授权”。
- [ ] 拒绝权限后，记录错误日志并保持 UI 为“未授权”状态。

## 10. 验证清单
- [ ] **Entitlement 检查**：确认 `foqos.entitlements`（或你的 App 授权文件）包含 `com.apple.developer.family-controls`。
- [ ] **真机测试**：在真实 iPhone/iPad 上运行（iOS 15+ 或 16+，视需求而定）。
- [ ] **系统设置确认**：确认 App 出现在 iOS 设置 > 屏幕使用时间 > 允许访问屏幕使用时间的 App 列表中。

## 11. 附录：检索与验证 Queries
- **Apple Docs**: `AuthorizationCenter requestAuthorization individual`
- **GitHub**: `path:*.entitlements com.apple.developer.family-controls`
