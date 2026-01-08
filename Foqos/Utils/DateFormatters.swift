import Foundation

/** 
 * 1. 作用描述：
 * `DateFormatters` 是一个静态工具类（以 `enum` 实现，防止实例化），为项目提供统一的日期、时间戳以及持续时间（Duration）的格式化逻辑。
 * 它确保了在调试界面、日志记录以及用户设置面板中，时间相关的展示样式保持一致。
 *
 * 2. 项目内搜索与关联功能：
 * - **调试工具/监控面板**：广泛用于 `<DebugView>` 和各种调试卡片（如 `<SessionDebugCard>`, `<ProfileDebugCard>`），展示 Session 的开始/结束精确时间。
 * - **专注模式设置**：在 `<ProfileScheduleRow>` 中用于将用户设置的专注时长（分钟）转换为易读的 “h min” 格式。
 * - **实时状态追踪**：用于计算并展示当前正在运行的 `<BlockedProfileSession>` 的累计时长。
 *
 * 3. 项目内用法总结：
 * - **用法 A：格式化精确时间点**（用于调试审计日志）
 *   ```swift
 *   // 在调试组件中展示 Session 的开始时间
 *   DebugRow(label: "Start Time", value: DateFormatters.formatDate(session.startTime))
 *   ```
 * - **用法 B：格式化累计持续时间**（用于展示 Session 运行了多久）
 *   ```swift
 *   // 获取 Session 持续时间的字符串描述（如 "1h 20m 30s"）
 *   let durationText = DateFormatters.formatDuration(session.duration)
 *   ```
 * - **用法 C：格式化配置时长**（用于 UI 列表展示规则）
 *   ```swift
 *   // 在配置页面展示规则时长（如 "45 min" 或 "2h 30m"）
 *   Text(DateFormatters.formatMinutes(profile.timerDuration))
 *   ```
 *
 * 4. GitHub 常见用法分析（基于 Swift 5.10+, Star > 200 开源项目）：
 * 在现代 iOS 开发中，类似的工具类通常会有以下演进模式：
 * - **性能优化**：通过缓存 `DateFormatter` 实例来避免由于频繁创建该对象导致的性能损耗（`DateFormatter` 的创建非常昂贵）。
 * - **标准 API 调用**：在公开仓库中，开发者更倾向于使用原生 `DateComponentsFormatter` 来处理 duration，以支持本地化（Localization）。
 * - **相对时间**：常见于社交类应用，使用 `RelativeDateTimeFormatter` 展示“3分钟前”等描述。
 *
 * 5. GitHub 常见用法示例：
 * - **模式 A：利用 DateComponentsFormatter 实现本地化持续时间**（更稳健、支持多语言）
 *   ```swift
 *   struct DurationUtility {
 *       private static let formatter: DateComponentsFormatter = {
 *           let df = DateComponentsFormatter()
 *           df.allowedUnits = [.hour, .minute, .second]
 *           df.unitsStyle = .abbreviated // 输出如 "1h 20m"
 *           return df
 *       }()
 *
 *       static func format(interval: TimeInterval) -> String {
 *           return formatter.string(from: interval) ?? ""
 *       }
 *   }
 *   ```
 * - **模式 B：通过 Extension 提供便捷链式调用**
 *   ```swift
 *   extension Date {
 *       func toShortTimeString() -> String {
 *           let formatter = DateFormatter()
 *           formatter.dateStyle = .none
 *           formatter.timeStyle = .short
 *           return formatter.string(from: self)
 *       }
 *   }
 *
 *   // 使用：let timeLabel = Date().toShortTimeString()
 *   ```
 **/
enum DateFormatters {
  static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }

  static func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
      return String(format: "%dh %dm %ds", hours, minutes, seconds)
    } else if minutes > 0 {
      return String(format: "%dm %ds", minutes, seconds)
    } else {
      return String(format: "%ds", seconds)
    }
  }

  static func formatMinutes(_ durationInMinutes: Int) -> String {
    if durationInMinutes <= 60 {
      return "\(durationInMinutes) min"
    } else {
      let hours = durationInMinutes / 60
      let minutes = durationInMinutes % 60
      if minutes == 0 {
        return "\(hours)h"
      } else {
        return "\(hours)h \(minutes)m"
      }
    }
  }
}
