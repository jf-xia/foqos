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
        }
        .padding()
    }
}
