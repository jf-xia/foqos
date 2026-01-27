import SwiftUI
import SwiftData
import CoreLocation
import FamilyControls

/// 场景: 地理位置组配置
/// 完整流程实现：权限检查 → 位置配置 → App选择 → 默认限制 → 监控启动 → 测试验证
struct LocationBasedScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var strategyManager: StrategyManager
    @Query private var profiles: [BlockedProfiles]
    @Query private var locationProfiles: [LocationProfile]
    
    // MARK: - 状态管理
    @StateObject private var locationManager = LocationManager.shared
    @State private var logMessages: [LogMessage] = []
    
    // MARK: - 流程阶段
    enum ConfigurationStep: Int, CaseIterable {
        case authorization = 0
        case locationSetup = 1
        case appSelection = 2
        case defaultSettings = 3
        case activation = 4
        case testing = 5
        
        var title: String {
            switch self {
            case .authorization: return "权限检查"
            case .locationSetup: return "位置设置"
            case .appSelection: return "App选择"
            case .defaultSettings: return "默认限制"
            case .activation: return "启动监控"
            case .testing: return "模拟测试"
            }
        }
        
        var icon: String {
            switch self {
            case .authorization: return "location.fill.viewfinder"
            case .locationSetup: return "mappin.and.ellipse"
            case .appSelection: return "apps.iphone"
            case .defaultSettings: return "gearshape"
            case .activation: return "play.circle"
            case .testing: return "testtube.2"
            }
        }
    }
    
    @State private var currentStep: ConfigurationStep = .authorization
    
    // MARK: - 位置设置
    @State private var selectedLocationType: LocationPresetType = .office
    @State private var customLocationName = ""
    @State private var geofenceRadius: Double = 100
    @State private var switchDelayMinutes: Int = 1
    
    // MARK: - 位置坐标设置
    @State private var useCurrentLocation = true
    @State private var manualLatitude = ""
    @State private var manualLongitude = ""
    @State private var isRequestingLocation = false
    @State private var locationError: String?
    
    // MARK: - App选择
    @State private var selectedActivity = FamilyActivitySelection()
    @State private var showAppPicker = false
    
    // MARK: - 默认限制设置
    @State private var enableDefaultBlocking = true
    @State private var selectedDefaultProfile: BlockedProfiles?
    @State private var enableNotifications = true
    @State private var autoSwitchEnabled = true
    
    // MARK: - 测试状态
    @State private var simulatedLocation: LocationPresetType?
    @State private var showTestResults = false
    
    // MARK: - 屏蔽状态
    @State private var isBlockingActive = false
    @State private var activeLocationProfile: LocationProfile?
    private let appBlocker = AppBlockerUtil()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 流程步骤指示器
                StepProgressView(
                    steps: ConfigurationStep.allCases.map { ($0.icon, $0.title) },
                    currentStep: currentStep.rawValue
                )
                .padding(.horizontal)
                
                // MARK: - 场景描述
                scenarioDescriptionSection
                
                // MARK: - 依赖组件
                dependenciesSection
                
                // MARK: - Step 1: 权限检查
                authorizationSection
                
                // MARK: - Step 2: 位置设置
                locationSetupSection
                
                // MARK: - Step 3: App选择
                appSelectionSection
                
                // MARK: - Step 4: 默认限制设置
                defaultSettingsSection
                
                // MARK: - Step 5: 启动监控
                activationSection
                
                // MARK: - Step 6: 模拟器测试
                testingSection
                
                // MARK: - 测试用例说明
                testCasesSection
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
            }
            .padding()
        }
        .navigationTitle("地理位置组配置")
        .background(Color(.systemGroupedBackground))
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: $selectedActivity
        )
        .onChange(of: selectedActivity) { _, newValue in
            let count = FamilyActivityUtil.countSelectedActivities(newValue)
            addLog("📱 已选择 \(count) 个App", type: .info)
        }
        .onAppear {
            addLog("📍 地理位置场景已加载", type: .info)
            checkInitialAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: .locationDidChange)) { notification in
            handleLocationChange(notification)
        }
        // 监听位置更新，检查是否在已配置的地理围栏内
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                checkLocationAgainstGeofences(location)
            }
        }
    }
    
    // MARK: - 场景描述
    private var scenarioDescriptionSection: some View {
        DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
            VStack(alignment: .leading, spacing: 12) {
                Text("**地理位置组配置**根据用户所在地理位置自动应用不同的屏蔽策略，实现智能化的屏幕时间管理。")
                
                Text("**使用场景：**")
                BulletPointView(text: "在家时允许娱乐应用，但限制社交媒体")
                BulletPointView(text: "在学校/图书馆时自动启用严格学习模式")
                BulletPointView(text: "在办公室时屏蔽游戏和短视频应用")
                BulletPointView(text: "在其他位置使用默认或宽松策略")
                
                Text("**完整流程：**")
                BulletPointView(text: "✅ Step 1: 位置权限检查与请求")
                BulletPointView(text: "✅ Step 2: 配置地理围栏位置")
                BulletPointView(text: "✅ Step 3: 选择要屏蔽的App")
                BulletPointView(text: "✅ Step 4: 设置默认限制规则")
                BulletPointView(text: "✅ Step 5: 启动位置监控")
                BulletPointView(text: "✅ Step 6: 模拟器测试验证")
                
                // 状态摘要卡片
                HStack(spacing: 12) {
                    StatusCardView(
                        icon: locationManager.isAuthorized ? "location.fill" : "location.slash",
                        title: "位置权限",
                        value: locationManager.authorizationStatusDescription,
                        color: locationManager.isAuthorized ? .green : .red
                    )
                    
                    StatusCardView(
                        icon: "mappin.circle",
                        title: "监控位置",
                        value: "\(locationProfiles.filter { $0.isEnabled }.count)个",
                        color: .blue
                    )
                    
                    StatusCardView(
                        icon: locationManager.isMonitoring ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash",
                        title: "监控状态",
                        value: locationManager.isMonitoring ? "运行中" : "未启动",
                        color: locationManager.isMonitoring ? .green : .gray
                    )
                }
            }
        }
    }
    
    // MARK: - 依赖组件
    private var dependenciesSection: some View {
        DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
            VStack(alignment: .leading, spacing: 8) {
                DependencyRowView(
                    name: "LocationManager",
                    path: "ZenBound/Utils/LocationManager.swift",
                    description: "位置服务封装 - 权限管理和地理围栏监控"
                )
                DependencyRowView(
                    name: "LocationProfile",
                    path: "ZenBound/Models/LocationProfile.swift",
                    description: "位置配置模型 - 存储位置与屏蔽配置映射"
                )
                DependencyRowView(
                    name: "BlockedProfiles",
                    path: "ZenBound/Models/BlockedProfiles.swift",
                    description: "屏蔽配置 - 每个位置绑定一个配置"
                )
                DependencyRowView(
                    name: "StrategyManager",
                    path: "ZenBound/Utils/StrategyManager.swift",
                    description: "策略管理 - 切换屏蔽会话"
                )
                DependencyRowView(
                    name: "CoreLocation",
                    path: "Apple Framework",
                    description: "位置服务 - CLLocationManager & CLMonitor"
                )
            }
        }
    }
    
    // MARK: - Step 1: 权限检查
    private var authorizationSection: some View {
        DemoSectionView(title: "🔐 Step 1: 位置权限检查", icon: "location.fill.viewfinder") {
            VStack(spacing: 16) {
                // 权限状态显示
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("位置服务")
                            .font(.subheadline.bold())
                        Text(LocationManager.locationServicesEnabled ? "设备已启用" : "设备已禁用")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: LocationManager.locationServicesEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(LocationManager.locationServicesEnabled ? .green : .red)
                        .font(.title2)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 授权状态
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("应用授权状态")
                            .font(.subheadline.bold())
                        Text(locationManager.authorizationStatusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    authorizationStatusBadge
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 精度授权
                if locationManager.isAuthorized {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("位置精度")
                                .font(.subheadline.bold())
                            Text(locationManager.accuracyAuthorization == .fullAccuracy ? "完整精度" : "降低精度")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: locationManager.accuracyAuthorization == .fullAccuracy ? "scope" : "scope")
                            .foregroundColor(locationManager.accuracyAuthorization == .fullAccuracy ? .green : .orange)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // 权限请求按钮
                VStack(spacing: 12) {
                    if !locationManager.isAuthorized {
                        Button {
                            requestLocationPermission()
                        } label: {
                            Label("请求位置权限", systemImage: "location")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if locationManager.isAuthorized && !locationManager.hasAlwaysAuthorization {
                        Button {
                            requestAlwaysPermission()
                        } label: {
                            Label("请求后台位置权限", systemImage: "location.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Text("💡 地理围栏需要\"始终\"权限才能在后台工作")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 权限说明
                DisclosureGroup("📋 权限说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        permissionExplanationRow(
                            title: "使用时允许",
                            description: "App 在前台时可获取位置",
                            recommended: false
                        )
                        permissionExplanationRow(
                            title: "始终允许",
                            description: "支持后台地理围栏监控（推荐）",
                            recommended: true
                        )
                        permissionExplanationRow(
                            title: "完整精度",
                            description: "获取精确位置，提高地理围栏准确性",
                            recommended: true
                        )
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    private var authorizationStatusBadge: some View {
        Group {
            switch locationManager.authorizationStatus {
            case .authorizedAlways:
                Label("始终允许", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            case .authorizedWhenInUse:
                Label("使用时允许", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .denied:
                Label("已拒绝", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            case .restricted:
                Label("受限制", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            case .notDetermined:
                Label("未确定", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundColor(.gray)
            @unknown default:
                Label("未知", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func permissionExplanationRow(title: String, description: String, recommended: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: recommended ? "star.fill" : "circle")
                .font(.caption)
                .foregroundColor(recommended ? .yellow : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.caption.bold())
                    if recommended {
                        Text("推荐")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Step 2: 位置设置
    private var locationSetupSection: some View {
        DemoSectionView(title: "📍 Step 2: 位置设置", icon: "mappin.and.ellipse") {
            VStack(spacing: 16) {
                // 位置类型选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("选择位置类型")
                        .font(.subheadline.bold())
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(LocationPresetType.allCases, id: \.self) { type in
                            LocationTypeButton(
                                type: type,
                                isSelected: selectedLocationType == type,
                                onSelect: {
                                    selectedLocationType = type
                                    geofenceRadius = type.defaultRadius
                                    addLog("📍 选择位置类型: \(type.displayName)", type: .info)
                                }
                            )
                        }
                    }
                }
                
                // 自定义名称（如果选择自定义）
                if selectedLocationType == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("自定义位置名称")
                            .font(.subheadline.bold())
                        TextField("输入位置名称", text: $customLocationName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // MARK: - 位置坐标设置（新增）
                locationCoordinateSection
                
                // 地理围栏半径
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("地理围栏半径", systemImage: "circle.dashed")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(geofenceRadius)) 米")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $geofenceRadius, in: 30...500, step: 10)
                        .onChange(of: geofenceRadius) { _, newValue in
                            addLog("📏 围栏半径设置为 \(Int(newValue)) 米", type: .info)
                        }
                    
                    HStack {
                        Text("30m (精确)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("500m (宽松)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 切换延迟
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("切换延迟", systemImage: "timer")
                            .font(.subheadline)
                        Spacer()
                        Text(switchDelayMinutes == 0 ? "立即" : "\(switchDelayMinutes) 分钟")
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("延迟时间", selection: $switchDelayMinutes) {
                        Text("立即").tag(0)
                        Text("1分钟").tag(1)
                        Text("2分钟").tag(2)
                        Text("5分钟").tag(5)
                        Text("10分钟").tag(10)
                    }
                    .pickerStyle(.segmented)
                    
                    Text("💡 延迟切换可避免短暂进出区域时频繁变动")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 已配置的位置列表
                if !locationProfiles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已配置的位置")
                            .font(.subheadline.bold())
                        
                        ForEach(locationProfiles) { location in
                            ConfiguredLocationRow(
                                location: location,
                                profiles: profiles,
                                onDelete: {
                                    deleteLocationProfile(location)
                                }
                            )
                        }
                    }
                }
                
                // 添加位置按钮
                Button {
                    addNewLocationProfile()
                } label: {
                    Label("保存此位置", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!locationManager.isAuthorized || !hasValidCoordinate)
            }
        }
    }
    
    // MARK: - 位置坐标设置视图（新增）
    private var locationCoordinateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📍 设置位置坐标")
                .font(.subheadline.bold())
            
            Text("选择如何获取【\(selectedLocationType.displayName)】的位置坐标：")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 选择方式
            Picker("坐标来源", selection: $useCurrentLocation) {
                Text("使用当前位置").tag(true)
                Text("手动输入坐标").tag(false)
            }
            .pickerStyle(.segmented)
            
            if useCurrentLocation {
                // 使用当前位置
                currentLocationCard
            } else {
                // 手动输入坐标
                manualCoordinateInput
            }
            
            // 错误提示
            if let error = locationError {
                Text("⚠️ \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var currentLocationCard: some View {
        VStack(spacing: 12) {
            // 当前位置显示
            if let location = locationManager.currentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("当前位置已获取")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Text("纬度: \(String(format: "%.6f", location.coordinate.latitude))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("经度: \(String(format: "%.6f", location.coordinate.longitude))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                // 未获取位置
                HStack {
                    Image(systemName: "location.slash")
                        .foregroundColor(.orange)
                    Text("尚未获取当前位置")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
            
            // 获取位置按钮
            Button {
                requestCurrentLocation()
            } label: {
                HStack {
                    if isRequestingLocation {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.circle")
                    }
                    Text(isRequestingLocation ? "正在获取位置..." : "获取当前位置")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!locationManager.isAuthorized || isRequestingLocation)
            
            Text("💡 点击按钮获取您当前的GPS位置，然后保存为【\(selectedLocationType.displayName)】的地理围栏")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var manualCoordinateInput: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("纬度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("如: 37.3349", text: $manualLatitude)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("经度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("如: -122.0090", text: $manualLongitude)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
            }
            
            // 常用地点快速填入
            Text("📌 快速填入示例坐标:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                QuickCoordinateButton(title: "旧金山", lat: "37.7749", lng: "-122.4194") {
                    manualLatitude = "37.7749"
                    manualLongitude = "-122.4194"
                }
                QuickCoordinateButton(title: "北京", lat: "39.9042", lng: "116.4074") {
                    manualLatitude = "39.9042"
                    manualLongitude = "116.4074"
                }
                QuickCoordinateButton(title: "上海", lat: "31.2304", lng: "121.4737") {
                    manualLatitude = "31.2304"
                    manualLongitude = "121.4737"
                }
            }
            
            Text("💡 您可以从 Google Maps 或 Apple Maps 复制坐标")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 检查是否有有效的坐标
    private var hasValidCoordinate: Bool {
        if useCurrentLocation {
            return locationManager.currentLocation != nil
        } else {
            guard let lat = Double(manualLatitude),
                  let lng = Double(manualLongitude) else {
                return false
            }
            return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180
        }
    }
    
    /// 获取用于保存的坐标
    private var coordinateToSave: CLLocationCoordinate2D? {
        if useCurrentLocation {
            return locationManager.currentLocation?.coordinate
        } else {
            guard let lat = Double(manualLatitude),
                  let lng = Double(manualLongitude) else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }
    
    // MARK: - Step 3: App选择
    private var appSelectionSection: some View {
        DemoSectionView(title: "📱 Step 3: 选择要屏蔽的App", icon: "apps.iphone") {
            VStack(spacing: 16) {
                // 当前选择状态
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已选择的App")
                            .font(.subheadline.bold())
                        Text(FamilyActivityUtil.getCountDisplayText(selectedActivity))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(FamilyActivityUtil.countSelectedActivities(selectedActivity))")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 建议说明
                VStack(alignment: .leading, spacing: 8) {
                    Text("建议屏蔽:")
                        .font(.caption.bold())
                    Text(selectedLocationType.suggestedBlockingDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // 打开选择器按钮
                Button {
                    showAppPicker = true
                    addLog("📱 打开App选择器", type: .info)
                } label: {
                    Label("选择要屏蔽的App", systemImage: "plus.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!locationManager.isAuthorized)
                
                // 快速选择按钮
                HStack(spacing: 12) {
                    QuickSelectButton(title: "社交媒体", icon: "bubble.left.and.bubble.right") {
                        addLog("📱 快速选择: 社交媒体", type: .info)
                        showAppPicker = true
                    }
                    
                    QuickSelectButton(title: "游戏", icon: "gamecontroller") {
                        addLog("📱 快速选择: 游戏", type: .info)
                        showAppPicker = true
                    }
                    
                    QuickSelectButton(title: "短视频", icon: "play.rectangle") {
                        addLog("📱 快速选择: 短视频", type: .info)
                        showAppPicker = true
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: 默认限制设置
    private var defaultSettingsSection: some View {
        DemoSectionView(title: "⚙️ Step 4: 默认限制设置", icon: "gearshape") {
            VStack(spacing: 16) {
                ToggleSettingRow(
                    title: "启用默认限制",
                    subtitle: "离开所有已配置位置时应用默认策略",
                    icon: "shield",
                    isOn: $enableDefaultBlocking
                )
                .onChange(of: enableDefaultBlocking) { _, newValue in
                    addLog("🛡️ 默认限制: \(newValue ? "启用" : "禁用")", type: .info)
                }
                
                if enableDefaultBlocking {
                    // 选择默认配置
                    VStack(alignment: .leading, spacing: 8) {
                        Text("默认屏蔽配置")
                            .font(.subheadline.bold())
                        
                        if profiles.isEmpty {
                            Text("暂无可用配置，请先创建屏蔽配置")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        } else {
                            Menu {
                                Button("无默认配置") {
                                    selectedDefaultProfile = nil
                                    addLog("🛡️ 清除默认配置", type: .info)
                                }
                                Divider()
                                ForEach(profiles) { profile in
                                    Button(profile.name) {
                                        selectedDefaultProfile = profile
                                        addLog("🛡️ 设置默认配置: \(profile.name)", type: .success)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedDefaultProfile?.name ?? "选择配置")
                                        .foregroundColor(selectedDefaultProfile != nil ? .primary : .secondary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                
                ToggleSettingRow(
                    title: "位置切换通知",
                    subtitle: "进入/离开位置时发送通知",
                    icon: "bell.badge",
                    isOn: $enableNotifications
                )
                .onChange(of: enableNotifications) { _, newValue in
                    addLog("🔔 切换通知: \(newValue ? "启用" : "禁用")", type: .info)
                }
                
                ToggleSettingRow(
                    title: "自动切换策略",
                    subtitle: "检测到位置变化时自动应用对应配置",
                    icon: "arrow.triangle.swap",
                    isOn: $autoSwitchEnabled
                )
                .onChange(of: autoSwitchEnabled) { _, newValue in
                    addLog("🔄 自动切换: \(newValue ? "启用" : "禁用")", type: .info)
                }
            }
        }
    }
    
    // MARK: - Step 5: 启动监控
    private var activationSection: some View {
        DemoSectionView(title: "▶️ Step 5: 启动位置监控", icon: "play.circle") {
            VStack(spacing: 16) {
                // 监控状态
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("监控状态")
                            .font(.subheadline.bold())
                        Text(locationManager.isMonitoring ? "运行中" : "未启动")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if locationManager.isMonitoring {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("监控中")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(locationManager.isMonitoring ? Color.green.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(10)
                
                // 屏蔽状态
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("屏蔽状态")
                            .font(.subheadline.bold())
                        if isBlockingActive, let activeProfile = activeLocationProfile {
                            Text("激活于: \(activeProfile.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("未激活")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isBlockingActive {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.fill")
                                .font(.caption)
                            Text("屏蔽中")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(isBlockingActive ? Color.red.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(10)
                
                // 当前位置
                if let currentRegion = locationManager.currentRegionIdentifier {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("当前位于: \(currentRegion)")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // 已注册的地理围栏
                if !locationManager.registeredRegions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已注册地理围栏: \(locationManager.registeredRegions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(Array(locationManager.registeredRegions.keys), id: \.self) { key in
                            if let region = locationManager.registeredRegions[key] {
                                HStack {
                                    Image(systemName: "mappin.circle")
                                        .foregroundColor(.blue)
                                    Text(key)
                                        .font(.caption)
                                    Spacer()
                                    Text("\(Int(region.radius))m")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // 启动/停止按钮
                HStack(spacing: 12) {
                    Button {
                        startLocationMonitoring()
                    } label: {
                        Label("启动监控", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(locationManager.isMonitoring || !locationManager.isAuthorized)
                    
                    Button {
                        stopLocationMonitoring()
                    } label: {
                        Label("停止监控", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!locationManager.isMonitoring)
                }
                
                // 检查条件
                if !locationManager.isAuthorized {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("请先完成位置权限授权")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Step 6: 模拟器测试
    private var testingSection: some View {
        DemoSectionView(title: "🧪 Step 6: 模拟器测试", icon: "testtube.2") {
            VStack(spacing: 16) {
                // 测试说明
                VStack(alignment: .leading, spacing: 8) {
                    Text("模拟器测试说明")
                        .font(.subheadline.bold())
                    
                    Text("由于 iOS 模拟器不支持真实 GPS，可以使用以下方法测试：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    BulletPointView(text: "Xcode → Debug → Simulate Location")
                    BulletPointView(text: "使用下方按钮模拟位置变化")
                    BulletPointView(text: "创建 GPX 文件模拟移动轨迹")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // 模拟位置按钮
                VStack(alignment: .leading, spacing: 8) {
                    Text("模拟进入位置")
                        .font(.subheadline.bold())
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(LocationPresetType.allCases.filter { $0 != .custom }, id: \.self) { type in
                            SimulateLocationButton(
                                type: type,
                                isActive: simulatedLocation == type,
                                onTap: {
                                    simulateEnterLocation(type)
                                }
                            )
                        }
                    }
                    
                    Button {
                        simulateLeaveAllLocations()
                    } label: {
                        Label("模拟离开所有位置", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                
                // 最近事件
                if !locationManager.recentEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近位置事件")
                            .font(.subheadline.bold())
                        
                        ForEach(locationManager.recentEvents.prefix(5)) { event in
                            HStack {
                                Text(event.formattedTime)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.tertiary)
                                
                                Image(systemName: eventIcon(for: event.type))
                                    .font(.caption)
                                    .foregroundColor(eventColor(for: event))
                                
                                Text(event.description)
                                    .font(.caption)
                                    .foregroundColor(eventColor(for: event))
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - 测试用例说明
    private var testCasesSection: some View {
        DemoSectionView(title: "📋 测试用例说明", icon: "checklist") {
            VStack(alignment: .leading, spacing: 16) {
                TestCaseRow(
                    number: 1,
                    title: "权限请求测试",
                    steps: [
                        "点击\"请求位置权限\"按钮",
                        "系统弹出权限对话框",
                        "选择\"使用App时允许\"或\"始终允许\"",
                        "验证权限状态更新"
                    ],
                    expectedResult: "权限状态显示\"使用时允许\"或\"始终允许\""
                )
                
                TestCaseRow(
                    number: 2,
                    title: "地理围栏注册测试",
                    steps: [
                        "选择位置类型（如\"办公室\"）",
                        "设置地理围栏半径",
                        "点击\"添加当前位置类型\"",
                        "检查已注册围栏列表"
                    ],
                    expectedResult: "位置出现在已配置列表中，日志显示注册成功"
                )
                
                TestCaseRow(
                    number: 3,
                    title: "位置监控启动测试",
                    steps: [
                        "确保至少有一个位置配置",
                        "点击\"启动监控\"按钮",
                        "检查监控状态"
                    ],
                    expectedResult: "状态显示\"运行中\"，绿色指示灯亮起"
                )
                
                TestCaseRow(
                    number: 4,
                    title: "模拟位置变化测试",
                    steps: [
                        "启动位置监控",
                        "点击模拟位置按钮（如\"办公室\"）",
                        "检查日志和当前位置显示",
                        "点击\"模拟离开所有位置\""
                    ],
                    expectedResult: "日志显示进入/离开事件，当前位置正确更新"
                )
                
                TestCaseRow(
                    number: 5,
                    title: "Xcode 位置模拟测试",
                    steps: [
                        "在模拟器运行App",
                        "Xcode菜单 → Debug → Simulate Location",
                        "选择预设位置或自定义坐标",
                        "观察App响应"
                    ],
                    expectedResult: "App检测到位置变化并触发相应事件"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addLog(_ message: String, type: LogType) {
        withAnimation {
            logMessages.insert(LogMessage(message: message, type: type), at: 0)
            if logMessages.count > 30 {
                logMessages.removeLast()
            }
        }
    }
    
    private func checkInitialAuthorization() {
        if locationManager.isAuthorized {
            addLog("✅ 位置权限已授权: \(locationManager.authorizationStatusDescription)", type: .success)
            currentStep = .locationSetup
        } else {
            addLog("⚠️ 需要位置权限才能使用地理围栏功能", type: .warning)
        }
    }
    
    private func requestLocationPermission() {
        addLog("📍 请求位置权限...", type: .info)
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func requestAlwaysPermission() {
        addLog("📍 请求后台位置权限...", type: .info)
        locationManager.requestAlwaysAuthorization()
    }
    
    private func requestCurrentLocation() {
        isRequestingLocation = true
        locationError = nil
        addLog("📍 正在获取当前位置...", type: .info)
        locationManager.requestLocation()
        
        // 设置超时
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isRequestingLocation {
                self.isRequestingLocation = false
                if self.locationManager.currentLocation == nil {
                    self.locationError = "获取位置超时，请确保已开启定位服务"
                    self.addLog("❌ 获取位置超时", type: .error)
                }
            }
        }
        
        // 监听位置更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.locationManager.currentLocation != nil {
                self.isRequestingLocation = false
                self.addLog("✅ 已获取当前位置", type: .success)
            }
        }
    }
    
    private func addNewLocationProfile() {
        let name = selectedLocationType == .custom 
            ? (customLocationName.isEmpty ? "自定义位置" : customLocationName)
            : selectedLocationType.displayName
        
        // 获取用户设置的坐标
        guard let coordinate = coordinateToSave else {
            locationError = "请先设置有效的位置坐标"
            addLog("❌ 无效的坐标，请先获取位置或输入坐标", type: .error)
            return
        }
        
        let profile = LocationProfile.create(
            in: modelContext,
            name: name,
            coordinate: coordinate,
            radius: geofenceRadius,
            blockedProfileId: nil,
            locationType: selectedLocationType
        )
        
        // 注册地理围栏
        locationManager.registerGeofence(
            identifier: profile.geofenceIdentifier,
            coordinate: coordinate,
            radius: geofenceRadius
        )
        
        addLog("✅ 已添加位置: \(name)", type: .success)
        addLog("📍 坐标: (\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))), 半径: \(Int(geofenceRadius))m", type: .info)
        
        // 重置输入
        manualLatitude = ""
        manualLongitude = ""
        locationError = nil
        
        if currentStep == .locationSetup {
            currentStep = .appSelection
        }
    }
    
    private func deleteLocationProfile(_ profile: LocationProfile) {
        locationManager.unregisterGeofence(identifier: profile.geofenceIdentifier)
        LocationProfile.delete(profile, in: modelContext)
        addLog("🗑️ 已删除位置: \(profile.name)", type: .info)
    }
    
    private func startLocationMonitoring() {
        let enabledProfiles = locationProfiles.filter({ $0.isEnabled })
        
        addLog("🚀 开始启动位置监控...", type: .info)
        addLog("📋 共有 \(enabledProfiles.count) 个启用的位置配置", type: .info)
        
        // 注册所有启用的位置围栏
        for profile in enabledProfiles {
            addLog("   → 注册围栏: \(profile.name) (\(String(format: "%.4f", profile.latitude)), \(String(format: "%.4f", profile.longitude))) 半径: \(Int(profile.radius))m", type: .info)
            locationManager.registerGeofence(
                identifier: profile.geofenceIdentifier,
                coordinate: profile.coordinate,
                radius: profile.radius
            )
        }
        
        locationManager.startMonitoring()
        addLog("✅ 位置监控已启动", type: .success)
        currentStep = .testing
        
        // 立即检查当前位置是否在任何地理围栏内
        if let currentLocation = locationManager.currentLocation {
            addLog("📍 立即检查当前位置...", type: .info)
            checkLocationAgainstGeofences(currentLocation)
        } else {
            addLog("⚠️ 当前位置未知，请求位置更新...", type: .warning)
            locationManager.requestLocation()
        }
    }
    
    private func stopLocationMonitoring() {
        locationManager.stopMonitoring()
        deactivateBlocking()
        addLog("⏹️ 位置监控已停止", type: .info)
    }
    
    private func simulateEnterLocation(_ type: LocationPresetType) {
        let identifier = "zenbound_\(type.rawValue)"
        simulatedLocation = type
        locationManager.simulateLocationChange(regionIdentifier: identifier, eventType: .enter)
        addLog("🧪 [模拟] 进入位置: \(type.displayName)", type: .success)
    }
    
    private func simulateLeaveAllLocations() {
        simulatedLocation = nil
        locationManager.simulateLocationChange(regionIdentifier: nil, eventType: .exit)
        addLog("🧪 [模拟] 离开所有位置", type: .info)
    }
    
    private func getSimulatedCoordinate(for type: LocationPresetType) -> CLLocationCoordinate2D {
        // 使用 Apple Park 附近的模拟坐标
        switch type {
        case .home:
            return CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        case .office:
            return CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0307)
        case .school:
            return CLLocationCoordinate2D(latitude: 37.3387, longitude: -122.0411)
        case .library:
            return CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0322)
        case .gym:
            return CLLocationCoordinate2D(latitude: 37.3270, longitude: -122.0250)
        case .cafe:
            return CLLocationCoordinate2D(latitude: 37.3300, longitude: -122.0280)
        case .custom:
            return CLLocationCoordinate2D(latitude: 37.3350, longitude: -122.0350)
        }
    }
    
    private func eventIcon(for type: LocationEventType) -> String {
        switch type {
        case .enter: return "arrow.down.circle.fill"
        case .exit: return "arrow.up.circle.fill"
        case .locationUpdate: return "location.fill"
        case .log: return "doc.text"
        }
    }
    
    private func eventColor(for event: LocationEvent) -> Color {
        if event.type == .log {
            switch event.logType {
            case .info: return .secondary
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        switch event.type {
        case .enter: return .green
        case .exit: return .orange
        case .locationUpdate: return .blue
        case .log: return .secondary
        }
    }
    
    // MARK: - 位置变化处理
    
    /// 处理位置变化通知（进入/离开地理围栏）
    private func handleLocationChange(_ notification: Notification) {
        guard let event = notification.object as? LocationEvent else {
            addLog("⚠️ 收到位置通知但无法解析事件", type: .warning)
            return
        }
        
        addLog("📍 收到位置变化通知: \(event.type.rawValue) - \(event.regionIdentifier ?? "无区域")", type: .info)
        
        switch event.type {
        case .enter:
            handleEnterRegion(event)
        case .exit:
            handleExitRegion(event)
        default:
            break
        }
    }
    
    /// 手动检查当前位置是否在任何已配置的地理围栏内
    private func checkLocationAgainstGeofences(_ location: CLLocation) {
        let enabledProfiles = locationProfiles.filter { $0.isEnabled }
        
        addLog("🔍 检查当前位置: (\(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)))", type: .info)
        addLog("📋 已启用的位置配置: \(enabledProfiles.count) 个", type: .info)
        
        for profile in enabledProfiles {
            let profileLocation = CLLocation(latitude: profile.latitude, longitude: profile.longitude)
            let distance = location.distance(from: profileLocation)
            
            addLog("   → \(profile.name): 距离 \(String(format: "%.1f", distance))m, 围栏半径 \(Int(profile.radius))m", type: .info)
            
            if distance <= profile.radius {
                addLog("   ✅ 当前位于【\(profile.name)】范围内!", type: .success)
                
                // 如果还没有激活屏蔽，或者是不同的位置，则激活
                if !isBlockingActive || activeLocationProfile?.id != profile.id {
                    activateBlockingForLocation(profile)
                }
                return // 找到一个匹配的就返回
            }
        }
        
        // 如果不在任何地理围栏内，且屏蔽是激活的，则停用
        if isBlockingActive {
            addLog("📍 当前不在任何已配置的地理围栏内，停用屏蔽", type: .info)
            deactivateBlocking()
        }
    }
    
    /// 处理进入区域事件
    private func handleEnterRegion(_ event: LocationEvent) {
        guard let regionId = event.regionIdentifier else { return }
        
        addLog("🚶‍♂️ 进入地理围栏: \(regionId)", type: .success)
        
        // 查找对应的 LocationProfile
        if let profile = LocationProfile.find(byGeofenceId: regionId, in: modelContext) {
            addLog("   → 匹配到位置配置: \(profile.name)", type: .info)
            activateBlockingForLocation(profile)
        } else {
            addLog("   ⚠️ 未找到匹配的位置配置", type: .warning)
        }
    }
    
    /// 处理离开区域事件
    private func handleExitRegion(_ event: LocationEvent) {
        guard let regionId = event.regionIdentifier else { return }
        
        addLog("🚶 离开地理围栏: \(regionId)", type: .info)
        
        // 如果离开的是当前激活屏蔽的位置，则停用屏蔽
        if let activeProfile = activeLocationProfile,
           activeProfile.geofenceIdentifier == regionId {
            addLog("   → 离开当前激活的位置，停用屏蔽", type: .info)
            deactivateBlocking()
        }
    }
    
    /// 为指定位置激活屏蔽
    private func activateBlockingForLocation(_ profile: LocationProfile) {
        addLog("🔒 准备为位置【\(profile.name)】激活屏蔽...", type: .info)
        
        // 检查位置是否有关联的屏蔽配置
        if let blockedProfileId = profile.blockedProfileId {
            addLog("   → 查找关联的屏蔽配置 ID: \(blockedProfileId)", type: .info)
            
            // 查找关联的 BlockedProfiles
            if let blockedProfile = profiles.first(where: { $0.id == blockedProfileId }) {
                addLog("   → 找到屏蔽配置: \(blockedProfile.name)", type: .success)
                
                // 获取快照并激活屏蔽
                let snapshot = BlockedProfiles.getSnapshot(for: blockedProfile)
                appBlocker.activateRestrictions(for: snapshot)
                
                isBlockingActive = true
                activeLocationProfile = profile
                
                addLog("✅ 屏蔽已激活! 位置: \(profile.name), 配置: \(blockedProfile.name)", type: .success)
            } else {
                addLog("   ❌ 未找到关联的屏蔽配置", type: .error)
            }
        } else {
            addLog("   ⚠️ 该位置未关联屏蔽配置，使用默认 App 选择", type: .warning)
            
            // 如果没有关联屏蔽配置，但选择了 App，则直接使用选择的 App
            if FamilyActivityUtil.countSelectedActivities(selectedActivity) > 0 {
                addLog("   → 使用已选择的 \(FamilyActivityUtil.countSelectedActivities(selectedActivity)) 个 App", type: .info)
                
                // 创建临时快照
                let tempSnapshot = SharedData.ProfileSnapshot(
                    id: UUID(),
                    name: profile.name,
                    selectedActivity: selectedActivity,
                    createdAt: Date(),
                    updatedAt: Date(),
                    order: 0,
                    enableLiveActivity: false,
                    enableBreaks: false,
                    enableStrictMode: false,
                    enableAllowMode: false,
                    enableAllowModeDomains: false,
                    enableSafariBlocking: false
                )
                
                appBlocker.activateRestrictions(for: tempSnapshot)
                isBlockingActive = true
                activeLocationProfile = profile
                
                addLog("✅ 屏蔽已激活! 位置: \(profile.name)", type: .success)
            } else {
                addLog("   ❌ 没有选择要屏蔽的 App", type: .error)
            }
        }
    }
    
    /// 停用屏蔽
    private func deactivateBlocking() {
        guard isBlockingActive else { return }
        
        appBlocker.deactivateRestrictions()
        
        let previousLocation = activeLocationProfile?.name ?? "未知"
        isBlockingActive = false
        activeLocationProfile = nil
        
        addLog("🔓 屏蔽已停用 (之前位置: \(previousLocation))", type: .info)
    }
}

// MARK: - Supporting Views

struct LocationTypeButton: View {
    let type: LocationPresetType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : colorForType(type))
                Text(type.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? colorForType(type) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? colorForType(type) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func colorForType(_ type: LocationPresetType) -> Color {
        switch type.color {
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return .brown
        case "green": return .green
        case "red": return .red
        default: return .gray
        }
    }
}

struct ConfiguredLocationRow: View {
    let location: LocationProfile
    let profiles: [BlockedProfiles]
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: location.preset.icon)
                .foregroundColor(colorForPreset(location.preset))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.subheadline)
                Text("📍 (\(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("半径: \(Int(location.radius))m")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(location.isEnabled))
                .labelsHidden()
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func colorForPreset(_ preset: LocationPresetType) -> Color {
        switch preset.color {
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return .brown
        case "green": return .green
        case "red": return .red
        default: return .gray
        }
    }
}

struct QuickSelectButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct SimulateLocationButton: View {
    let type: LocationPresetType
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: type.icon)
                Text(type.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.green : Color(.systemGray6))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TestCaseRow: View {
    let number: Int
    let title: String
    let steps: [String]
    let expectedResult: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("TC-\(number)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                    
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("步骤:")
                        .font(.caption.bold())
                    
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(step)
                                .font(.caption)
                        }
                    }
                    
                    Divider()
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("预期结果:")
                            .font(.caption.bold())
                        Text(expectedResult)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

/// 快速坐标填入按钮
struct QuickCoordinateButton: View {
    let title: String
    let lat: String
    let lng: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2.bold())
                Text("\(lat), \(lng)")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LocationBasedScenarioView()
            .modelContainer(for: [BlockedProfiles.self, LocationProfile.self])
            .environmentObject(StrategyManager.shared)
    }
}
