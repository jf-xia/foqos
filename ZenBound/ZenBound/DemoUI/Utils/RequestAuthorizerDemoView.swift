import SwiftUI

/// RequestAuthorizer Demo - 展示屏幕时间授权管理
struct RequestAuthorizerDemoView: View {
    @StateObject private var authorizer = RequestAuthorizer()
    @State private var logMessages: [LogMessage] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RequestAuthorizer 管理 FamilyControls 的授权状态。")
                        
                        Text("**授权状态 (AuthorizationStatus)：**")
                        BulletPointView(text: ".notDetermined - 未请求")
                        BulletPointView(text: ".denied - 已拒绝")
                        BulletPointView(text: ".approved - 已授权")
                        
                        Text("**核心方法：**")
                        BulletPointView(text: "requestAuthorization() - 请求授权")
                        BulletPointView(text: "checkAuthorizationStatus() - 检查状态")
                        BulletPointView(text: "revokeAuthorization() - 撤销授权")
                        
                        Text("**注意事项：**")
                        BulletPointView(text: "需要设备支持屏幕时间")
                        BulletPointView(text: "需要 Family Controls 权限")
                        BulletPointView(text: "首次请求会显示系统授权弹窗")
                    }
                }
                
                // MARK: - 当前状态
                DemoSectionView(title: "📊 授权状态", icon: "checkmark.shield") {
                    VStack(spacing: 16) {
                        // 状态显示
                        HStack {
                            Image(systemName: statusIcon)
                                .font(.title)
                                .foregroundColor(statusColor)
                            VStack(alignment: .leading) {
                                Text(statusText)
                                    .font(.headline)
                                Text(statusDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(12)
                        
                        // 刷新按钮
                        Button {
                            refreshStatus()
                        } label: {
                            Label("刷新状态", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            Task { await requestAuthorization() }
                        } label: {
                            Label("请求授权", systemImage: "lock.open")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(authorizer.authorizationStatus == .approved)
                        
                        Button {
                            Task { await revokeAuthorization() }
                        } label: {
                            Label("撤销授权", systemImage: "lock")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(authorizer.authorizationStatus != .approved)
                        .tint(.red)
                        
                        Button {
                            openScreenTimeSettings()
                        } label: {
                            Label("打开屏幕使用时间设置", systemImage: "gear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 授权流程图
                DemoSectionView(title: "📐 授权流程", icon: "arrow.triangle.branch") {
                    VStack(alignment: .leading, spacing: 8) {
                        FlowStepView(number: 1, text: "检查 AuthorizationCenter.shared.authorizationStatus")
                        FlowStepView(number: 2, text: "如果 .notDetermined → 显示请求按钮")
                        FlowStepView(number: 3, text: "调用 AuthorizationCenter.shared.requestAuthorization()")
                        FlowStepView(number: 4, text: "系统显示授权弹窗")
                        FlowStepView(number: 5, text: "用户选择 → 状态变为 .approved 或 .denied")
                        FlowStepView(number: 6, text: "如果 .approved → 可以使用屏幕时间 API")
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 首次启动授权",
                            description: "App 首次启动时检查并请求授权",
                            code: """
struct ContentView: View {
    @StateObject var authorizer = RequestAuthorizer()
    
    var body: some View {
        Group {
            switch authorizer.authorizationStatus {
            case .notDetermined:
                OnboardingAuthView()
            case .denied:
                AuthDeniedView()
            case .approved:
                MainAppView()
            @unknown default:
                EmptyView()
            }
        }
        .onAppear {
            authorizer.checkAuthorizationStatus()
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 授权状态监听",
                            description: "监听授权状态变化",
                            code: """
class RequestAuthorizer: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    init() {
        // 监听状态变化
        Task {
            for await status in AuthorizationCenter.shared.$authorizationStatus.values {
                await MainActor.run {
                    self.authorizationStatus = status
                }
            }
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 处理拒绝状态",
                            description: "引导用户到设置中开启权限",
                            code: """
struct AuthDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 60))
            Text("需要屏幕时间权限")
            Text("请在设置中开启屏幕使用时间")
                .font(.caption)
            Button("打开设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("RequestAuthorizer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
            refreshStatus()
        }
    }
    
    // MARK: - Computed Properties
    private var statusIcon: String {
        switch authorizer.authorizationStatus {
        case .notDetermined: return "questionmark.circle"
        case .denied: return "xmark.shield"
        case .approved: return "checkmark.shield.fill"
        @unknown default: return "questionmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch authorizer.authorizationStatus {
        case .notDetermined: return .gray
        case .denied: return .red
        case .approved: return .green
        @unknown default: return .gray
        }
    }
    
    private var statusText: String {
        switch authorizer.authorizationStatus {
        case .notDetermined: return "未请求授权"
        case .denied: return "授权被拒绝"
        case .approved: return "已授权"
        @unknown default: return "未知状态"
        }
    }
    
    private var statusDescription: String {
        switch authorizer.authorizationStatus {
        case .notDetermined: return "点击下方按钮请求屏幕时间授权"
        case .denied: return "请到设置中开启屏幕使用时间权限"
        case .approved: return "可以使用所有屏幕时间功能"
        @unknown default: return ""
        }
    }
    
    // MARK: - Actions
    private func refreshStatus() {
        authorizer.checkAuthorizationStatus()
        addLog("🔄 当前状态: \(statusText)", type: .info)
    }
    
    private func requestAuthorization() async {
        addLog("📤 请求授权...", type: .info)
        do {
            try await authorizer.requestAuthorization()
            addLog("✅ 授权成功", type: .success)
        } catch {
            addLog("❌ 授权失败: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func revokeAuthorization() async {
        addLog("🔒 撤销授权...", type: .warning)
        await authorizer.revokeAuthorization()
        addLog("✅ 已撤销", type: .success)
    }
    
    private func openScreenTimeSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
            addLog("⚙️ 打开系统设置", type: .info)
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 15 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct FlowStepView: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.caption)
        }
    }
}

#Preview {
    NavigationStack {
        RequestAuthorizerDemoView()
    }
}
