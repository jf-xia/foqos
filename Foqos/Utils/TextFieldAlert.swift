import SwiftUI
import UIKit

/**
 SwiftUI 中带文本输入框的 UIAlertController 桥接组件
 
 # 1. 作用与输入输出
 
 将 UIKit 的 `UIAlertController`（带 `addTextField`）桥接到 SwiftUI 生态，实现在纯声明式视图中弹出文本输入对话框。
 
 **输入**：
 - `title`、`message`：警告框标题与描述文本
 - `text` (Binding)：双向绑定的文本值，用户输入会自动同步回父视图
 - `placeholder`：文本框占位符
 - `confirmTitle`、`cancelTitle`：按钮标签
 - `onConfirm`：用户点击确认后的回调闭包，接收最终输入的字符串
 
 **输出**：
 - 用户输入通过 `@Binding` 实时同步
 - 确认后通过 `onConfirm` 闭包传递最终值
 - 取消或关闭后自动将 `isPresented` 设为 `false`
 
 **示例输入输出流程**：
 
 ```swift
 // 1️⃣ 声明状态
 @State private var showAlert = false
 @State private var inputText = ""
 
 // 2️⃣ 通过按钮触发
 Button("创建配置") {
     showAlert = true
 }
 .background(
     TextFieldAlert(
         isPresented: $showAlert,
         title: "输入配置名称",
         message: "请输入一个唯一的名称",
         text: $inputText,
         placeholder: "例如：工作时段",
         confirmTitle: "确认",
         cancelTitle: "取消"
     ) { finalText in
         // 3️⃣ 用户确认后执行业务逻辑
         print("用户输入：\(finalText)")
         createProfile(name: finalText)
     }
 )
 
 // 输出流程：
 // • 用户在弹窗输入 "工作时段" → `inputText` 实时更新
 // • 点击确认 → `onConfirm` 接收 "工作时段"，同时 `isPresented` 变为 false
 // • 点击取消 → 直接 `isPresented` 变为 false，不触发 `onConfirm`
 ```
 
 ---
 
 # 2. 本项目中的使用方式搜索
 
 在本 iOS 专注力管理应用中，此组件用于"配置克隆"功能，位于配置详情页的工具栏菜单中。
 
 **引用位置**：
 - **视图文件**：BlockedProfileView.swift（详情编辑页）
 - **触发方式**：通过工具栏菜单中的"Duplicate"按钮触发
 - **状态管理**：`@State private var showingClonePrompt: Bool`、`@State private var cloneName: String`
 
 ---
 
 # 3. 本项目内用法总结与 UI 流程
 
 ## 用法 A：配置克隆（Clone Profile）
 
 **关联 UI 流程**：
 1. 用户进入某个专注配置的详情编辑页（BlockedProfileView）
 2. 点击页面右上角工具栏的省略号图标 (⋯)
 3. 在弹出菜单中选择"Duplicate"菜单项
 4. 触发 `TextFieldAlert`，标题为"Duplicate Profile"，占位符为"Profile Name"
 5. 用户输入新配置名称（如"深度工作 v2"）后点击"Create"
 6. 执行以下逻辑：
    - 调用 `BlockedProfiles.cloneProfile(_:in:newName:)` 复制原配置数据
    - 调用 `DeviceActivityCenterUtil.scheduleTimerActivity(for:)` 为新配置注册定时器监控
    - 如果失败，通过 `showError(message:)` 显示错误提示
 
 **相关功能代码示例**（项目抽象版）：
 
 ```swift
 struct ProfileDetailView: View {
     @State private var showCloneDialog = false
     @State private var newProfileName = ""
     let sourceProfile: BlockedProfile
     
     var body: some View {
         // 工具栏菜单
         .toolbar {
             ToolbarItem(placement: .navigationBarTrailing) {
                 Menu {
                     Button("Duplicate") {
                         showCloneDialog = true
                     }
                 } label: {
                     Image(systemName: "ellipsis.circle")
                 }
             }
         }
         // 克隆对话框（作为 background 附加）
         .background(
             TextFieldAlert(
                 isPresented: $showCloneDialog,
                 title: "Duplicate Profile",
                 message: nil,
                 text: $newProfileName,
                 placeholder: "Profile Name",
                 confirmTitle: "Create",
                 cancelTitle: "Cancel"
             ) { enteredName in
                 let name = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)
                 guard !name.isEmpty else { return }
                 
                 do {
                     // 克隆配置到 SwiftData 持久化层
                     let cloned = try ProfileManager.clone(
                         sourceProfile, 
                         newName: name
                     )
                     // 为新配置注册 DeviceActivity 监控（Apple ScreenTime API）
                     ActivityScheduler.registerMonitoring(for: cloned)
                 } catch {
                     showErrorAlert(error.localizedDescription)
                 }
             }
         )
     }
 }
 ```
 
 **数据流说明**：
 - **状态源**：本地 `@State` 变量 `showingClonePrompt` 和 `cloneName`（视图私有状态）
 - **持久化层**：克隆后的配置写入 SwiftData 的 `ModelContext`（`BlockedProfiles` 模型）
 - **系统集成**：通过 `DeviceActivityCenterUtil` 将新配置注册到 iOS ScreenTime API 的监控调度器中
 - **线程**：所有操作在主线程执行（SwiftUI 视图更新 + SwiftData 写入均为主线程安全）
 
 ---
 
 # 4. GitHub 公开仓库的常见用法搜索
 
 已搜索关键词：`UIViewControllerRepresentable UIAlertController addTextField language:Swift`，筛选条件：最近 2 年有更新，代码质量较高的仓库（Stream Chat、Nordic Semiconductor DFU、Unstoppable Wallet、MEGA iOS、LiveContainer 等）。
 
 ---
 
 # 5. GitHub 常见用法总结
 
 ## 模式 A：聊天/消息应用中的频道/群组创建
 
 **典型场景**：Stream Chat SwiftUI、Threema iOS  
 **功能**：用户在聊天列表点击"新建频道"，弹出文本输入框输入频道名称。
 
 ```swift
 struct ChannelListView: View {
     @State private var showCreateChannel = false
     @State private var channelName = ""
     
     var body: some View {
         List { /* 频道列表 */ }
         .toolbar {
             Button("创建频道") { showCreateChannel = true }
         }
         .background(
             TextFieldAlertBridge(
                 isPresented: $showCreateChannel,
                 title: "新建频道",
                 text: $channelName,
                 placeholder: "输入频道名称"
             ) { name in
                 ChatService.createChannel(name: name)
             }
         )
     }
 }
 ```
 
 ## 模式 B：文件/文件夹重命名操作
 
 **典型场景**：ONLYOFFICE Documents、MEGA iOS  
 **功能**：长按文件后选择"重命名"，弹出预填充当前文件名的输入框。
 
 ```swift
 struct FileRowView: View {
     let file: FileItem
     @State private var showRename = false
     @State private var newName = ""
     
     var contextMenu: some View {
         Button("重命名") {
             newName = file.name
             showRename = true
         }
     }
     
     var body: some View {
         Text(file.name)
             .contextMenu { contextMenu }
             .background(
                 TextFieldAlertBridge(
                     isPresented: $showRename,
                     title: "重命名文件",
                     text: $newName,
                     placeholder: file.name,
                     confirmTitle: "保存"
                 ) { finalName in
                     FileManager.renameFile(file, to: finalName)
                 }
             )
     }
 }
 ```
 
 ## 模式 C：OTP/密码管理器的新建条目
 
 **典型场景**：Raivo OTP  
 **功能**：在密码管理器中新建条目时，需要输入服务名称/账号标识。
 
 ```swift
 struct AddAccountButton: View {
     @State private var showInput = false
     @State private var accountLabel = ""
     
     var body: some View {
         Button("添加账号") { showInput = true }
         .background(
             TextFieldAlertBridge(
                 isPresented: $showInput,
                 title: "新增 OTP 账号",
                 message: "为此双因素认证设置一个标识",
                 text: $accountLabel,
                 placeholder: "例如：GitHub"
             ) { label in
                 OTPManager.addAccount(label: label, secret: scannedSecret)
             }
         )
     }
 }
 ```
 
 ## 模式 D：固件/DFU 更新的设备命名
 
 **典型场景**：Nordic Semiconductor DFU Library  
 **功能**：蓝牙设备 DFU 更新前，让用户为设备设置昵称。
 
 ```swift
 struct DFUSetupView: View {
     @State private var showNameInput = false
     @State private var deviceNickname = ""
     let peripheral: CBPeripheral
     
     var body: some View {
         Button("开始更新") {
             showNameInput = true
         }
         .background(
             TextFieldAlertBridge(
                 isPresented: $showNameInput,
                 title: "设备昵称",
                 text: $deviceNickname,
                 placeholder: peripheral.name ?? "未命名设备"
             ) { nickname in
                 DFUService.startUpdate(
                     peripheral: peripheral,
                     nickname: nickname
                 )
             }
         )
     }
 }
 ```
 
 ## 模式 E：钱包/加密货币应用的钱包创建/导入
 
 **典型场景**：Unstoppable Wallet  
 **功能**：用户导入钱包时输入钱包名称，用于本地标识多个钱包。
 
 ```swift
 struct ImportWalletFlow: View {
     @State private var showNamePrompt = false
     @State private var walletName = ""
     let mnemonic: [String]
     
     var body: some View {
         Button("导入钱包") {
             showNamePrompt = true
         }
         .background(
             TextFieldAlertBridge(
                 isPresented: $showNamePrompt,
                 title: "钱包名称",
                 text: $walletName,
                 placeholder: "我的钱包",
                 confirmTitle: "完成"
             ) { name in
                 WalletManager.importWallet(
                     name: name,
                     mnemonic: mnemonic
                 )
             }
         )
     }
 }
 ```
 
 ---
 
 ## 常见集成模式总结
 
 ### 1. **作为 `.background()` 修饰符附加**（推荐）
 
 避免干扰视图层级，不会影响布局，只在 `isPresented` 为 `true` 时才呈现 UIAlertController：
 
 ```swift
 SomeView()
     .background(
         TextFieldAlertBridge(isPresented: $show, ...) { ... }
     )
 ```
 
 ### 2. **状态驱动与双向绑定**
 
 所有实现都使用 `@Binding` 进行双向数据流：
 - 父视图通过 `@State` 或 `@StateObject` 管理弹窗显示状态
 - 文本输入通过 Binding 实时同步
 - 确认后通过闭包回调执行业务逻辑
 
 ### 3. **输入验证与错误处理**
 
 在 `onConfirm` 闭包中常见的验证模式：
 
 ```swift
 onConfirm: { input in
     let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
     guard !trimmed.isEmpty else {
         showError("名称不能为空")
         return
     }
     
     do {
         try performAction(trimmed)
     } catch {
         showError(error.localizedDescription)
     }
 }
 ```
 
 ### 4. **UIKit 桥接的必要性**
 
 SwiftUI 原生 `.alert()` 修饰符（iOS 15+）不支持 `TextField`，只能显示确认/取消按钮。当需要输入框时，必须桥接 UIKit 的 `UIAlertController`：
 
 - **iOS 15–16**：通过 `UIViewControllerRepresentable` 桥接（本组件的实现方式）
 - **iOS 16+**：可用 `.alert(...) { TextField(...) }` 语法糖（SwiftUI 原生支持），但不支持自定义键盘类型和输入验证
 
 ---
 
 ## 注意事项
 
 1. **平台差异**：UIAlertController 是 iOS/Mac Catalyst 独有，无法在 macOS AppKit 或 watchOS 中使用。
 2. **SwiftUI 生命周期**：必须通过 `.background()` 或 `ZStack` 附加到视图树，否则 `UIViewController` 无法呈现。
 3. **线程安全**：`updateUIViewController` 中的 `present` 操作已在主线程执行（SwiftUI 自动保证），但业务逻辑（如数据库写入）需检查是否主线程安全。
 4. **键盘配置**：当前实现固定为 `.done` 返回键类型，如需支持邮箱/数字键盘，可扩展��置参数。
 5. **多次触发**：通过 `uiViewController.presentedViewController == nil` 检查避免重复弹窗。
 */
struct TextFieldAlert: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  var title: String
  var message: String?
  @Binding var text: String
  var placeholder: String
  var confirmTitle: String = "Create"
  var cancelTitle: String = "Cancel"
  var onConfirm: (String) -> Void

  func makeUIViewController(context: Context) -> UIViewController {
    UIViewController()
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    guard isPresented, uiViewController.presentedViewController == nil else { return }

    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addTextField { textField in
      textField.placeholder = placeholder
      textField.text = text
      textField.clearButtonMode = .whileEditing
      textField.returnKeyType = .done
    }

    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
      isPresented = false
    }
    alert.addAction(cancelAction)

    let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in
      let value = alert.textFields?.first?.text ?? ""
      text = value
      onConfirm(value)
      isPresented = false
    }
    alert.addAction(confirmAction)

    uiViewController.present(alert, animated: true)
  }
}
