import SwiftUI
import FamilyControls

/// FamilyActivityUtil Demo - 展示家庭活动选择计数
struct FamilyActivityUtilDemoView: View {
    @State private var logMessages: [LogMessage] = []
    @State private var mockCategoryCount = 2
    @State private var mockAppCount = 5
    @State private var mockDomainCount = 3
    @State private var isAllowMode = false
    
    private var totalCount: Int {
        mockCategoryCount + mockAppCount + mockDomainCount
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FamilyActivityUtil 提供 FamilyActivitySelection 的计数与校验功能。")
                        
                        Text("**核心方法：**")
                        BulletPointView(text: "countSelectedActivities() - 统计选中项总数")
                        BulletPointView(text: "getCountDisplayText() - 获取显示文本")
                        BulletPointView(text: "shouldShowAllowModeWarning() - 白名单警告")
                        BulletPointView(text: "getSelectionBreakdown() - 获取分类明细")
                        
                        Text("**重要限制：**")
                        BulletPointView(text: "Allow Mode 下类别会展开为具体 App")
                        BulletPointView(text: "系统限制最多 50 个 App")
                        BulletPointView(text: "选择类别可能导致超限")
                    }
                }
                
                // MARK: - 模拟选择
                DemoSectionView(title: "🎯 模拟选择", icon: "checkmark.circle") {
                    VStack(spacing: 16) {
                        Toggle("Allow Mode (白名单)", isOn: $isAllowMode)
                            .onChange(of: isAllowMode) { _, newValue in
                                checkAllowModeWarning()
                            }
                        
                        Divider()
                        
                        StepperRowView(label: "类别数量", value: $mockCategoryCount, range: 0...10)
                        StepperRowView(label: "App 数量", value: $mockAppCount, range: 0...50)
                        StepperRowView(label: "网站数量", value: $mockDomainCount, range: 0...20)
                        
                        Divider()
                        
                        HStack {
                            Text("总计")
                                .font(.headline)
                            Spacer()
                            Text("\(totalCount) 项")
                                .font(.title2.bold())
                        }
                        
                        if isAllowMode && mockCategoryCount > 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Allow Mode 下选择类别可能超过 50 App 限制")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            simulateCount()
                        } label: {
                            Label("计算选中项", systemImage: "number")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            simulateBreakdown()
                        } label: {
                            Label("获取分类明细", systemImage: "chart.pie")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            checkAllowModeWarning()
                        } label: {
                            Label("检查 Allow Mode 警告", systemImage: "exclamationmark.triangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 配置列表显示计数",
                            description: "在配置卡片上显示选中的 App 数量",
                            code: """
struct ProfileCard: View {
    let profile: BlockedProfiles
    
    var body: some View {
        let count = FamilyActivityUtil.countSelectedActivities(
            profile.selectedActivity,
            allowMode: profile.enableAllowMode
        )
        
        Text("\\(count) Apps Selected")
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: Allow Mode 警告",
                            description: "编辑配置时提醒用户潜在问题",
                            code: """
// 在 App 选择器中
if FamilyActivityUtil.shouldShowAllowModeWarning(
    selection, 
    allowMode: isAllowMode
) {
    WarningBanner(
        message: "选择类别可能导致超过 50 App 限制"
    )
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 获取分类明细",
                            description: "调试或统计时查看详细分布",
                            code: """
let breakdown = FamilyActivityUtil.getSelectionBreakdown(selection)

print("Categories: \\(breakdown.categories)")
print("Applications: \\(breakdown.applications)")
print("Web Domains: \\(breakdown.webDomains)")
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("FamilyActivityUtil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            addLog("页面加载", type: .info)
        }
    }
    
    // MARK: - Actions
    private func simulateCount() {
        addLog("📊 计算选中项:", type: .info)
        addLog("   模式: \(isAllowMode ? "Allow (白名单)" : "Block (黑名单)")", type: .info)
        addLog("   类别: \(mockCategoryCount)", type: .info)
        addLog("   App: \(mockAppCount)", type: .info)
        addLog("   网站: \(mockDomainCount)", type: .info)
        addLog("   总计: \(totalCount) 项", type: .success)
    }
    
    private func simulateBreakdown() {
        addLog("📋 分类明细:", type: .info)
        addLog("   categories: \(mockCategoryCount)", type: .info)
        addLog("   applications: \(mockAppCount)", type: .info)
        addLog("   webDomains: \(mockDomainCount)", type: .info)
        
        let percentage = Double(mockAppCount) / Double(max(totalCount, 1)) * 100
        addLog("   App 占比: \(String(format: "%.1f", percentage))%", type: .info)
    }
    
    private func checkAllowModeWarning() {
        if isAllowMode && mockCategoryCount > 0 {
            addLog("⚠️ 需要显示 Allow Mode 警告", type: .warning)
            addLog("   原因: Allow Mode 下选择了 \(mockCategoryCount) 个类别", type: .info)
            addLog("   问题: 系统会将类别展开为具体 App", type: .info)
            addLog("   风险: 可能超过 50 App 限制", type: .error)
        } else if isAllowMode {
            addLog("✅ Allow Mode 无需警告", type: .success)
            addLog("   未选择任何类别，只选择了具体 App", type: .info)
        } else {
            addLog("ℹ️ Block Mode 无限制", type: .info)
            addLog("   Block Mode 下类别计为 1 项", type: .info)
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }
}

// MARK: - Supporting Views
struct StepperRowView: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Stepper("\(value)", value: $value, in: range)
        }
    }
}

#Preview {
    NavigationStack {
        FamilyActivityUtilDemoView()
    }
}
