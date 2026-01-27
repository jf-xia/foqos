import SwiftUI

// MARK: - Log Types
enum LogType {
    case info
    case success
    case warning
    case error
    
    var color: Color {
        switch self {
        case .info: return .secondary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}

// MARK: - Log Message
struct LogMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType
    let timestamp = Date()
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Demo Section View
struct DemoSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Demo Log View
struct DemoLogView: View {
    let messages: [LogMessage]
    
    var body: some View {
        DemoSectionView(title: "📝 日志输出", icon: "doc.text") {
            VStack(alignment: .leading, spacing: 4) {
                if messages.isEmpty {
                    Text("暂无日志")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(messages) { log in
                        HStack(alignment: .top, spacing: 8) {
                            Text(log.formattedTime)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                            
                            Image(systemName: log.type.icon)
                                .font(.caption2)
                                .foregroundColor(log.type.color)
                            
                            Text(log.message)
                                .font(.caption)
                                .foregroundColor(log.type.color)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Bullet Point View
struct BulletPointView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Scenario Card View
struct ScenarioCardView: View {
    let title: String
    let description: String
    let code: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(8)
                }
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Info Card View
struct InfoCardView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Status Badge View
struct StatusBadgeView: View {
    let text: String
    let color: Color
    let icon: String?
    
    init(_ text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(icon: String, title: String, message: String, action: (() -> Void)? = nil, actionTitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Code Block View
struct CodeBlockView: View {
    let code: String
    let language: String
    
    init(_ code: String, language: String = "swift") {
        self.code = code
        self.language = language
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(language.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .padding(12)
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Dependency Row View
/// 依赖组件行视图
struct DependencyRowView: View {
    let name: String
    let path: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline.bold())
                .foregroundColor(.accentColor)
            Text(path)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Improvement Card View
/// 改进建议卡片
struct ImprovementCardView: View {
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
        
        var label: String {
            switch self {
            case .high: return "高"
            case .medium: return "中"
            case .low: return "低"
            }
        }
    }
    
    let priority: Priority
    let title: String
    let description: String
    let relatedFiles: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("优先级: \(priority.label)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(priority.color.opacity(0.15))
                    .foregroundColor(priority.color)
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(title)
                .font(.subheadline.bold())
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if !relatedFiles.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(relatedFiles.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Step Progress View
/// 流程步骤进度指示器
struct StepProgressView: View {
    let steps: [(icon: String, title: String)]
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Color.accentColor : Color(.systemGray4))
                            .frame(width: 32, height: 32)
                        
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: step.icon)
                                .font(.caption2)
                                .foregroundColor(index <= currentStep ? .white : .secondary)
                        }
                    }
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.accentColor : Color(.systemGray4))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Status Card View
/// 状态卡片视图
struct StatusCardView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.caption.bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Authorization Check Section View
/// 权限检查区块视图
struct AuthorizationCheckSectionView: View {
    let isAuthorized: Bool
    let authorizationChecked: Bool
    let onCheckAuthorization: () -> Void
    let onRequestAuthorization: () -> Void
    let logMessages: [LogMessage]
    
    var body: some View {
        VStack(spacing: 12) {
            // 权限状态显示
            HStack {
                Image(systemName: isAuthorized ? "checkmark.shield.fill" : "shield.slash")
                    .font(.title)
                    .foregroundColor(isAuthorized ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isAuthorized ? "屏幕时间已授权" : "屏幕时间未授权")
                        .font(.headline)
                    Text(isAuthorized ? "可以使用App屏蔽功能" : "需要授权才能使用屏蔽功能")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(isAuthorized ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(10)
            
            // 操作按钮
            HStack(spacing: 12) {
                Button {
                    onCheckAuthorization()
                } label: {
                    Label("检查权限", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                if !isAuthorized {
                    Button {
                        onRequestAuthorization()
                    } label: {
                        Label("请求授权", systemImage: "hand.raised")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // 权限说明
            VStack(alignment: .leading, spacing: 8) {
                Text("权限说明")
                    .font(.subheadline.bold())
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("需要「屏幕时间」权限来检测和限制App使用。授权后可以选择要限制的App并设置使用时间。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Test Case Row View
/// 测试用例行视图
struct TestCaseRowView: View {
    enum Status {
        case ready, planned, passed, failed
        
        var color: Color {
            switch self {
            case .ready: return .blue
            case .planned: return .gray
            case .passed: return .green
            case .failed: return .red
            }
        }
        
        var label: String {
            switch self {
            case .ready: return "Ready"
            case .planned: return "Planned"
            case .passed: return "Passed"
            case .failed: return "Failed"
            }
        }
    }
    
    let id: String
    let name: String
    let status: Status
    let description: String
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(name)
                        .font(.caption.bold())
                }
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Text(status.label)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(status.color.opacity(0.15))
                .foregroundColor(status.color)
                .cornerRadius(4)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(6)
    }
}

// MARK: - Flow Layout for Tags
/// 自适应流式布局 - 用于标签等自动换行
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Previews
#Preview("Demo Section") {
    ScrollView {
        VStack(spacing: 16) {
            DemoSectionView(title: "示例区块", icon: "star") {
                Text("这是一个示例内容区域")
            }
            
            DemoLogView(messages: [
                LogMessage(message: "操作成功", type: .success),
                LogMessage(message: "警告信息", type: .warning),
                LogMessage(message: "错误发生", type: .error),
                LogMessage(message: "一般信息", type: .info)
            ])
            
            ScenarioCardView(
                title: "示例场景",
                description: "这是场景描述",
                code: "let example = \"Hello World\""
            )
            
            DependencyRowView(
                name: "AppBlockerUtil",
                path: "ZenBound/Utils/AppBlockerUtil.swift",
                description: "App屏蔽工具类"
            )
            
            ImprovementCardView(
                priority: .high,
                title: "添加自动循环模式",
                description: "完成休息后自动开始下一个番茄",
                relatedFiles: ["StrategyManager.swift"]
            )
            
            TestCaseRowView(
                id: "TC-001",
                name: "权限请求流程",
                status: .ready,
                description: "验证从未授权到授权的完整流程"
            )
        }
        .padding()
    }
}
