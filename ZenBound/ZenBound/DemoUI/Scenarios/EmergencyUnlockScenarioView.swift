import SwiftUI
import SwiftData

/// 场景7: 紧急解锁机制
/// 严格模式下的安全阀门，防止完全被锁死
struct EmergencyUnlockScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var strategyManager: StrategyManager
    
    @State private var logMessages: [LogMessage] = []
    @State private var remainingUnlocks = 3
    @State private var resetPeriodWeeks = 1
    @State private var isStrictModeActive = true
    @State private var showConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**紧急解锁机制**是严格模式下的安全阀门，确保用户在真正紧急情况下可以解除屏蔽。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "紧急工作电话需要使用被屏蔽的应用")
                        BulletPointView(text: "家人紧急联系需要使用社交应用")
                        BulletPointView(text: "意外情况需要临时解除限制")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "有限的解锁次数（如每周3次）")
                        BulletPointView(text: "解锁需要确认，防止误触")
                        BulletPointView(text: "定期自动重置次数")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "StrategyManager.emergencyUnblock()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "紧急解锁 - 执行解锁操作"
                        )
                        DependencyRowView(
                            name: "enableStrictMode",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "严格模式 - 启用紧急解锁限制"
                        )
                        DependencyRowView(
                            name: "emergencyUnblocksRemaining",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "剩余次数 - UserDefaults存储"
                        )
                        DependencyRowView(
                            name: "getNextResetDate()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "重置时间 - 计算下次重置日期"
                        )
                        DependencyRowView(
                            name: "checkAndResetEmergencyUnblocks()",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "自动重置 - 检查并重置次数"
                        )
                    }
                }
                
                // MARK: - 紧急解锁状态
                DemoSectionView(title: "🆘 紧急解锁状态", icon: "exclamationmark.shield") {
                    VStack(spacing: 16) {
                        // 剩余次数显示
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.red.opacity(0.2), lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(remainingUnlocks) / 3.0)
                                    .stroke(remainingUnlocks > 0 ? Color.red : Color.gray, lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("\(remainingUnlocks)")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(remainingUnlocks > 0 ? .red : .gray)
                                    Text("剩余次数")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // 重置信息
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("重置周期: \(resetPeriodWeeks) 周")
                                    .font(.subheadline)
                                Text("下次重置: \(nextResetDateString)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        // 严格模式状态
                        HStack {
                            Image(systemName: isStrictModeActive ? "lock.fill" : "lock.open")
                                .foregroundColor(isStrictModeActive ? .red : .green)
                            VStack(alignment: .leading) {
                                Text("严格模式: \(isStrictModeActive ? "启用" : "禁用")")
                                    .font(.subheadline)
                                Text(isStrictModeActive ? "正常停止已禁用" : "可随时停止")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $isStrictModeActive)
                                .labelsHidden()
                        }
                        .padding()
                        .background(isStrictModeActive ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        // 紧急解锁按钮
                        Button {
                            showConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                Text("紧急解锁")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(remainingUnlocks <= 0 || !isStrictModeActive)
                        
                        if remainingUnlocks <= 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("本周解锁次数已用完")
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Divider()
                        
                        // 管理操作
                        HStack {
                            Button {
                                resetUnlocks()
                            } label: {
                                Label("重置次数", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                adjustResetPeriod()
                            } label: {
                                Label("调整周期", systemImage: "calendar.badge.clock")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // MARK: - 解锁历史
                DemoSectionView(title: "📜 解锁历史", icon: "clock.arrow.circlepath") {
                    VStack(alignment: .leading, spacing: 8) {
                        UnlockHistoryRow(date: "今天 14:32", reason: "紧急工作电话")
                        UnlockHistoryRow(date: "昨天 09:15", reason: "家人急事")
                        UnlockHistoryRow(date: "3天前 18:45", reason: "医疗预约确认")
                        
                        Text("仅显示最近7天记录")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 检查剩余次数",
                            description: "获取当前可用的紧急解锁次数",
                            code: """
let manager = StrategyManager.shared

// 获取剩余次数
let remaining = manager.getRemainingEmergencyUnblocks()
// 返回: 0-3 (默认每周3次)

// 获取重置周期
let weeks = manager.getResetPeriodInWeeks()
// 返回: 1-4 周

// 获取下次重置日期
if let nextReset = manager.getNextResetDate() {
    // 显示倒计时或日期
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 执行紧急解锁",
                            description: "消耗一次解锁机会并解除屏蔽",
                            code: """
// 执行紧急解锁
manager.emergencyUnblock(context: modelContext)

// 内部逻辑:
// 1. 检查 remainingUnlocks > 0
// 2. remainingUnlocks -= 1
// 3. 调用 stopBlocking()
// 4. 记录解锁时间 (用于统计)

// 解锁后会话状态变为 .completed
// Live Activity 会被结束
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 自动重置检查",
                            description: "应用启动时检查是否需要重置",
                            code: """
// 在 App 启动时调用
manager.checkAndResetEmergencyUnblocks()

// 内部逻辑:
// 1. 读取 lastResetTimestamp
// 2. 计算距今是否超过 resetPeriodInWeeks
// 3. 如果超过，重置次数为 3

// 手动重置 (管理员功能)
manager.resetEmergencyUnblocks()
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 配置严格模式",
                            description: "在配置中启用严格模式",
                            code: """
// 创建严格模式配置
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "深度工作",
    selection: distractingApps,
    blockingStrategyId: ManualBlockingStrategy.id,
    enableStrictMode: true  // 关键: 启用严格模式
)

// 更新现有配置
let _ = BlockedProfiles.updateProfile(
    profile, in: context,
    enableStrictMode: true
)

// 严格模式下:
// - 正常停止按钮被禁用
// - 只能通过紧急解锁停止
// - 或等待计时器/日程自动结束
"""
                        )
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 改进建议
                DemoSectionView(title: "💡 改进建议", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ImprovementCardView(
                            priority: .high,
                            title: "添加解锁原因记录",
                            description: "每次紧急解锁时要求输入原因，便于后续反思",
                            relatedFiles: ["StrategyManager.swift", "新建 UnlockHistory.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "渐进式惩罚机制",
                            description: "频繁使用紧急解锁会减少下周的解锁次数",
                            relatedFiles: ["StrategyManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "解锁冷却期",
                            description: "紧急解锁后需要等待一段时间才能再次启动屏蔽",
                            relatedFiles: ["StrategyManager.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "可信联系人解锁",
                            description: "允许设置可信联系人，他们可以帮助解锁",
                            relatedFiles: ["新建 TrustedContacts.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "解锁统计报告",
                            description: "生成解锁使用报告，帮助用户了解自己的习惯",
                            relatedFiles: ["ProfileInsightsUtil.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("紧急解锁机制")
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认紧急解锁", isPresented: $showConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确认解锁", role: .destructive) {
                performEmergencyUnlock()
            }
        } message: {
            Text("确定要使用一次紧急解锁吗？\n剩余次数: \(remainingUnlocks) → \(remainingUnlocks - 1)")
        }
        .onAppear {
            remainingUnlocks = strategyManager.getRemainingEmergencyUnblocks()
            resetPeriodWeeks = strategyManager.getResetPeriodInWeeks()
        }
    }
    
    // MARK: - Computed Properties
    
    private var nextResetDateString: String {
        if let date = strategyManager.getNextResetDate() {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
        return "未知"
    }
    
    // MARK: - Private Methods
    
    private func performEmergencyUnlock() {
        guard remainingUnlocks > 0 else { return }
        
        addLog("🆘 执行紧急解锁", type: .warning)
        addLog("📉 剩余次数: \(remainingUnlocks) → \(remainingUnlocks - 1)", type: .info)
        
        remainingUnlocks -= 1
        
        addLog("🔓 StrategyManager.emergencyUnlock()", type: .success)
        addLog("📱 AppBlockerUtil.deactivateRestrictions()", type: .success)
        addLog("✅ 紧急解锁成功", type: .success)
    }
    
    private func resetUnlocks() {
        addLog("🔄 重置解锁次数", type: .info)
        remainingUnlocks = 3
        addLog("📊 剩余次数已重置为 3", type: .success)
    }
    
    private func adjustResetPeriod() {
        resetPeriodWeeks = resetPeriodWeeks >= 4 ? 1 : resetPeriodWeeks + 1
        addLog("📅 调整重置周期: \(resetPeriodWeeks) 周", type: .info)
        addLog("💾 StrategyManager.setResetPeriodInWeeks()", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Unlock History Row
struct UnlockHistoryRow: View {
    let date: String
    let reason: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.shield")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reason)
                    .font(.subheadline)
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        EmergencyUnlockScenarioView()
            .environmentObject(StrategyManager.shared)
    }
}
