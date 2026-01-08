import Foundation
import SwiftData

/**
 1. 目标代码的作用
    该工具类主要用于将 SwiftData 模型数据（具体为 `<BlockedProfileSession>`）导出为 CSV 格式字符串。
    核心方法 `exportSessionsCSV` 支持按 Profile ID 过滤、指定排序方向（升序/降序）以及时区（UTC/Local），并内部处理了 CSV 字段转义与 ISO8601 时间格式化。

 2. 项目中的使用方式与相关功能
    - **调用位置**: 主要在数据导出/统计相关的视图层调用（如 `<ExportView>` / `<SettingsDataView>`）。
    - **业务流程**:
      1. 用户在“档案详情”或“设置”页点击“导出数据”。
      2. 视图层收集需导出的 ID 列表，并获取当前的 SwiftData `ModelContext`。
      3. 调用此工具生成 CSV 字符串。
      4. 将字符串包装为 `<CSVDocument>` (遵循 `FileDocument` 协议)，触发系统的 `.fileExporter` 或 `ShareSheet` 供用户保存/分享。

 3. 项目内用法示例
    ```swift
    // 假设在 ViewModel 或 View 的 Action 中
    func generateReport() {
        do {
            // 1. 调用导出方法
            let csvString = try DataExporter.exportSessionsCSV(
                forProfileIDs: selectedIDs,
                in: modelContext, // 来自 @Environment(\.modelContext)
                sortDirection: .descending,
                timeZone: .local
            )

            // 2. 包装为文档对象供系统导出
            self.document = CSVDocument(text: csvString)
            self.isExporting = true
        } catch {
            print("Export failed: \(error)")
        }
    }
    ```
 */
enum DataExportSortDirection: Hashable {
  case ascending
  case descending
}

enum DataExportTimeZone: Hashable {
  case utc
  case local
}

struct DataExporter {
  static func exportSessionsCSV(
    forProfileIDs profileIDs: [UUID],
    in context: ModelContext,
    sortDirection: DataExportSortDirection = .ascending,
    timeZone: DataExportTimeZone = .utc
  ) throws -> String {
    var lines: [String] = [
      "session_id,profile_name,start_time,end_time,break_start_time,break_end_time"
    ]

    if profileIDs.isEmpty {
      return lines.joined(separator: "\n")
    }

    let order: SortOrder = (sortDirection == .ascending) ? .forward : .reverse
    let descriptor = FetchDescriptor<BlockedProfileSession>(
      predicate: #Predicate { session in
        profileIDs.contains(session.blockedProfile.id)
      },
      sortBy: [SortDescriptor(\.startTime, order: order)]
    )

    let sessions = try context.fetch(descriptor)

    let dateFormatter = makeISO8601Formatter(timeZone: timeZone)
    lines.reserveCapacity(sessions.count + 1)
    for session in sessions {
      let id = session.id
      let profileName = session.blockedProfile.name
      let start = dateFormatter.string(from: session.startTime)
      let end = session.endTime.map { dateFormatter.string(from: $0) } ?? ""
      let breakStart = session.breakStartTime.map { dateFormatter.string(from: $0) } ?? ""
      let breakEnd = session.breakEndTime.map { dateFormatter.string(from: $0) } ?? ""

      let row = [id, profileName, start, end, breakStart, breakEnd]
        .map { escapeCSVField($0) }
        .joined(separator: ",")
      lines.append(row)
    }

    return lines.joined(separator: "\n")
  }

  private static func escapeCSVField(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
      let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return field
  }

  private static func makeISO8601Formatter(timeZone: DataExportTimeZone) -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    switch timeZone {
    case .utc:
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
    case .local:
      formatter.timeZone = .current
    }
    return formatter
  }
}
