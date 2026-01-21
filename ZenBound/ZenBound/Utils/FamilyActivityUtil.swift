import FamilyControls
import Foundation

/**
 Screen Time 选区计数与校验工具类

 1. 作用
 封装 `FamilyActivitySelection` 的计数逻辑，核心是为了解决 Apple Screen Time API 在 "Allow List"（白名单）模式下的特殊限制问题。系统在白名单模式下会将“类别”拆解为具体 App 计算限额（容易突破 50 个 App 的限制），本工具提供统一的计数算法与预警判断。

 2. 项目内功能/流程
 - **列表摘要显示**：在受限策略列表中，计算并展示当前策略已选的 App/类别/网站总数。
 - **白名单模式预警**：在 App 选择器 UI 中，当监测到用户处于白名单模式且选中了“类别”时，发出可能超限的警告。

 3. 项目内用法示例
 - **用法 A：UI 里的计数展示**
   在 `<ProfileRow>` 或 `<DashboardView>` 中获取可显示的统计数字。
   ```swift
   // 获取选中项的总数（Apps + Categories + Websites）
   let count = FamilyActivityUtil.countSelectedActivities(profile.selection)
   Text("\(count) Apps Selected")
   ```

 - **用法 B：编辑时的合规性检查**
   在 `<AppPicker>` 或 `<ConfigScreen>` 中，根据当前模式（Allow/Block）决定是否以此工具检查输入合法性。
   ```swift
   // 检查是否选了类别（在 Allow 模式下类别可能导致系统限制错误）
   if FamilyActivityUtil.shouldShowAllowModeWarning(selection, allowMode: isAllowMode) {
       WarningView("Selecting categories in Allow Mode may exceed the 50-app limit.")
   }
   ```

 4. GitHub 公开仓库常见用法
 搜索条件: `FamilyActivitySelection count extension language:swift`
 - **常见模式**：社区项目通常直接对 `FamilyActivitySelection` 编写扩展（Extension），添加计算属性来获取总选区数量或判断是否为空。
 - **差异对比**：本项目将其封装为独立的 `Util` 结构体，这在需要处理复杂业务规则（如 Allow vs Block 模式差异）时比纯 Extension 更灵活。

 5. GitHub 常见用法示例
 社区通常使用扩展属性来简化调用：
   ```swift
   // GitHub 常见：通过 Extension 直接扩展模型能力
   extension FamilyActivitySelection {
       /// 检查是否包含任何选中项
       var hasSelection: Bool {
           return !applicationTokens.isEmpty || !categoryTokens.isEmpty || !webDomainTokens.isEmpty
       }

       /// 获取所有类型的 token 总和
       var totalItemCount: Int {
           return applications.count + categories// GitHub 常见：通过 Extension 直接扩展模型能力
   extension FamilyActivitySelection {
       /// 检查是否包含任何选中项
       var hasSelection: Bool {
           return !applicationTokens.isEmpty || !categoryTokens.isEmpty || !webDomainTokens.isEmpty
       }

       /// 获取所有类型的 token 总和
       var totalItemCount: Int {
           return applications.count + categories.count + webDomains.count
       }
   }
   ```
 */
/// Utility functions for working with FamilyActivitySelection
struct FamilyActivityUtil {

  /// Counts the total number of selected activities (categories + applications + web domains)
  /// - Parameters:
  ///   - selection: The FamilyActivitySelection to count
  ///   - allowMode: Whether this is for allow mode (affects display but not actual count)
  /// - Returns: Total count of selected items
  /// - Note: This shows the count as displayed to users. In ALLOW mode, Apple internally expands
  ///         categories to individual apps when enforcing the 50 app limit, so selecting a few
  ///         categories may exceed the limit. In BLOCK mode, categories count as 1 item each.
  static func countSelectedActivities(_ selection: FamilyActivitySelection, allowMode: Bool = false)
    -> Int
  {
    // This count shows categories + apps + domains as displayed
    // IMPORTANT: In Allow mode, Apple enforces the 50 limit AFTER expanding categories to individual apps
    // In Block mode, categories count as 1 regardless of how many apps they contain
    return selection.categories.count + selection.applications.count + selection.webDomains.count
  }

  /// Gets display text for the count with appropriate warnings for allow mode
  /// - Parameters:
  ///   - selection: The FamilyActivitySelection to display
  ///   - allowMode: Whether this is for allow mode
  /// - Returns: Formatted display text with warnings if needed
  static func getCountDisplayText(_ selection: FamilyActivitySelection, allowMode: Bool = false)
    -> String
  {
    let count = countSelectedActivities(selection, allowMode: allowMode)

    return "\(count) items"
  }

  /// Determines if a warning should be shown for allow mode category selection
  /// - Parameters:
  ///   - selection: The FamilyActivitySelection to check
  ///   - allowMode: Whether this is for allow mode
  /// - Returns: True if warning should be shown
  static func shouldShowAllowModeWarning(
    _ selection: FamilyActivitySelection, allowMode: Bool = false
  ) -> Bool {
    return allowMode && selection.categories.count > 0
  }

  /// Gets a detailed breakdown of the selection for debugging/stats
  /// - Parameter selection: The FamilyActivitySelection to analyze
  /// - Returns: A breakdown of categories, apps, and domains
  static func getSelectionBreakdown(_ selection: FamilyActivitySelection) -> (
    categories: Int, applications: Int, webDomains: Int
  ) {
    return (
      categories: selection.categories.count,
      applications: selection.applications.count,
      webDomains: selection.webDomains.count
    )
  }
}
