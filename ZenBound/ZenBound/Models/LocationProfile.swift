import CoreLocation
import Foundation
import SwiftData

/**
 # 位置配置模型 (Location Profile)
 
 ## 1️⃣ 作用与核心功能
 
 存储地理位置与屏蔽配置的映射关系，用于实现基于位置的自动策略切换。
 
 ### 数据流:
 - 用户设置位置 → 保存 LocationProfile → 注册地理围栏 → 检测位置变化 → 自动切换屏蔽策略
 
 ---
 
 ## 2️⃣ 字段说明
 
 | 字段 | 类型 | 说明 |
 |-----|------|------|
 | id | UUID | 唯一标识符 |
 | name | String | 位置名称（如"家"、"办公室"） |
 | latitude | Double | 纬度 |
 | longitude | Double | 经度 |
 | radius | Double | 地理围栏半径（米） |
 | blockedProfileId | UUID? | 关联的屏蔽配置ID |
 | isEnabled | Bool | 是否启用此位置 |
 | createdAt | Date | 创建时间 |
 | updatedAt | Date | 更新时间 |
 | notifyOnEnter | Bool | 进入时通知 |
 | notifyOnExit | Bool | 离开时通知 |
 | switchDelaySeconds | Int | 切换延迟（秒） |
 
 ---
 
 ## 3️⃣ 预设位置类型
 
 提供常用位置预设，方便用户快速配置:
 - 家
 - 办公室
 - 学校
 - 图书馆
 - 健身房
 - 自定义
 */
@Model
final class LocationProfile {
    
    // MARK: - Properties
    
    /// 唯一标识符
    var id: UUID
    
    /// 位置名称
    var name: String
    
    /// 纬度
    var latitude: Double
    
    /// 经度
    var longitude: Double
    
    /// 地理围栏半径（米）
    var radius: Double
    
    /// 关联的屏蔽配置ID
    var blockedProfileId: UUID?
    
    /// 是否启用
    var isEnabled: Bool
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 进入时通知
    var notifyOnEnter: Bool
    
    /// 离开时通知
    var notifyOnExit: Bool
    
    /// 切换延迟（秒）
    var switchDelaySeconds: Int
    
    /// 位置类型（用于图标和颜色）
    var locationType: String
    
    /// 排序顺序
    var order: Int
    
    // MARK: - Computed Properties
    
    /// 获取坐标对象
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// 获取位置预设类型
    var preset: LocationPresetType {
        LocationPresetType(rawValue: locationType) ?? .custom
    }
    
    /// 地理围栏标识符
    var geofenceIdentifier: String {
        "zenbound_location_\(id.uuidString)"
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double = 100,
        blockedProfileId: UUID? = nil,
        locationType: LocationPresetType = .custom,
        notifyOnEnter: Bool = true,
        notifyOnExit: Bool = true,
        switchDelaySeconds: Int = 60,
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.radius = radius
        self.blockedProfileId = blockedProfileId
        self.isEnabled = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notifyOnEnter = notifyOnEnter
        self.notifyOnExit = notifyOnExit
        self.switchDelaySeconds = switchDelaySeconds
        self.locationType = locationType.rawValue
        self.order = order
    }
    
    // MARK: - Static Methods
    
    /// 获取所有位置配置
    static func fetchAll(in context: ModelContext) -> [LocationProfile] {
        let descriptor = FetchDescriptor<LocationProfile>(
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// 根据ID查找位置配置
    static func find(byId id: UUID, in context: ModelContext) -> LocationProfile? {
        let descriptor = FetchDescriptor<LocationProfile>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }
    
    /// 根据地理围栏标识符查找
    static func find(byGeofenceId geofenceId: String, in context: ModelContext) -> LocationProfile? {
        // 从 geofenceId 提取 UUID
        let prefix = "zenbound_location_"
        guard geofenceId.hasPrefix(prefix),
              let uuid = UUID(uuidString: String(geofenceId.dropFirst(prefix.count))) else {
            return nil
        }
        return find(byId: uuid, in: context)
    }
    
    /// 创建新位置配置
    @discardableResult
    static func create(
        in context: ModelContext,
        name: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double = 100,
        blockedProfileId: UUID? = nil,
        locationType: LocationPresetType = .custom
    ) -> LocationProfile {
        let nextOrder = getNextOrder(in: context)
        let profile = LocationProfile(
            name: name,
            coordinate: coordinate,
            radius: radius,
            blockedProfileId: blockedProfileId,
            locationType: locationType,
            order: nextOrder
        )
        context.insert(profile)
        try? context.save()
        return profile
    }
    
    /// 更新位置配置
    func update(
        name: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        radius: Double? = nil,
        blockedProfileId: UUID?? = nil,
        isEnabled: Bool? = nil,
        notifyOnEnter: Bool? = nil,
        notifyOnExit: Bool? = nil,
        switchDelaySeconds: Int? = nil
    ) {
        if let name = name { self.name = name }
        if let coord = coordinate {
            self.latitude = coord.latitude
            self.longitude = coord.longitude
        }
        if let radius = radius { self.radius = radius }
        if let profileId = blockedProfileId { self.blockedProfileId = profileId }
        if let enabled = isEnabled { self.isEnabled = enabled }
        if let onEnter = notifyOnEnter { self.notifyOnEnter = onEnter }
        if let onExit = notifyOnExit { self.notifyOnExit = onExit }
        if let delay = switchDelaySeconds { self.switchDelaySeconds = delay }
        
        self.updatedAt = Date()
    }
    
    /// 删除位置配置
    static func delete(_ profile: LocationProfile, in context: ModelContext) {
        context.delete(profile)
        try? context.save()
    }
    
    /// 获取下一个排序顺序值
    static func getNextOrder(in context: ModelContext) -> Int {
        let profiles = fetchAll(in: context)
        return (profiles.map { $0.order }.max() ?? -1) + 1
    }
    
    /// 重新排序位置配置
    static func reorder(_ profiles: [LocationProfile], in context: ModelContext) {
        for (index, profile) in profiles.enumerated() {
            profile.order = index
            profile.updatedAt = Date()
        }
        try? context.save()
    }
    
    /// 获取所有启用的位置配置
    static func fetchEnabled(in context: ModelContext) -> [LocationProfile] {
        let descriptor = FetchDescriptor<LocationProfile>(
            predicate: #Predicate { $0.isEnabled },
            sortBy: [SortDescriptor(\.order, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}

// MARK: - Location Preset Type

/// 位置预设类型
enum LocationPresetType: String, CaseIterable, Codable {
    case home = "home"
    case office = "office"
    case school = "school"
    case library = "library"
    case gym = "gym"
    case cafe = "cafe"
    case custom = "custom"
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .home: return "家"
        case .office: return "办公室"
        case .school: return "学校"
        case .library: return "图书馆"
        case .gym: return "健身房"
        case .cafe: return "咖啡厅"
        case .custom: return "自定义"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .office: return "building.2.fill"
        case .school: return "graduationcap.fill"
        case .library: return "books.vertical.fill"
        case .gym: return "dumbbell.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .custom: return "mappin.circle.fill"
        }
    }
    
    /// 颜色
    var color: String {
        switch self {
        case .home: return "orange"
        case .office: return "blue"
        case .school: return "purple"
        case .library: return "brown"
        case .gym: return "green"
        case .cafe: return "red"
        case .custom: return "gray"
        }
    }
    
    /// 建议屏蔽的应用描述
    var suggestedBlockingDescription: String {
        switch self {
        case .home: return "可选择性限制社交媒体和游戏"
        case .office: return "建议屏蔽社交媒体、短视频和游戏"
        case .school: return "建议屏蔽所有娱乐应用"
        case .library: return "建议启用严格模式，仅保留学习工具"
        case .gym: return "可屏蔽社交媒体，保留音乐应用"
        case .cafe: return "根据需要自定义"
        case .custom: return "根据需要自定义"
        }
    }
    
    /// 默认地理围栏半径（米）
    var defaultRadius: Double {
        switch self {
        case .home: return 50
        case .office: return 100
        case .school: return 200
        case .library: return 50
        case .gym: return 50
        case .cafe: return 30
        case .custom: return 100
        }
    }
}

// MARK: - Location Profile Snapshot (for App Group sharing)

/// 位置配置快照（用于跨进程共享）
struct LocationProfileSnapshot: Codable, Equatable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let blockedProfileId: UUID?
    let isEnabled: Bool
    let geofenceIdentifier: String
    
    init(from profile: LocationProfile) {
        self.id = profile.id
        self.name = profile.name
        self.latitude = profile.latitude
        self.longitude = profile.longitude
        self.radius = profile.radius
        self.blockedProfileId = profile.blockedProfileId
        self.isEnabled = profile.isEnabled
        self.geofenceIdentifier = profile.geofenceIdentifier
    }
}
