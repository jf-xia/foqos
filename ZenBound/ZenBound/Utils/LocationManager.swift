import CoreLocation
import Combine
import Foundation

// MARK: - Notification Name Extension
extension Notification.Name {
    static let locationDidChange = Notification.Name("zenbound.locationDidChange")
}

/**
 # 位置管理器 (Location Manager)
 
 ## 1️⃣ 作用与核心功能
 
 封装 CoreLocation 框架，为应用提供统一的位置服务管理。主要功能包括:
 
 ### 输入 → 处理 → 输出示例:
 
 - **权限请求**: 调用 `requestAuthorization()` → 显示系统权限弹窗 → 更新 `authorizationStatus`
 - **位置监控**: 注册地理围栏 → 检测用户进入/离开区域 → 发送 `locationDidChange` 通知
 - **当前位置**: 调用 `getCurrentLocation()` → 返回 CLLocation 坐标
 
 ---
 
 ## 2️⃣ 项目内用法
 
 ### 🎯 用法 1: 检查和请求位置权限
 ```swift
 let locationManager = LocationManager.shared
 
 // 检查当前状态
 if locationManager.authorizationStatus == .notDetermined {
     locationManager.requestWhenInUseAuthorization()
 }
 ```
 
 ### 🎯 用法 2: 注册地理围栏
 ```swift
 locationManager.registerGeofence(
     identifier: "office",
     coordinate: CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0307),
     radius: 100
 )
 ```
 
 ### 🎯 用法 3: 监听位置变化
 ```swift
 NotificationCenter.default.addObserver(
     forName: .locationDidChange,
     object: nil,
     queue: .main
 ) { notification in
     if let event = notification.object as? LocationEvent {
         // 处理位置变化
     }
 }
 ```
 
 ---
 
 ## 3️⃣ iOS 模拟器测试说明
 
 由于 CoreLocation 在模拟器上有限制，以下功能需要特殊处理:
 
 - **权限请求**: 模拟器可正常弹出权限对话框
 - **位置模拟**: Xcode → Debug → Simulate Location
 - **地理围栏**: 模拟器支持有限，建议使用 GPX 文件模拟移动
 
 本类提供 `simulateLocationChange()` 方法用于模拟器测试。
 */
@MainActor
final class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    
    /// 当前授权状态
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// 精度授权
    @Published private(set) var accuracyAuthorization: CLAccuracyAuthorization = .reducedAccuracy
    
    /// 当前所在区域ID（如果在已注册的地理围栏内）
    @Published private(set) var currentRegionIdentifier: String?
    
    /// 当前位置
    @Published private(set) var currentLocation: CLLocation?
    
    /// 是否正在监控位置
    @Published private(set) var isMonitoring = false
    
    /// 已注册的地理围栏
    @Published private(set) var registeredRegions: [String: CLCircularRegion] = [:]
    
    /// 最近的位置事件
    @Published private(set) var recentEvents: [LocationEvent] = []
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private let maxEventHistory = 20
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10米更新一次
        
        // 读取初始状态
        updateAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// 检查是否已获得位置授权
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    /// 检查是否有"始终"位置权限（地理围栏后台监控需要）
    var hasAlwaysAuthorization: Bool {
        authorizationStatus == .authorizedAlways
    }
    
    /// 请求"使用时"位置权限
    func requestWhenInUseAuthorization() {
        logEvent("📍 请求'使用时'位置权限", type: .info)
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 请求"始终"位置权限（用于后台地理围栏）
    func requestAlwaysAuthorization() {
        logEvent("📍 请求'始终'位置权限", type: .info)
        locationManager.requestAlwaysAuthorization()
    }
    
    /// 检查位置服务是否在设备上启用
    static var locationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// 获取授权状态的描述文本
    var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "未确定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终允许"
        case .authorizedWhenInUse:
            return "使用时允许"
        @unknown default:
            return "未知"
        }
    }
    
    // MARK: - Location Updates
    
    /// 开始持续位置更新
    func startUpdatingLocation() {
        guard isAuthorized else {
            logEvent("❌ 无法开始位置更新: 未授权", type: .error)
            return
        }
        
        logEvent("🚀 开始位置更新", type: .success)
        locationManager.startUpdatingLocation()
    }
    
    /// 停止位置更新
    func stopUpdatingLocation() {
        logEvent("⏹️ 停止位置更新", type: .info)
        locationManager.stopUpdatingLocation()
    }
    
    /// 请求单次位置更新
    func requestLocation() {
        guard isAuthorized else {
            logEvent("❌ 无法请求位置: 未授权", type: .error)
            return
        }
        
        logEvent("📍 请求当前位置", type: .info)
        locationManager.requestLocation()
    }
    
    // MARK: - Geofencing
    
    /// 注册地理围栏
    /// - Parameters:
    ///   - identifier: 唯一标识符
    ///   - coordinate: 中心坐标
    ///   - radius: 半径（米），最大值由系统限制
    ///   - notifyOnEntry: 进入时通知
    ///   - notifyOnExit: 离开时通知
    func registerGeofence(
        identifier: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = true
    ) {
        // 检查是否支持区域监控
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            logEvent("❌ 设备不支持区域监控", type: .error)
            return
        }
        
        // 限制半径
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        
        let region = CLCircularRegion(
            center: coordinate,
            radius: clampedRadius,
            identifier: identifier
        )
        region.notifyOnEntry = notifyOnEntry
        region.notifyOnExit = notifyOnExit
        
        // 保存并开始监控
        registeredRegions[identifier] = region
        locationManager.startMonitoring(for: region)
        
        logEvent("📍 注册地理围栏: \(identifier) (半径: \(Int(clampedRadius))m)", type: .success)
    }
    
    /// 取消注册地理围栏
    func unregisterGeofence(identifier: String) {
        guard let region = registeredRegions[identifier] else {
            logEvent("⚠️ 未找到地理围栏: \(identifier)", type: .warning)
            return
        }
        
        locationManager.stopMonitoring(for: region)
        registeredRegions.removeValue(forKey: identifier)
        
        logEvent("🗑️ 取消地理围栏: \(identifier)", type: .info)
    }
    
    /// 取消所有地理围栏
    func unregisterAllGeofences() {
        for region in registeredRegions.values {
            locationManager.stopMonitoring(for: region)
        }
        registeredRegions.removeAll()
        logEvent("🗑️ 已取消所有地理围栏", type: .info)
    }
    
    /// 请求某个区域的当前状态
    func requestState(for identifier: String) {
        guard let region = registeredRegions[identifier] else {
            logEvent("⚠️ 未找到地理围栏: \(identifier)", type: .warning)
            return
        }
        
        locationManager.requestState(for: region)
    }
    
    // MARK: - Monitoring Control
    
    /// 启动位置监控（含地理围栏）
    func startMonitoring() {
        guard isAuthorized else {
            logEvent("❌ 无法启动监控: 未授权", type: .error)
            return
        }
        
        isMonitoring = true
        startUpdatingLocation()
        
        // 请求所有已注册区域的状态
        for region in registeredRegions.values {
            locationManager.requestState(for: region)
        }
        
        logEvent("🚀 位置监控已启动 (\(registeredRegions.count) 个地理围栏)", type: .success)
    }
    
    /// 停止位置监控
    func stopMonitoring() {
        isMonitoring = false
        stopUpdatingLocation()
        currentRegionIdentifier = nil
        
        logEvent("⏹️ 位置监控已停止", type: .info)
    }
    
    // MARK: - Simulator Testing Support
    
    /// 模拟位置变化（仅用于测试）
    /// - Parameters:
    ///   - regionIdentifier: 模拟进入的区域ID，nil表示离开所有区域
    ///   - eventType: 事件类型
    func simulateLocationChange(regionIdentifier: String?, eventType: LocationEventType) {
        #if DEBUG
        logEvent("🧪 [模拟] 位置变化: \(regionIdentifier ?? "离开所有区域")", type: .info)
        
        if let identifier = regionIdentifier {
            currentRegionIdentifier = identifier
            let event = LocationEvent(
                type: eventType,
                regionIdentifier: identifier,
                coordinate: registeredRegions[identifier]?.center,
                timestamp: Date()
            )
            addEvent(event)
            
            // 发送通知
            NotificationCenter.default.post(
                name: .locationDidChange,
                object: event
            )
        } else {
            if let previousRegion = currentRegionIdentifier {
                let event = LocationEvent(
                    type: .exit,
                    regionIdentifier: previousRegion,
                    coordinate: nil,
                    timestamp: Date()
                )
                addEvent(event)
                currentRegionIdentifier = nil
                
                NotificationCenter.default.post(
                    name: .locationDidChange,
                    object: event
                )
            }
        }
        #endif
    }
    
    /// 模拟设置当前位置
    func simulateLocation(latitude: Double, longitude: Double) {
        #if DEBUG
        let location = CLLocation(latitude: latitude, longitude: longitude)
        currentLocation = location
        logEvent("🧪 [模拟] 当前位置: (\(latitude), \(longitude))", type: .info)
        #endif
    }
    
    // MARK: - Private Helpers
    
    private func updateAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        accuracyAuthorization = locationManager.accuracyAuthorization
    }
    
    private func addEvent(_ event: LocationEvent) {
        recentEvents.insert(event, at: 0)
        if recentEvents.count > maxEventHistory {
            recentEvents.removeLast()
        }
    }
    
    private func logEvent(_ message: String, type: LocationEventLogType) {
        let event = LocationEvent(
            type: .log,
            regionIdentifier: nil,
            coordinate: nil,
            timestamp: Date(),
            logMessage: message,
            logType: type
        )
        addEvent(event)
        
        #if DEBUG
        print("[LocationManager] \(message)")
        #endif
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthorizationStatus()
            logEvent("🔐 授权状态变更: \(authorizationStatusDescription)", type: .info)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            
            let event = LocationEvent(
                type: .locationUpdate,
                regionIdentifier: nil,
                coordinate: location.coordinate,
                timestamp: Date()
            )
            addEvent(event)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            logEvent("❌ 位置错误: \(error.localizedDescription)", type: .error)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        Task { @MainActor in
            currentRegionIdentifier = region.identifier
            
            let event = LocationEvent(
                type: .enter,
                regionIdentifier: region.identifier,
                coordinate: circularRegion.center,
                timestamp: Date()
            )
            addEvent(event)
            logEvent("📍 进入区域: \(region.identifier)", type: .success)
            
            // 发送通知
            NotificationCenter.default.post(
                name: .locationDidChange,
                object: event
            )
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            if currentRegionIdentifier == region.identifier {
                currentRegionIdentifier = nil
            }
            
            let event = LocationEvent(
                type: .exit,
                regionIdentifier: region.identifier,
                coordinate: nil,
                timestamp: Date()
            )
            addEvent(event)
            logEvent("📍 离开区域: \(region.identifier)", type: .info)
            
            // 发送通知
            NotificationCenter.default.post(
                name: .locationDidChange,
                object: event
            )
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        Task { @MainActor in
            switch state {
            case .inside:
                currentRegionIdentifier = region.identifier
                logEvent("📍 当前位于区域内: \(region.identifier)", type: .info)
            case .outside:
                if currentRegionIdentifier == region.identifier {
                    currentRegionIdentifier = nil
                }
                logEvent("📍 当前位于区域外: \(region.identifier)", type: .info)
            case .unknown:
                logEvent("📍 区域状态未知: \(region.identifier)", type: .warning)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            let regionName = region?.identifier ?? "unknown"
            logEvent("❌ 区域监控失败 (\(regionName)): \(error.localizedDescription)", type: .error)
        }
    }
}

// MARK: - Supporting Types

/// 位置事件类型
enum LocationEventType: String {
    case enter = "进入"
    case exit = "离开"
    case locationUpdate = "位置更新"
    case log = "日志"
}

/// 日志类型
enum LocationEventLogType {
    case info
    case success
    case warning
    case error
}

/// 位置事件
struct LocationEvent: Identifiable {
    let id = UUID()
    let type: LocationEventType
    let regionIdentifier: String?
    let coordinate: CLLocationCoordinate2D?
    let timestamp: Date
    var logMessage: String?
    var logType: LocationEventLogType = .info
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    var description: String {
        if let message = logMessage {
            return message
        }
        
        if let region = regionIdentifier {
            return "\(type.rawValue) \(region)"
        }
        
        if let coord = coordinate {
            return "位置: (\(String(format: "%.4f", coord.latitude)), \(String(format: "%.4f", coord.longitude)))"
        }
        
        return type.rawValue
    }
}
