import SwiftUI

/// 场景: 内容与隐私权限制 (Content & Privacy Restrictions)
/// 展示如何使用 ManagedSettingsStore 配置 iOS 的各项内容和隐私限制
struct ContentPrivacyRestrictionsScenarioView: View {
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - App Store 设置
    @State private var denyAppInstallation = false
    @State private var denyAppRemoval = false
    @State private var denyInAppPurchases = false
    @State private var requirePasswordForPurchases = false
    @State private var appStoreMaximumRating: Int? = nil
    
    // MARK: - 媒体内容设置
    @State private var maximumMovieRating: Int? = nil
    @State private var maximumTVShowRating: Int? = nil
    
    // MARK: - Siri 设置
    @State private var denySiri = false
    
    // MARK: - Game Center 设置
    @State private var denyMultiplayerGaming = false
    @State private var denyAddingFriends = false
    
    // MARK: - 系统变更设置
    @State private var lockPasscode = false
    @State private var lockAccounts = false
    @State private var lockAppCellularData = false
    
    // MARK: - 状态
    @State private var isRestrictionsActive = false
    
    private let appBlocker = AppBlockerUtil()
    
    // 分级选项
    private let appRatingOptions: [(String, Int?)] = [
        ("无限制", nil),
        ("4+ (所有年龄)", 100),
        ("9+ (9岁以上)", 200),
        ("12+ (12岁以上)", 300),
        ("17+ (17岁以上)", 600)
    ]
    
    private let movieRatingOptions: [(String, Int?)] = [
        ("无限制", nil),
        ("G (普遍级)", 200),
        ("PG (辅导级)", 300),
        ("PG-13 (13岁以上)", 400),
        ("R (限制级)", 500),
        ("NC-17 (17岁以下禁止)", 600)
    ]
    
    private let tvRatingOptions: [(String, Int?)] = [
        ("无限制", nil),
        ("TV-Y (儿童)", 200),
        ("TV-G (普遍级)", 300),
        ("TV-PG (辅导级)", 400),
        ("TV-14 (14岁以上)", 500),
        ("TV-MA (成人)", 600)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**内容与隐私权限制**演示如何使用 ManagedSettingsStore API 配置 iOS 系统级别的内容和隐私限制。")
                        
                        Text("**主要功能：**")
                        BulletPointView(text: "iTunes 与 App Store 购买限制")
                        BulletPointView(text: "媒体内容分级限制")
                        BulletPointView(text: "Siri 搜索与语言过滤")
                        BulletPointView(text: "Game Center 社交功能限制")
                        BulletPointView(text: "隐私权限变更锁定")
                        BulletPointView(text: "系统设置变更锁定")
                        
                        Text("**适用场景：**")
                        BulletPointView(text: "儿童/青少年设备管理")
                        BulletPointView(text: "企业设备管理 (MDM)")
                        BulletPointView(text: "家长控制功能")
                        BulletPointView(text: "教育机构设备管理")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "ManagedSettingsStore",
                            path: "ManagedSettings Framework",
                            description: "Apple Screen Time API 的核心存储类"
                        )
                        DependencyRowView(
                            name: "AppBlockerUtil",
                            path: "ZenBound/Utils/AppBlockerUtil.swift",
                            description: "封装 ManagedSettingsStore 的工具类"
                        )
                        DependencyRowView(
                            name: "store.appStore",
                            path: "ManagedSettings.AppStoreSettings",
                            description: "App Store 安装/删除/购买限制"
                        )
                        DependencyRowView(
                            name: "store.media",
                            path: "ManagedSettings.MediaSettings",
                            description: "媒体内容分级和过滤"
                        )
                        DependencyRowView(
                            name: "store.siri / store.gameCenter",
                            path: "ManagedSettings",
                            description: "Siri 和 Game Center 限制"
                        )
                        DependencyRowView(
                            name: "store.privacy / store.passcode / store.account",
                            path: "ManagedSettings",
                            description: "隐私权限和系统变更限制"
                        )
                    }
                }
                
                // MARK: - 当前状态
                DemoSectionView(title: "📊 当前状态", icon: "chart.bar") {
                    HStack(spacing: 16) {
                        InfoCardView(
                            icon: isRestrictionsActive ? "lock.shield.fill" : "lock.open.fill",
                            title: "限制状态",
                            value: isRestrictionsActive ? "已启用" : "未启用",
                            color: isRestrictionsActive ? .red : .green
                        )
                        
                        InfoCardView(
                            icon: "slider.horizontal.3",
                            title: "已配置项目",
                            value: "\(countActiveRestrictions())",
                            color: .blue
                        )
                    }
                }
                
                // MARK: - iTunes 与 App Store 购买
                DemoSectionView(title: "🛒 iTunes 与 App Store 购买", icon: "bag.fill") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "禁止安装 App",
                            subtitle: "设为 true 以禁止安装新 App",
                            icon: "arrow.down.app",
                            isOn: $denyAppInstallation,
                            iconColor: .blue
                        )
                        .onChange(of: denyAppInstallation) { _, newValue in
                            addLog("🛒 禁止安装 App: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "禁止删除 App",
                            subtitle: "设为 true 以禁止删除 App",
                            icon: "trash.slash",
                            isOn: $denyAppRemoval,
                            iconColor: .red
                        )
                        .onChange(of: denyAppRemoval) { _, newValue in
                            addLog("🛒 禁止删除 App: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "禁止 App 内购买",
                            subtitle: "设为 true 以禁止所有 App 内购买",
                            icon: "creditcard.trianglebadge.exclamationmark",
                            isOn: $denyInAppPurchases,
                            iconColor: .orange
                        )
                        .onChange(of: denyInAppPurchases) { _, newValue in
                            addLog("🛒 禁止 App 内购买: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "购买时需要密码",
                            subtitle: "设为 true 以要求每次购买都需输入密码",
                            icon: "key.fill",
                            isOn: $requirePasswordForPurchases,
                            iconColor: .purple
                        )
                        .onChange(of: requirePasswordForPurchases) { _, newValue in
                            addLog("🛒 购买时需要密码: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        // App 内容分级选择
                        RatingPickerView(
                            title: "App 内容分级",
                            icon: "star.fill",
                            selectedRating: $appStoreMaximumRating,
                            options: appRatingOptions
                        )
                        .onChange(of: appStoreMaximumRating) { _, newValue in
                            let label = appRatingOptions.first { $0.1 == newValue }?.0 ?? "未知"
                            addLog("🛒 App 内容分级: \(label)", type: .info)
                        }
                    }
                }
                
                // MARK: - 内容限制
                DemoSectionView(title: "🎬 内容限制", icon: "film") {
                    VStack(spacing: 12) {
                        Text("注意: 过滤兒童不宜内容功能在 ManagedSettings 中不可用，需通过设置 App 手动配置。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                        
                        RatingPickerView(
                            title: "电影内容分级",
                            icon: "film.fill",
                            selectedRating: $maximumMovieRating,
                            options: movieRatingOptions
                        )
                        .onChange(of: maximumMovieRating) { _, newValue in
                            let label = movieRatingOptions.first { $0.1 == newValue }?.0 ?? "未知"
                            addLog("🎬 电影内容分级: \(label)", type: .info)
                        }
                        
                        RatingPickerView(
                            title: "电视节目内容分级",
                            icon: "tv.fill",
                            selectedRating: $maximumTVShowRating,
                            options: tvRatingOptions
                        )
                        .onChange(of: maximumTVShowRating) { _, newValue in
                            let label = tvRatingOptions.first { $0.1 == newValue }?.0 ?? "未知"
                            addLog("🎬 电视节目内容分级: \(label)", type: .info)
                        }
                    }
                }
                
                // MARK: - Siri 限制
                DemoSectionView(title: "🎤 Siri 限制", icon: "waveform") {
                    VStack(spacing: 12) {
                        Text("注意: ManagedSettings 仅支持完全禁用 Siri，细粒度控制（网页搜索、语言过滤）不可用。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                        
                        ToggleSettingRow(
                            title: "禁用 Siri",
                            subtitle: "设为 true 以完全禁用 Siri 功能",
                            icon: "waveform.slash",
                            isOn: $denySiri,
                            iconColor: .red
                        )
                        .onChange(of: denySiri) { _, newValue in
                            addLog("🎤 禁用 Siri: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                    }
                }
                
                // MARK: - Game Center 限制
                DemoSectionView(title: "🎮 Game Center 限制", icon: "gamecontroller") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "禁止多人游戏",
                            subtitle: "设为 true 以禁止多人游戏功能",
                            icon: "person.2.fill",
                            isOn: $denyMultiplayerGaming,
                            iconColor: .green
                        )
                        .onChange(of: denyMultiplayerGaming) { _, newValue in
                            addLog("🎮 禁止多人游戏: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "禁止加入朋友",
                            subtitle: "设为 true 以禁止新增朋友",
                            icon: "person.badge.plus",
                            isOn: $denyAddingFriends,
                            iconColor: .teal
                        )
                        .onChange(of: denyAddingFriends) { _, newValue in
                            addLog("🎮 禁止加入朋友: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                    }
                }
                
                // MARK: - 系统变更限制
                DemoSectionView(title: "⚙️ 系统变更限制", icon: "gearshape.2") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "锁定密码",
                            subtitle: "设为 true 以锁定装置密码的变更",
                            icon: "lock.rectangle",
                            isOn: $lockPasscode,
                            iconColor: .red
                        )
                        .onChange(of: lockPasscode) { _, newValue in
                            addLog("⚙️ 锁定密码: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "锁定帐号",
                            subtitle: "设为 true 以锁定 iCloud 和郵件等帐号的变更",
                            icon: "person.crop.circle.badge.xmark",
                            isOn: $lockAccounts,
                            iconColor: .orange
                        )
                        .onChange(of: lockAccounts) { _, newValue in
                            addLog("⚙️ 锁定帐号: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "锁定 App 行动数据",
                            subtitle: "设为 true 以锁定 App 的行动数据设置",
                            icon: "antenna.radiowaves.left.and.right",
                            isOn: $lockAppCellularData,
                            iconColor: .blue
                        )
                        .onChange(of: lockAppCellularData) { _, newValue in
                            addLog("⚙️ 锁定 App 行动数据: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                    }
                }
                
                // MARK: - 操作按钮
                DemoSectionView(title: "🚀 操作", icon: "play.fill") {
                    VStack(spacing: 12) {
                        Button {
                            applyRestrictions()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("应用所有限制")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button {
                            clearRestrictions()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.shield")
                                Text("清除所有限制")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button {
                            applyChildSafetyPreset()
                        } label: {
                            HStack {
                                Image(systemName: "figure.and.child.holdinghands")
                                Text("应用儿童安全预设")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. App Store 限制",
                            description: "禁止安装/删除应用和 App 内购买",
                            code: """
// App 安装/删除限制 (在 application 设置中)
store.application.denyAppInstallation = true
store.application.denyAppRemoval = true

// App Store 购买限制
store.appStore.denyInAppPurchases = true
store.appStore.requirePasswordForPurchases = true
store.appStore.maximumRating = 300  // 12+
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 媒体内容限制",
                            description: "设置电影和电视分级限制",
                            code: """
// 媒体内容分级限制
store.media.maximumMovieRating = 400   // PG-13
store.media.maximumTVShowRating = 500  // TV-14

// 注意: denyExplicitContent 在 ManagedSettings 中不可用
// 需通过设置 App 手动配置
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. Siri 和 Game Center 限制",
                            description: "禁用 Siri 和限制社交功能",
                            code: """
// Siri 限制 (仅支持完全禁用)
store.siri.denySiri = true

// Game Center 限制
store.gameCenter.denyMultiplayerGaming = true
store.gameCenter.denyAddingFriends = true
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 系统变更限制",
                            description: "锁定密码、帐号和行动数据",
                            code: """
// 系统变更限制
store.passcode.lockPasscode = true
store.account.lockAccounts = true
store.cellular.lockAppCellularData = true
"""
                        )
                    }
                }
                
                // MARK: - 改进建议
                DemoSectionView(title: "💡 改进建议", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ImprovementCardView(
                            priority: .high,
                            title: "添加预设配置模板",
                            description: "为不同年龄段儿童创建预设配置，如 6岁以下、6-12岁、12-17岁等",
                            relatedFiles: ["AppBlockerUtil.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "添加定时限制功能",
                            description: "结合 Schedule 功能，在特定时间段自动启用/关闭内容限制",
                            relatedFiles: ["Schedule.swift", "ScheduleTimerActivity.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "添加远程管理功能",
                            description: "通过 iCloud 同步配置，支持家长远程管理孩子设备",
                            relatedFiles: ["SharedData.swift"]
                        )
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("内容与隐私权限制")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    logMessages.removeAll()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
    
    private func countActiveRestrictions() -> Int {
        var count = 0
        if denyAppInstallation { count += 1 }
        if denyAppRemoval { count += 1 }
        if denyInAppPurchases { count += 1 }
        if requirePasswordForPurchases { count += 1 }
        if appStoreMaximumRating != nil { count += 1 }
        if maximumMovieRating != nil { count += 1 }
        if maximumTVShowRating != nil { count += 1 }
        if denySiri { count += 1 }
        if denyMultiplayerGaming { count += 1 }
        if denyAddingFriends { count += 1 }
        if lockPasscode { count += 1 }
        if lockAccounts { count += 1 }
        if lockAppCellularData { count += 1 }
        return count
    }
    
    private func applyRestrictions() {
        addLog("🚀 开始应用所有限制...", type: .info)
        
        let config = AppBlockerUtil.ContentPrivacyConfig(
            denyAppInstallation: denyAppInstallation,
            denyAppRemoval: denyAppRemoval,
            denyInAppPurchases: denyInAppPurchases,
            requirePasswordForPurchases: requirePasswordForPurchases,
            appStoreMaximumRating: appStoreMaximumRating,
            maximumMovieRating: maximumMovieRating,
            maximumTVShowRating: maximumTVShowRating,
            denySiri: denySiri,
            denyMultiplayerGaming: denyMultiplayerGaming,
            denyAddingFriends: denyAddingFriends,
            lockPasscode: lockPasscode,
            lockAccounts: lockAccounts,
            lockAppCellularData: lockAppCellularData
        )
        
        appBlocker.applyContentPrivacyRestrictions(config)
        isRestrictionsActive = true
        
        addLog("✅ 所有限制已应用成功！共 \(countActiveRestrictions()) 项", type: .success)
    }
    
    private func clearRestrictions() {
        addLog("🗑️ 开始清除所有限制...", type: .info)
        
        appBlocker.clearAllContentPrivacyRestrictions()
        
        // 重置所有状态
        denyAppInstallation = false
        denyAppRemoval = false
        denyInAppPurchases = false
        requirePasswordForPurchases = false
        appStoreMaximumRating = nil
        maximumMovieRating = nil
        maximumTVShowRating = nil
        denySiri = false
        denyMultiplayerGaming = false
        denyAddingFriends = false
        lockPasscode = false
        lockAccounts = false
        lockAppCellularData = false
        
        isRestrictionsActive = false
        
        addLog("✅ 所有限制已清除！", type: .success)
    }
    
    private func applyChildSafetyPreset() {
        addLog("👶 应用儿童安全预设...", type: .info)
        
        // 设置儿童安全预设值
        denyAppInstallation = true
        denyAppRemoval = true
        denyInAppPurchases = true
        requirePasswordForPurchases = true
        appStoreMaximumRating = 200  // 9+
        maximumMovieRating = 300     // PG
        maximumTVShowRating = 300    // TV-G
        denySiri = true
        denyMultiplayerGaming = true
        denyAddingFriends = true
        
        // 应用设置
        applyRestrictions()
        
        addLog("✅ 儿童安全预设已应用！", type: .success)
    }
}

// MARK: - Rating Picker View
/// 分级选择器组件
struct RatingPickerView: View {
    let title: String
    let icon: String
    @Binding var selectedRating: Int?
    let options: [(String, Int?)]
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
            Spacer()
            
            Menu {
                ForEach(options, id: \.0) { option in
                    Button {
                        selectedRating = option.1
                    } label: {
                        if selectedRating == option.1 {
                            Label(option.0, systemImage: "checkmark")
                        } else {
                            Text(option.0)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(options.first { $0.1 == selectedRating }?.0 ?? "无限制")
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        ContentPrivacyRestrictionsScenarioView()
    }
}
