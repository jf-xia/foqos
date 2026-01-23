import SwiftUI
import SwiftData

/// 场景6: 家庭共享管理
/// 管理多个配置文件，支持家庭成员共享使用
struct FamilySharingScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlockedProfiles.order) private var profiles: [BlockedProfiles]
    @EnvironmentObject private var requestAuthorizer: RequestAuthorizer
    
    @State private var logMessages: [LogMessage] = []
    @State private var showCreateSheet = false
    @State private var selectedMember: FamilyMember?
    
    struct FamilyMember: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let color: Color
        var profiles: [String]  // 关联的配置名称
    }
    
    @State private var familyMembers: [FamilyMember] = [
        FamilyMember(name: "爸爸", icon: "person.fill", color: .blue, profiles: ["工作专注"]),
        FamilyMember(name: "妈妈", icon: "person.fill", color: .pink, profiles: ["购物限制"]),
        FamilyMember(name: "小明", icon: "person.fill", color: .green, profiles: ["学习时间", "游戏限制"]),
        FamilyMember(name: "小红", icon: "person.fill", color: .orange, profiles: ["作业时间"])
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**家庭共享管理**允许家长为家庭成员创建和管理不同的屏蔽配置。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "为孩子设置学习时间和娱乐限制")
                        BulletPointView(text: "家长自己的工作专注配置")
                        BulletPointView(text: "全家共同的屏幕时间管理")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "多配置文件管理")
                        BulletPointView(text: "配置快速切换")
                        BulletPointView(text: "权限统一管理")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "FamilyActivityUtil",
                            path: "ZenBound/Utils/FamilyActivityUtil.swift",
                            description: "家庭活动 - 选择应用和类别"
                        )
                        DependencyRowView(
                            name: "SharedData",
                            path: "ZenBound/Models/Shared.swift",
                            description: "数据共享 - 跨扩展同步配置"
                        )
                        DependencyRowView(
                            name: "BlockedProfiles",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "配置管理 - CRUD和排序"
                        )
                        DependencyRowView(
                            name: "RequestAuthorizer",
                            path: "ZenBound/Utils/RequestAuthorizer.swift",
                            description: "权限管理 - Screen Time授权"
                        )
                        DependencyRowView(
                            name: "ProfileSnapshot",
                            path: "ZenBound/Models/Shared.swift",
                            description: "配置快照 - 跨进程数据共享"
                        )
                    }
                }
                
                // MARK: - 授权状态
                DemoSectionView(title: "🔐 授权状态", icon: "checkmark.shield") {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: requestAuthorizer.isAuthorized ? "checkmark.shield.fill" : "shield.slash")
                                .font(.title)
                                .foregroundColor(requestAuthorizer.isAuthorized ? .green : .red)
                            
                            VStack(alignment: .leading) {
                                Text(requestAuthorizer.isAuthorized ? "已授权" : "未授权")
                                    .font(.headline)
                                Text("Screen Time 家庭控制权限")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if !requestAuthorizer.isAuthorized {
                                Button("请求授权") {
                                    requestAuthorizer.requestAuthorization()
                                    addLog("🔐 请求 Screen Time 授权", type: .info)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        .background(
                            requestAuthorizer.isAuthorized
                            ? Color.green.opacity(0.1)
                            : Color.red.opacity(0.1)
                        )
                        .cornerRadius(12)
                    }
                }
                
                // MARK: - 家庭成员
                DemoSectionView(title: "👨‍👩‍👧‍👦 家庭成员", icon: "person.3") {
                    VStack(spacing: 12) {
                        ForEach(familyMembers) { member in
                            Button {
                                selectedMember = member
                                addLog("👤 选择成员: \(member.name)", type: .info)
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(member.color.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: member.icon)
                                            .foregroundColor(member.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            ForEach(member.profiles, id: \.self) { profile in
                                                Text(profile)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(member.color.opacity(0.1))
                                                    .foregroundColor(member.color)
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedMember?.id == member.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(member.color)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding()
                                .background(
                                    selectedMember?.id == member.id
                                    ? member.color.opacity(0.1)
                                    : Color(.systemGray6)
                                )
                                .cornerRadius(12)
                            }
                        }
                        
                        Button {
                            addLog("➕ 添加新家庭成员", type: .info)
                        } label: {
                            Label("添加家庭成员", systemImage: "person.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 配置文件列表
                DemoSectionView(title: "📋 配置文件 (\(profiles.count))", icon: "list.bullet.rectangle") {
                    VStack(spacing: 12) {
                        if profiles.isEmpty {
                            EmptyStateView(
                                icon: "doc.badge.plus",
                                title: "暂无配置",
                                message: "创建配置文件来开始管理屏幕时间"
                            )
                        } else {
                            ForEach(profiles) { profile in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(profile.name)
                                            .font(.headline)
                                        
                                        HStack {
                                            StatusBadgeView(
                                                profile.schedule != nil ? "有日程" : "手动",
                                                color: profile.schedule != nil ? .blue : .gray,
                                                icon: profile.schedule != nil ? "calendar" : nil
                                            )
                                            
                                            if profile.enableStrictMode {
                                                StatusBadgeView("严格", color: .red, icon: "lock.fill")
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button {
                                            duplicateProfile(profile)
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button {
                                            deleteProfile(profile)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("创建新配置", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            reorderProfiles()
                        } label: {
                            Label("重新排序", systemImage: "arrow.up.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(profiles.count < 2)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 请求家庭控制权限",
                            description: "使用 RequestAuthorizer 获取授权",
                            code: """
let authorizer = RequestAuthorizer()

// 检查授权状态
authorizer.isAuthorized  // Bool
authorizer.authorizationStatus  // AuthorizationStatus

// 请求授权 (会显示系统授权弹窗)
authorizer.requestAuthorization()

// 撤销授权
authorizer.revokeAuthorization()
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 创建多个配置",
                            description: "为不同成员创建专属配置",
                            code: """
// 为孩子创建学习配置
let studyProfile = BlockedProfiles.createProfile(
    in: context,
    name: "小明-学习时间",
    selection: gameAndSocialApps,
    blockingStrategyId: ManualBlockingStrategy.id,
    enableStrictMode: true,  // 孩子配置启用严格模式
    schedule: weekdaySchedule
)

// 为家长创建工作配置
let workProfile = BlockedProfiles.createProfile(
    in: context,
    name: "爸爸-工作专注",
    selection: entertainmentApps,
    enableStrictMode: false  // 家长可自行控制
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 配置排序和管理",
                            description: "调整配置显示顺序",
                            code: """
// 获取所有配置
let profiles = BlockedProfiles.fetchProfiles(in: context)

// 重新排序
let reorderedIds = profiles.map { $0.id }
BlockedProfiles.reorderProfiles(reorderedIds, in: context)

// 复制配置
let cloned = BlockedProfiles.cloneProfile(
    profile, in: context,
    newName: "小红-学习时间"  // 复制给另一个孩子
)

// 删除配置
BlockedProfiles.deleteProfile(profile, in: context)
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 跨进程数据共享",
                            description: "使用 SharedData 同步配置到扩展",
                            code: """
// 保存配置快照 (供扩展读取)
BlockedProfiles.updateSnapshot(for: profile)

// 从 App Group 读取快照 (在扩展中)
if let snapshot = SharedData.snapshot(for: profileId) {
    // 使用快照数据
    snapshot.name
    snapshot.selectedActivity
    snapshot.schedule
}

// 获取所有快照
let allSnapshots = SharedData.profileSnapshots

// 删除快照
SharedData.removeSnapshot(for: profileId)
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
                            title: "添加家庭成员账户",
                            description: "将配置与具体家庭成员关联，而不仅仅是配置名称",
                            relatedFiles: ["新建 FamilyMember.swift", "BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "家长密码保护",
                            description: "修改孩子配置或解除屏蔽需要家长密码",
                            relatedFiles: ["StrategyManager.swift", "新建 ParentalControl.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "使用报告通知",
                            description: "每周向家长发送孩子的屏幕时间使用报告",
                            relatedFiles: ["ProfileInsightsUtil.swift", "TimersUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "远程配置管理",
                            description: "家长可以远程修改孩子设备上的配置",
                            relatedFiles: ["SharedData.swift", "CloudKit"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "配置模板库",
                            description: "提供常见场景的配置模板，一键导入",
                            relatedFiles: ["BlockedProfiles.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("家庭共享管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateSheet) {
            CreateProfileSheet(
                profileName: .constant("新配置"),
                onCreate: { name in
                    createProfile(name: name)
                }
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func createProfile(name: String) {
        addLog("➕ 创建配置: \(name)", type: .info)
        addLog("💾 BlockedProfiles.createProfile()", type: .success)
        addLog("📤 SharedData.updateSnapshot()", type: .success)
        showCreateSheet = false
    }
    
    private func duplicateProfile(_ profile: BlockedProfiles) {
        addLog("📋 复制配置: \(profile.name)", type: .info)
        addLog("💾 BlockedProfiles.cloneProfile()", type: .success)
    }
    
    private func deleteProfile(_ profile: BlockedProfiles) {
        addLog("🗑️ 删除配置: \(profile.name)", type: .warning)
        addLog("💾 BlockedProfiles.deleteProfile()", type: .success)
        addLog("📤 SharedData.removeSnapshot()", type: .success)
    }
    
    private func reorderProfiles() {
        addLog("🔄 重新排序配置", type: .info)
        addLog("💾 BlockedProfiles.reorderProfiles()", type: .success)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

// MARK: - Create Profile Sheet
struct CreateProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profileName: String
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("配置名称") {
                    TextField("输入名称", text: $profileName)
                }
            }
            .navigationTitle("创建配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        onCreate(profileName)
                        dismiss()
                    }
                    .disabled(profileName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        FamilySharingScenarioView()
            .environmentObject(RequestAuthorizer())
    }
}
