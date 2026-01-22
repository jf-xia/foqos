import SwiftUI
import SwiftData
import FamilyControls

/// StrategyManager Demo - 展示会话管理核心
struct StrategyManagerDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedProfile: BlockedProfiles?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("StrategyManager 是 ZenBound 的核心会话协调器。")
                        
                        Text("**核心职责：**")
                        BulletPointView(text: "管理配置状态 (激活/暂停)")
                        BulletPointView(text: "协调阻断策略执行")
                        BulletPointView(text: "管理会话生命周期")
                        BulletPointView(text: "处理休息时间")
                        BulletPointView(text: "同步共享数据")
                        
                        Text("**状态管理：**")
                        BulletPointView(text: "@Published state: StrategyState")
                        BulletPointView(text: ".idle → .running → .paused → .completed")
                        
                        Text("**依赖项：**")
                        BulletPointView(text: "BlockedProfiles - 配置数据")
                        BulletPointView(text: "BlockingStrategy - 阻断策略")
                        BulletPointView(text: "AppBlockerUtil - 实际阻断")
                        BulletPointView(text: "DeviceActivityCenterUtil - 计时器")
                    }
                }
                
                // MARK: - 状态机
                DemoSectionView(title: "🔄 状态机", icon: "arrow.triangle.2.circlepath") {
                    VStack(spacing: 12) {
                        StateFlowView()
                        
                        Text("状态转换说明")
                            .font(.caption.bold())
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• idle → running: startSession()")
                                .font(.caption)
                            Text("• running → paused: startBreak()")
                                .font(.caption)
                            Text("• paused → running: endBreak()")
                                .font(.caption)
                            Text("• running → completed: stopSession()")
                                .font(.caption)
                            Text("• any → idle: reset()")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - 选择配置
                DemoSectionView(title: "📋 选择配置", icon: "person.crop.rectangle.stack") {
                    if profiles.isEmpty {
                        VStack {
                            Text("请先在 BlockedProfiles Demo 中创建配置")
                                .foregroundStyle(.secondary)
                            NavigationLink("前往创建") {
                                BlockedProfilesDemoView()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(profiles) { profile in
                            Button {
                                selectedProfile = profile
                                addLog("📋 选中: \(profile.name)", type: .info)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(profile.name)
                                            .foregroundColor(.primary)
                                        Text(profile.blockingStrategyId ?? "未知策略")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedProfile?.id == profile.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        HStack {
                            Button {
                                simulateStartSession()
                            } label: {
                                Label("启动会话", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedProfile == nil)
                            
                            Button {
                                simulateStopSession()
                            } label: {
                                Label("停止会话", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        
                        HStack {
                            Button {
                                simulateStartBreak()
                            } label: {
                                Label("开始休息", systemImage: "cup.and.saucer")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                simulateEndBreak()
                            } label: {
                                Label("结束休息", systemImage: "play.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Divider()
                        
                        Button {
                            simulateFullLifecycle()
                        } label: {
                            Label("模拟完整生命周期", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 启动专注会话",
                            description: "使用 StrategyManager 启动完整会话",
                            code: """
struct FocusView: View {
    @EnvironmentObject var strategyManager: StrategyManager
    @State var profile: BlockedProfiles
    
    func startFocusSession() {
        // 1. 创建会话
        let session = profile.createNewSession()
        
        // 2. 启动策略管理器
        strategyManager.startSession(
            profile: profile,
            session: session
        )
        
        // 内部会：
        // - 激活 AppBlockerUtil
        // - 启动 DeviceActivityCenter 计时器
        // - 更新 SharedData
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 处理策略验证",
                            description: "不同策略的解锁验证流程",
                            code: """
// 策略验证入口
func validateAndUnlock(with data: Any) async -> Bool {
    guard let strategy = currentStrategy else { return false }
    
    switch strategy {
    case is ManualBlockingStrategy:
        // 手动模式：直接解锁
        return true
        
    case let nfcStrategy as NFCBlockingStrategy:
        // NFC: 验证标签
        return nfcStrategy.validateTag(data as? NFCNDEFTag)
        
    case let qrStrategy as QRCodeBlockingStrategy:
        // QR: 验证二维码
        return qrStrategy.validateCode(data as? String)
        
    default:
        return false
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 共享数据同步",
                            description: "Widget/Extension 数据同步",
                            code: """
private func syncSharedData() {
    guard let profile = currentProfile,
          let session = currentSession else { return }
    
    // 生成快照
    let profileSnapshot = profile.toSnapshot()
    let sessionSnapshot = session.toSnapshot()
    
    // 保存到 App Group
    SharedData.activeProfileSnapshot.save(profileSnapshot)
    SharedData.activeSessionSnapshot.save(sessionSnapshot)
    
    // Widget/Extension 可以读取
    // WidgetCenter.shared.reloadAllTimelines()
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("StrategyManager")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载 (StrategyManager 是核心协调器)", type: .info)
            addLog("⚠️ 此页面模拟演示，不执行真实操作", type: .warning)
        }
    }
    
    // MARK: - Simulation Actions
    private func simulateStartSession() {
        guard let profile = selectedProfile else { return }
        
        addLog("▶️ 启动会话: \(profile.name)", type: .info)
        addLog("   1. 验证策略: \(profile.blockingStrategyId ?? "未知")", type: .info)
        addLog("   2. 创建 Session 对象", type: .info)
        addLog("   3. 激活 AppBlockerUtil.activateRestrictions()", type: .info)
        addLog("   4. 启动 DeviceActivityCenter 计时器", type: .info)
        addLog("   5. 同步 SharedData", type: .info)
        addLog("   6. 状态: idle → running", type: .success)
    }
    
    private func simulateStopSession() {
        addLog("⏹️ 停止会话", type: .warning)
        addLog("   1. 停止 DeviceActivityCenter 计时器", type: .info)
        addLog("   2. 停用 AppBlockerUtil.deactivateRestrictions()", type: .info)
        addLog("   3. 保存会话数据", type: .info)
        addLog("   4. 清除 SharedData", type: .info)
        addLog("   5. 状态: running → completed", type: .success)
    }
    
    private func simulateStartBreak() {
        addLog("☕ 开始休息", type: .info)
        addLog("   1. 暂停阻断: deactivateRestrictions()", type: .info)
        addLog("   2. 启动休息计时器", type: .info)
        addLog("   3. 记录休息开始时间", type: .info)
        addLog("   4. 状态: running → paused", type: .success)
    }
    
    private func simulateEndBreak() {
        addLog("▶️ 结束休息", type: .info)
        addLog("   1. 停止休息计时器", type: .info)
        addLog("   2. 恢复阻断: activateRestrictions()", type: .info)
        addLog("   3. 记录休息时长", type: .info)
        addLog("   4. 状态: paused → running", type: .success)
    }
    
    private func simulateFullLifecycle() {
        addLog("🔄 模拟完整生命周期:", type: .info)
        
        // 模拟延迟效果
        addLog("", type: .info)
        addLog("T+0s  | 状态: idle", type: .info)
        addLog("T+0s  | → startSession()", type: .success)
        addLog("T+0s  | 状态: running", type: .info)
        addLog("", type: .info)
        addLog("T+25m | → startBreak()", type: .warning)
        addLog("T+25m | 状态: paused", type: .info)
        addLog("", type: .info)
        addLog("T+30m | → endBreak()", type: .success)
        addLog("T+30m | 状态: running", type: .info)
        addLog("", type: .info)
        addLog("T+55m | → stopSession()", type: .warning)
        addLog("T+55m | 状态: completed", type: .info)
        addLog("", type: .info)
        addLog("总时长: 55分钟 (含5分钟休息)", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 30 {
            logMessages.removeLast()
        }
    }
}

// MARK: - State Flow View
struct StateFlowView: View {
    var body: some View {
        HStack(spacing: 8) {
            StateNodeView(name: "idle", color: .gray)
            Image(systemName: "arrow.right")
                .font(.caption)
            StateNodeView(name: "running", color: .green)
            Image(systemName: "arrow.right")
                .font(.caption)
            StateNodeView(name: "paused", color: .orange)
            Image(systemName: "arrow.right")
                .font(.caption)
            StateNodeView(name: "completed", color: .blue)
        }
    }
}

struct StateNodeView: View {
    let name: String
    let color: Color
    
    var body: some View {
        Text(name)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        StrategyManagerDemoView()
    }
    .modelContainer(for: [BlockedProfiles.self])
}
