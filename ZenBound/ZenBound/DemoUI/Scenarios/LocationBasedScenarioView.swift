import SwiftUI
import SwiftData
import CoreLocation

/// 场景: 地理位置组配置
/// 根据用户所在的地理位置自动切换不同的屏蔽策略
struct LocationBasedScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedLocation: LocationPreset = .home
    @State private var customLocationName = ""
    @State private var isMonitoring = false
    
    // MARK: - 位置设置
    @State private var homeProfile: BlockedProfiles?
    @State private var schoolProfile: BlockedProfiles?
    @State private var workProfile: BlockedProfiles?
    @State private var otherProfile: BlockedProfiles?
    
    // MARK: - 高级设置
    @State private var autoSwitch = true
    @State private var notifyOnSwitch = true
    @State private var geofenceRadius: Double = 100 // 米
    @State private var delayBeforeSwitch: Int = 5 // 分钟
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**地理位置组配置**根据用户所在地理位置自动应用不同的屏蔽策略，实现智能化的屏幕时间管理。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "在家时允许娱乐应用，但限制社交媒体")
                        BulletPointView(text: "在学校/图书馆时自动启用严格学习模式")
                        BulletPointView(text: "在办公室时屏蔽游戏和短视频应用")
                        BulletPointView(text: "在其他位置使用默认或宽松策略")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "支持多个地理围栏位置")
                        BulletPointView(text: "每个位置可绑定不同的屏蔽配置")
                        BulletPointView(text: "自动检测位置变化并切换策略")
                        BulletPointView(text: "支持延迟切换，避免频繁变动")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "BlockedProfiles",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "屏蔽配置 - 每个位置绑定一个配置"
                        )
                        DependencyRowView(
                            name: "ManualBlockingStrategy",
                            path: "ZenBound/Models/Strategies/ManualBlockingStrategy.swift",
                            description: "手动策略 - 位置切换时使用"
                        )
                        DependencyRowView(
                            name: "StrategyManager",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "策略管理 - 切换屏蔽会话"
                        )
                        DependencyRowView(
                            name: "AppBlockerUtil",
                            path: "ZenBound/Utils/AppBlockerUtil.swift",
                            description: "应用屏蔽 - 激活/停用限制"
                        )
                        DependencyRowView(
                            name: "CoreLocation",
                            path: "Apple Framework",
                            description: "位置服务 - 地理围栏监控"
                        )
                        DependencyRowView(
                            name: "TimersUtil",
                            path: "ZenBound/Utils/TimersUtil.swift",
                            description: "通知调度 - 位置切换提醒"
                        )
                    }
                }
                
                // MARK: - 改进建议
                DemoSectionView(title: "💡 改进建议", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ImprovementRowView(
                            priority: .high,
                            title: "创建 LocationManager 工具类",
                            description: "封装 CLLocationManager，处理地理围栏注册、位置更新和权限请求"
                        )
                        
                        ImprovementRowView(
                            priority: .high,
                            title: "新增 LocationProfile 数据模型",
                            description: "存储位置名称、坐标、半径和关联的 BlockedProfiles ID"
                        )
                        
                        ImprovementRowView(
                            priority: .medium,
                            title: "实现后台位置监控",
                            description: "使用 startMonitoring(for:) 在应用后台时也能检测位置变化"
                        )
                        
                        ImprovementRowView(
                            priority: .medium,
                            title: "添加 Shortcuts 集成",
                            description: "暴露 App Intent 让用户通过快捷指令手动切换位置策略"
                        )
                        
                        ImprovementRowView(
                            priority: .low,
                            title: "添加位置历史记录",
                            description: "记录位置切换历史，用于分析用户习惯和优化策略"
                        )
                        
                        ImprovementRowView(
                            priority: .low,
                            title: "支持 Wi-Fi 网络识别",
                            description: "除 GPS 外，可通过连接的 Wi-Fi 网络名称辅助判断位置"
                        )
                    }
                }
                
                // MARK: - 位置预设配置
                DemoSectionView(title: "📍 位置预设配置", icon: "location.circle") {
                    VStack(spacing: 16) {
                        // 位置选择器
                        ForEach(LocationPreset.allCases, id: \.self) { location in
                            LocationPresetRowView(
                                preset: location,
                                isSelected: selectedLocation == location,
                                assignedProfile: getAssignedProfile(for: location),
                                availableProfiles: profiles,
                                onSelect: {
                                    selectedLocation = location
                                    addLog("📍 选择位置: \(location.name)", type: .info)
                                },
                                onProfileAssign: { profile in
                                    assignProfile(profile, to: location)
                                }
                            )
                        }
                        
                        // 状态显示
                        HStack {
                            Image(systemName: isMonitoring ? "location.fill" : "location.slash")
                                .foregroundColor(isMonitoring ? .green : .secondary)
                            Text(isMonitoring ? "位置监控已启用" : "位置监控已停用")
                                .font(.subheadline)
                                .foregroundStyle(isMonitoring ? .primary : .secondary)
                            Spacer()
                        }
                        .padding()
                        .background(isMonitoring ? Color.green.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(10)
                        
                        // 操作按钮
                        Button {
                            toggleLocationMonitoring()
                        } label: {
                            Label(
                                isMonitoring ? "停止位置监控" : "启动位置监控",
                                systemImage: isMonitoring ? "location.slash" : "location"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isMonitoring ? .red : .accentColor)
                    }
                }
                
                // MARK: - 高级设置
                DemoSectionView(title: "⚙️ 高级设置", icon: "gearshape") {
                    VStack(spacing: 12) {
                        ToggleSettingRow(
                            title: "自动切换策略",
                            subtitle: "进入/离开位置时自动应用对应配置",
                            icon: "arrow.triangle.swap",
                            isOn: $autoSwitch
                        )
                        .onChange(of: autoSwitch) { _, newValue in
                            addLog("🔄 自动切换: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        ToggleSettingRow(
                            title: "切换时通知",
                            subtitle: "策略切换时发送本地通知",
                            icon: "bell.badge",
                            isOn: $notifyOnSwitch
                        )
                        .onChange(of: notifyOnSwitch) { _, newValue in
                            addLog("🔔 切换通知: \(newValue ? "开启" : "关闭")", type: .info)
                        }
                        
                        // 地理围栏半径
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("地理围栏半径", systemImage: "circle.dashed")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(geofenceRadius)) 米")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(value: $geofenceRadius, in: 50...500, step: 50)
                                .onChange(of: geofenceRadius) { _, newValue in
                                    addLog("📏 围栏半径设置为 \(Int(newValue)) 米", type: .info)
                                }
                            
                            HStack {
                                Text("50m")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("500m")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        // 延迟切换时间
                        DurationPickerView(
                            title: "延迟切换时间",
                            icon: "timer",
                            selectedMinutes: $delayBeforeSwitch,
                            options: [0, 1, 2, 5, 10, 15]
                        )
                        .onChange(of: delayBeforeSwitch) { _, newValue in
                            if newValue == 0 {
                                addLog("⏱️ 即时切换（无延迟）", type: .info)
                            } else {
                                addLog("⏱️ 延迟 \(newValue) 分钟后切换", type: .info)
                            }
                        }
                        
                        // 提示
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("延迟切换可避免短暂进出某区域时频繁切换策略，建议设置 2-5 分钟")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 创建 LocationManager",
                            description: "封装 CoreLocation 进行地理围栏监控",
                            code: """
// LocationManager.swift (建议新增)
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentRegion: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
    }
    
    func registerGeofence(
        identifier: String,
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance
    ) {
        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        manager.startMonitoring(for: region)
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        currentRegion = region.identifier
        // 触发策略切换
        NotificationCenter.default.post(
            name: .locationDidChange,
            object: region.identifier
        )
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 位置变化时切换策略",
                            description: "监听位置变化并应用对应的屏蔽配置",
                            code: """
// 在 App 或 ViewModel 中监听位置变化
NotificationCenter.default.addObserver(
    forName: .locationDidChange,
    object: nil,
    queue: .main
) { notification in
    guard let locationId = notification.object as? String else { return }
    
    // 获取该位置关联的配置
    if let profile = getProfileForLocation(locationId) {
        // 切换到新策略
        strategyManager.toggleBlocking(
            context: context,
            activeProfile: profile
        )
        
        // 发送切换通知
        if notifyOnSwitch {
            sendLocalNotification(
                title: "位置策略已切换",
                body: "已应用「\\(profile.name)」配置"
            )
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. 创建位置配置数据模型",
                            description: "存储位置与配置的映射关系",
                            code: """
// LocationProfile.swift (建议新增)
import SwiftData
import CoreLocation

@Model
final class LocationProfile {
    var id: UUID
    var name: String                    // 位置名称
    var latitude: Double                // 纬度
    var longitude: Double               // 经度
    var radius: Double                  // 地理围栏半径（米）
    var blockedProfileId: UUID?         // 关联的屏蔽配置ID
    var isEnabled: Bool                 // 是否启用
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
    
    init(
        name: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double = 100,
        blockedProfileId: UUID? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.radius = radius
        self.blockedProfileId = blockedProfileId
        self.isEnabled = true
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. 添加快捷指令支持",
                            description: "让用户通过 Siri 手动切换位置策略",
                            code: """
// LocationAppIntent.swift (建议新增)
import AppIntents

struct SwitchLocationStrategyIntent: AppIntent {
    static var title: LocalizedStringResource = "切换位置策略"
    
    @Parameter(title: "位置名称")
    var locationName: String
    
    func perform() async throws -> some IntentResult {
        // 查找对应位置的配置
        guard let profile = findProfileForLocation(locationName) else {
            return .result(dialog: "未找到位置「\\(locationName)」的配置")
        }
        
        // 应用配置
        await MainActor.run {
            strategyManager.toggleBlocking(
                context: context,
                activeProfile: profile
            )
        }
        
        return .result(dialog: "已切换到「\\(profile.name)」策略")
    }
}
"""
                        )
                    }
                }
                
                // MARK: - 使用示例
                DemoSectionView(title: "🎯 典型用例", icon: "star") {
                    VStack(alignment: .leading, spacing: 16) {
                        UseCaseCardView(
                            title: "学生日常",
                            icon: "graduationcap.fill",
                            color: .purple,
                            scenarios: [
                                "🏠 在家：允许社交和娱乐，但限制游戏时间",
                                "🏫 在学校：启用严格模式，仅保留学习应用",
                                "📚 在图书馆：最严格模式，屏蔽所有干扰"
                            ]
                        )
                        
                        UseCaseCardView(
                            title: "上班族",
                            icon: "briefcase.fill",
                            color: .blue,
                            scenarios: [
                                "🏢 在办公室：屏蔽社交媒体和短视频",
                                "🏠 在家：正常使用，可选择性屏蔽",
                                "☕️ 在咖啡厅：启用专注模式"
                            ]
                        )
                        
                        UseCaseCardView(
                            title: "家长控制",
                            icon: "figure.2.and.child.holdinghands",
                            color: .green,
                            scenarios: [
                                "🏠 在家：按时间表控制娱乐时间",
                                "🏫 在学校：完全禁用娱乐应用",
                                "🚗 在路上：仅允许音乐和导航"
                            ]
                        )
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
            }
            .padding()
        }
        .navigationTitle("地理位置组配置")
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Methods
    
    private func addLog(_ message: String, type: LogType) {
        withAnimation {
            logMessages.insert(LogMessage(message: message, type: type), at: 0)
            if logMessages.count > 20 {
                logMessages.removeLast()
            }
        }
    }
    
    private func getAssignedProfile(for location: LocationPreset) -> BlockedProfiles? {
        switch location {
        case .home: return homeProfile
        case .school: return schoolProfile
        case .work: return workProfile
        case .other: return otherProfile
        }
    }
    
    private func assignProfile(_ profile: BlockedProfiles?, to location: LocationPreset) {
        switch location {
        case .home:
            homeProfile = profile
        case .school:
            schoolProfile = profile
        case .work:
            workProfile = profile
        case .other:
            otherProfile = profile
        }
        
        if let profile = profile {
            addLog("✅ 将「\(profile.name)」绑定到\(location.name)", type: .success)
        } else {
            addLog("🗑️ 已取消\(location.name)的配置绑定", type: .info)
        }
    }
    
    private func toggleLocationMonitoring() {
        isMonitoring.toggle()
        
        if isMonitoring {
            addLog("🚀 位置监控已启动", type: .success)
            addLog("📍 正在监控 \(LocationPreset.allCases.count) 个位置", type: .info)
        } else {
            addLog("⏹️ 位置监控已停止", type: .warning)
        }
    }
}

// MARK: - Supporting Types

/// 位置预设枚举
enum LocationPreset: String, CaseIterable {
    case home = "home"
    case school = "school"
    case work = "work"
    case other = "other"
    
    var name: String {
        switch self {
        case .home: return "家"
        case .school: return "学校"
        case .work: return "办公室"
        case .other: return "其他位置"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .school: return "graduationcap.fill"
        case .work: return "building.2.fill"
        case .other: return "mappin.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .home: return .orange
        case .school: return .purple
        case .work: return .blue
        case .other: return .gray
        }
    }
    
    var suggestedAppsToBlock: String {
        switch self {
        case .home: return "可选择性限制社交媒体"
        case .school: return "建议屏蔽游戏、社交、短视频"
        case .work: return "建议屏蔽社交媒体、娱乐应用"
        case .other: return "根据需要自定义"
        }
    }
}

// MARK: - Component Views

/// 位置预设行视图
struct LocationPresetRowView: View {
    let preset: LocationPreset
    let isSelected: Bool
    let assignedProfile: BlockedProfiles?
    let availableProfiles: [BlockedProfiles]
    let onSelect: () -> Void
    let onProfileAssign: (BlockedProfiles?) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 位置信息
            HStack {
                Button(action: onSelect) {
                    HStack(spacing: 12) {
                        Image(systemName: preset.icon)
                            .font(.title2)
                            .foregroundColor(preset.color)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(preset.suggestedAppsToBlock)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            
            // 配置选择
            HStack {
                Text("绑定配置:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Menu {
                    Button {
                        onProfileAssign(nil)
                    } label: {
                        if assignedProfile == nil {
                            Label("无", systemImage: "checkmark")
                        } else {
                            Text("无")
                        }
                    }
                    
                    Divider()
                    
                    ForEach(availableProfiles) { profile in
                        Button {
                            onProfileAssign(profile)
                        } label: {
                            if assignedProfile?.id == profile.id {
                                Label(profile.name, systemImage: "checkmark")
                            } else {
                                Text(profile.name)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(assignedProfile?.name ?? "选择配置")
                            .foregroundColor(assignedProfile != nil ? .primary : .secondary)
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
        }
        .padding()
        .background(isSelected ? preset.color.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? preset.color : Color.clear, lineWidth: 2)
        )
    }
}

/// 改进建议行视图
struct ImprovementRowView: View {
    let priority: ImprovementPriority
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(priority.color)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())
                    
                    Text(priority.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priority.color.opacity(0.2))
                        .foregroundColor(priority.color)
                        .cornerRadius(4)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

enum ImprovementPriority {
    case high, medium, low
    
    var label: String {
        switch self {
        case .high: return "高优先级"
        case .medium: return "中优先级"
        case .low: return "低优先级"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

/// 用例卡片视图
struct UseCaseCardView: View {
    let title: String
    let icon: String
    let color: Color
    let scenarios: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.bold())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(scenarios, id: \.self) { scenario in
                    Text(scenario)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Notification Name Extension (建议添加到项目中)
extension Notification.Name {
    static let locationDidChange = Notification.Name("locationDidChange")
}

#Preview {
    NavigationStack {
        LocationBasedScenarioView()
    }
}
