//
//  RequestAuthorizer.swift
//  ZenBound
//
//  FamilyControls 授权管理器
//  负责处理屏幕使用时间 API 的权限请求和状态管理
//

import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

/// 授权管理器
/// 封装 FamilyControls 授权请求，作为可被 SwiftUI 观察的对象
class RequestAuthorizer: ObservableObject {
    /// 是否已获得授权
    @Published var isAuthorized: Bool = false
    
    /// 授权状态
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    init() {
        // 初始化时检查当前授权状态
        checkAuthorizationStatus()
    }
    
    // MARK: - 公开方法
    
    /// 请求 FamilyControls 授权
    /// 使用 `.individual` scope，适用于个人设备
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    self.isAuthorized = true
                    self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
                    print("[ZenBound] Authorization granted")
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
                    print("[ZenBound] Authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 获取当前授权状态
    /// - Returns: 当前的 AuthorizationStatus
    func getAuthorizationStatus() -> AuthorizationStatus {
        return AuthorizationCenter.shared.authorizationStatus
    }
    
    /// 检查并更新授权状态
    func checkAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        self.authorizationStatus = status
        self.isAuthorized = (status == .approved)
    }
    
    /// 是否需要显示授权提示
    var needsAuthorization: Bool {
        return authorizationStatus != .approved
    }
    
    /// 授权状态描述文本
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "未请求授权"
        case .denied:
            return "授权被拒绝"
        case .approved:
            return "已授权"
        @unknown default:
            return "未知状态"
        }
    }
    
    /// 状态颜色
    var statusColor: Color {
        switch authorizationStatus {
        case .approved:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}
