import ActivityKit
import Foundation
import SwiftUI

/**
 1) 作用：集中管理 Live Activity 的启动、更新、结束与持久化；利用 AppStorage 记忆活动 ID 并在初始化时恢复，确保专注会话在前后台或重启后仍能显示动态岛/锁屏状态；同时基于 ActivityKit 权限检测避免在不支持的设备或版本上调用。
 2) 项目内用法与相关流程：在应用根场景中以单例形式注入环境对象，供会话调度器在手动/定时/NFC/二维码等策略下启动或更新 Live Activity；在会话加载时若已有进行中会话则尝试恢复或关闭活动；在紧急解锁或会话结束时强制终止活动；在休息开始/结束时仅更新内容状态。
 3) 项目内常见用法示例：
    - 根视图环境注入（让所有子视图可访问 Live Activity 状态）：
      ```swift
      @StateObject private var liveActivity = LiveActivityManager.shared
      RootView()
        .environmentObject(liveActivity)
      ```
    - 会话启动时开启或续接 Live Activity（策略回调内）：
      ```swift
      strategy.onSessionCreation = { event in
        switch event {
        case .started(let session):
          self.liveActivityManager.startSessionActivity(session: session)
        case .ended:
          self.liveActivityManager.endSessionActivity()
        }
      }
      ```
    - 休息状态切换时仅更新内容状态（避免重新请求 Activity）：
      ```swift
      if session.isBreakActive {
        liveActivityManager.updateBreakState(session: session)
      } else {
        liveActivityManager.updateBreakState(session: session)
      }
      ```
    - 紧急解锁或无活跃会话时主动结束并清理：
      ```swift
      if let active = getActiveSession() {
        stopBlocking(session: active)
        liveActivityManager.endSessionActivity()
      }
      ```
 4) GitHub 搜索（ActivityKit + Swift，stars>200，近两年更新）结果稀少，但常见开源模式通常包含：启动前检查 `ActivityAuthorizationInfo().areActivitiesEnabled`；在单例/DI 容器中持有 `Activity<Attributes>`；用 `Task` 异步调用 `update` / `end`；启动时用随机或本地化文案填充 attributes。
 5) GitHub 常见用法示例（基于上述模式抽象化示例）：
    ```swift
    final class LiveActivityCenter {
      static let shared = LiveActivityCenter()
      @AppStorage("activityId") private var id = ""
      private init() {}

      func start(attributes: SomeAttributes, state: SomeAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if let existing = Activity<SomeAttributes>.activities.first(where: { $0.id == id }) {
          self.id = existing.id
          Task { await existing.update(using: state) }
          return
        }
        if let activity = try? Activity.request(attributes: attributes, contentState: state) {
          self.id = activity.id
        }
      }

      func end() {
        guard let current = Activity<SomeAttributes>.activities.first(where: { $0.id == id }) else { return }
        Task { await current.end(using: .init(), dismissalPolicy: .immediate) }
        id = ""
      }
    }
    ```
 注意事项：Live Activities 需 iOS 16.1+ 且设备支持；在模拟器上可能不可用；若涉及隐私数据需确保 attributes 不泄露；结束时应清理持久化的 ID 以避免悬空引用。 
**/

class LiveActivityManager: ObservableObject {
  // Published property for live activity reference
  @Published var currentActivity: Activity<ZbWidgetAttributes>?

  // Use AppStorage for persisting the activity ID across app launches
  @AppStorage("com.foqos.currentActivityId") private var storedActivityId: String = ""

  static let shared = LiveActivityManager()

  private init() {
    // Try to restore existing activity on initialization
    restoreExistingActivity()
  }

  private var isSupported: Bool {
    if #available(iOS 16.1, *) {
      return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    return false
  }

  // Save activity ID using AppStorage
  private func saveActivityId(_ id: String) {
    storedActivityId = id
  }

  // Remove activity ID from AppStorage
  private func removeActivityId() {
    storedActivityId = ""
  }

  // Restore existing activity from system if available
  private func restoreExistingActivity() {
    guard isSupported else { return }

    // Check if we have a saved activity ID
    if !storedActivityId.isEmpty {
      if let existingActivity = Activity<ZbWidgetAttributes>.activities.first(where: {
        $0.id == storedActivityId
      }) {
        // Found the existing activity
        self.currentActivity = existingActivity
        print("Restored existing Live Activity with ID: \(existingActivity.id)")
      } else {
        // The activity no longer exists, clean up the stored ID
        print("No existing activity found with saved ID, removing reference")
        removeActivityId()
      }
    }
  }

  func startSessionActivity(session: BlockedProfileSession) {
    // Check if Live Activities are supported
    guard isSupported else {
      print("Live Activities are not supported on this device")
      return
    }

    // Check if we can restore an existing activity first
    if currentActivity == nil {
      restoreExistingActivity()
    }

    // Check if we already have an activity running
    if currentActivity != nil {
      print("Live Activity is already running, will update instead")
      updateSessionActivity(session: session)
      return
    }

    if session.blockedProfile.enableLiveActivity == false {
      print("Activity is disabled for profile")
      return
    }

    // Create and start the activity
    let profileName = session.blockedProfile.name
    let message = FocusMessages.getRandomMessage()
    let attributes = ZbWidgetAttributes(name: profileName, message: message)
    let contentState = ZbWidgetAttributes.ContentState(
      startTime: session.startTime,
      isBreakActive: session.isBreakActive,
      breakStartTime: session.breakStartTime,
      breakEndTime: session.breakEndTime
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        contentState: contentState
      )
      currentActivity = activity

      saveActivityId(activity.id)
      print("Started Live Activity with ID: \(activity.id) for profile: \(profileName)")
      return
    } catch {
      print("Error starting Live Activity: \(error.localizedDescription)")
      return
    }
  }

  func updateSessionActivity(session: BlockedProfileSession) {
    guard let activity = currentActivity else {
      print("No Live Activity to update")
      return
    }

    let updatedState = ZbWidgetAttributes.ContentState(
      startTime: session.startTime,
      isBreakActive: session.isBreakActive,
      breakStartTime: session.breakStartTime,
      breakEndTime: session.breakEndTime
    )

    Task {
      await activity.update(using: updatedState)
      print("Updated Live Activity with ID: \(activity.id)")
    }
  }

  func updateBreakState(session: BlockedProfileSession) {
    guard let activity = currentActivity else {
      print("No Live Activity to update for break state")
      return
    }

    let updatedState = ZbWidgetAttributes.ContentState(
      startTime: session.startTime,
      isBreakActive: session.isBreakActive,
      breakStartTime: session.breakStartTime,
      breakEndTime: session.breakEndTime
    )

    Task {
      await activity.update(using: updatedState)
      print("Updated Live Activity break state: \(session.isBreakActive)")
    }
  }

  func endSessionActivity() {
    guard let activity = currentActivity else {
      print("No Live Activity to end")
      return
    }

    // End the activity
    let completedState = ZbWidgetAttributes.ContentState(
      startTime: Date.now
    )

    Task {
      await activity.end(using: completedState, dismissalPolicy: .immediate)
      print("Ended Live Activity")
    }

    // Remove the stored activity ID when ending the activity
    removeActivityId()
    currentActivity = nil
  }
}
