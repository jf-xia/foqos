import SwiftUI
import SwiftData
import FamilyControls

/// BlockedProfiles Demo - 展示屏蔽配置的 CRUD 操作
struct BlockedProfilesDemoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var showingCreateSheet = false
    @State private var newProfileName = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BlockedProfiles 是应用的核心数据模型，定义了一个完整的屏蔽配置。")
                        
                        Text("**主要属性：**")
                        BulletPointView(text: "id/name - 唯一标识和名称")
                        BulletPointView(text: "selectedActivity - 要屏蔽的 App/网站/类别")
                        BulletPointView(text: "blockingStrategyId - 使用的屏蔽策略")
                        BulletPointView(text: "schedule - 自动屏蔽日程")
                        BulletPointView(text: "enableBreaks/enableStrictMode - 功能开关")
                        
                        Text("**核心方法：**")
                        BulletPointView(text: "createProfile() - 创建新配置")
                        BulletPointView(text: "updateProfile() - 更新配置")
                        BulletPointView(text: "deleteProfile() - 删除配置")
                        BulletPointView(text: "cloneProfile() - 复制配置")
                    }
                }
                
                // MARK: - 当前数据
                DemoSectionView(title: "📊 当前配置列表", icon: "list.bullet.rectangle") {
                    if profiles.isEmpty {
                        Text("暂无配置，点击下方按钮创建")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(profiles) { profile in
                            ProfileRowView(profile: profile, onDelete: {
                                deleteProfile(profile)
                            })
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("创建新配置", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if let firstProfile = profiles.first {
                            Button {
                                cloneProfile(firstProfile)
                            } label: {
                                Label("复制第一个配置", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                updateProfileOrder()
                            } label: {
                                Label("重新排序所有配置", systemImage: "arrow.up.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button {
                            fetchAndLogProfiles()
                        } label: {
                            Label("获取所有配置", systemImage: "magnifyingglass")
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
                            title: "场景1: 创建工作专注配置",
                            description: "创建一个屏蔽社交媒体的配置，使用 NFC 策略，需要扫描标签才能解除",
                            code: """
let profile = try BlockedProfiles.createProfile(
    in: context,
    name: "工作专注",
    selection: socialMediaApps,
    blockingStrategyId: NFCBlockingStrategy.id,
    enableStrictMode: true
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 设置自动日程",
                            description: "配置每周一至周五 9:00-18:00 自动启用屏蔽",
                            code: """
let schedule = BlockedProfileSchedule(
    days: [.monday, .tuesday, .wednesday, .thursday, .friday],
    startHour: 9, startMinute: 0,
    endHour: 18, endMinute: 0
)
try BlockedProfiles.updateProfile(
    profile, in: context, 
    schedule: schedule
)
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 启用休息模式",
                            description: "允许用户在屏蔽期间休息 15 分钟",
                            code: """
try BlockedProfiles.updateProfile(
    profile, in: context,
    enableBreaks: true,
    breakTimeInMinutes: 15
)
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("BlockedProfiles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreateSheet) {
            CreateProfileSheet(
                profileName: $newProfileName,
                onCreate: createProfile
            )
        }
        .onAppear {
            addLog("页面加载，当前有 \(profiles.count) 个配置", type: .info)
        }
    }
    
    // MARK: - Actions
    private func createProfile() {
        guard !newProfileName.isEmpty else {
            addLog("配置名称不能为空", type: .error)
            return
        }
        
        do {
            let profile = try BlockedProfiles.createProfile(
                in: modelContext,
                name: newProfileName,
                blockingStrategyId: ManualBlockingStrategy.id
            )
            addLog("✅ 创建配置成功: \(profile.name) (ID: \(profile.id.uuidString.prefix(8))...)", type: .success)
            newProfileName = ""
            showingCreateSheet = false
        } catch {
            addLog("❌ 创建失败: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func deleteProfile(_ profile: BlockedProfiles) {
        let name = profile.name
        do {
            try BlockedProfiles.deleteProfile(profile, in: modelContext)
            try modelContext.save()
            addLog("🗑️ 删除配置成功: \(name)", type: .warning)
        } catch {
            addLog("❌ 删除失败: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func cloneProfile(_ profile: BlockedProfiles) {
        do {
            let cloned = try BlockedProfiles.cloneProfile(
                profile,
                in: modelContext,
                newName: "\(profile.name) (副本)"
            )
            addLog("📋 复制配置成功: \(cloned.name)", type: .success)
        } catch {
            addLog("❌ 复制失败: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func updateProfileOrder() {
        do {
            try BlockedProfiles.reorderProfiles(profiles.reversed(), in: modelContext)
            addLog("🔄 重新排序完成", type: .info)
        } catch {
            addLog("❌ 排序失败: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func fetchAndLogProfiles() {
        do {
            let allProfiles = try BlockedProfiles.fetchProfiles(in: modelContext)
            addLog("📊 查询到 \(allProfiles.count) 个配置:", type: .info)
            for (index, p) in allProfiles.enumerated() {
                addLog("  [\(index)] \(p.name) - 策略: \(p.blockingStrategyId ?? "无")", type: .info)
            }
        } catch {
            addLog("❌ 查询失败: \(error.localizedDescription)", type: .error)
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
struct ProfileRowView: View {
    let profile: BlockedProfiles
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label(profile.blockingStrategyId ?? "Manual", systemImage: "shield")
                        .font(.caption)
                    if profile.enableBreaks {
                        Label("休息", systemImage: "cup.and.saucer")
                            .font(.caption)
                    }
                    if profile.enableStrictMode {
                        Label("严格", systemImage: "lock.fill")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CreateProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profileName: String
    let onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("配置信息") {
                    TextField("配置名称", text: $profileName)
                }
                
                Section {
                    Text("创建后可在详情页配置更多选项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新建配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") { onCreate() }
                        .disabled(profileName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BlockedProfilesDemoView()
    }
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self])
}
