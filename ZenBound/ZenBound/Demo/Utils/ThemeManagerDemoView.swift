import SwiftUI

/// ThemeManager Demo - 展示主题颜色管理
struct ThemeManagerDemoView: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var logMessages: [LogMessage] = []
    
    // 所有可用主题色
    private let themeColors: [(name: String, color: Color)] = [
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Mint", .mint),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Indigo", .indigo),
        ("Brown", .brown),
        ("Gray", .gray),
        ("Black", .black),
        ("White", .white)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 功能说明
                DemoSectionView(title: "📖 功能说明", icon: "book") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ThemeManager 管理应用的主题颜色。")
                        
                        Text("**属性：**")
                        BulletPointView(text: "@Published themeColor: Color - 当前主题色")
                        BulletPointView(text: "@AppStorage 持久化存储")
                        
                        Text("**可用颜色 (15种)：**")
                        Text("Blue, Purple, Pink, Red, Orange, Yellow, Green, Mint, Teal, Cyan, Indigo, Brown, Gray, Black, White")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("**使用方式：**")
                        BulletPointView(text: ".accentColor(themeManager.themeColor)")
                        BulletPointView(text: ".tint(themeManager.themeColor)")
                        BulletPointView(text: ".foregroundColor(themeManager.themeColor)")
                    }
                }
                
                // MARK: - 当前主题
                DemoSectionView(title: "🎨 当前主题", icon: "paintpalette") {
                    VStack(spacing: 16) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.themeColor)
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading) {
                                Text("当前主题色")
                                    .font(.headline)
                                Text(themeColorName)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // 主题色预览组件
                        VStack(spacing: 12) {
                            Button("Primary Button") {}
                                .buttonStyle(.borderedProminent)
                                .tint(themeManager.themeColor)
                            
                            Button("Secondary Button") {}
                                .buttonStyle(.bordered)
                                .tint(themeManager.themeColor)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                Image(systemName: "heart.fill")
                                Image(systemName: "bell.fill")
                            }
                            .font(.title)
                            .foregroundColor(themeManager.themeColor)
                            
                            ProgressView(value: 0.7)
                                .tint(themeManager.themeColor)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // MARK: - 颜色选择
                DemoSectionView(title: "🎯 选择颜色", icon: "paintbrush") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(themeColors, id: \.name) { item in
                            Button {
                                selectColor(item.name, color: item.color)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    if colorMatches(item.color) {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundColor(contrastColor(for: item.color))
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: - 操作演示
                DemoSectionView(title: "🎮 操作演示", icon: "play.circle") {
                    VStack(spacing: 12) {
                        Button {
                            randomColor()
                        } label: {
                            Label("随机颜色", systemImage: "shuffle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeManager.themeColor)
                        
                        Button {
                            resetToDefault()
                        } label: {
                            Label("恢复默认 (Blue)", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 场景应用
                DemoSectionView(title: "🎯 场景应用", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "场景1: 全局主题注入",
                            description: "通过 EnvironmentObject 全局共享主题",
                            code: """
@main
struct ZenBoundApp: App {
    @StateObject var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .tint(themeManager.themeColor)
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景2: 组件使用主题色",
                            description: "子视图读取主题色",
                            code: """
struct ProfileCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let profile: BlockedProfiles
    
    var body: some View {
        HStack {
            Circle()
                .fill(themeManager.themeColor)
                .frame(width: 40, height: 40)
            Text(profile.name)
        }
        .padding()
        .background(themeManager.themeColor.opacity(0.1))
        .cornerRadius(12)
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "场景3: 设置页面颜色选择",
                            description: "用户可选择的主题色设置",
                            code: """
struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Form {
            Section("主题颜色") {
                ForEach(ThemeManager.availableColors, id: \\.self) { color in
                    Button {
                        themeManager.themeColor = color
                    } label: {
                        HStack {
                            Circle().fill(color).frame(width: 24)
                            Text(color.description)
                            Spacer()
                            if themeManager.themeColor == color {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
}
"""
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("ThemeManager")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.themeColor)
        .onAppear {
            addLog("页面加载，当前主题: \(themeColorName)", type: .info)
        }
    }
    
    // MARK: - Helpers
    private var themeColorName: String {
        for item in themeColors {
            if colorMatches(item.color) {
                return item.name
            }
        }
        return "Custom"
    }
    
    private func colorMatches(_ color: Color) -> Bool {
        // 简化的颜色比较
        return themeManager.themeColor.description == color.description
    }
    
    private func contrastColor(for color: Color) -> Color {
        // 简化的对比色计算
        let darkColors: [Color] = [.blue, .purple, .indigo, .black, .brown, .red]
        return darkColors.contains(where: { $0.description == color.description }) ? .white : .black
    }
    
    // MARK: - Actions
    private func selectColor(_ name: String, color: Color) {
        themeManager.themeColor = color
        addLog("🎨 选择颜色: \(name)", type: .success)
    }
    
    private func randomColor() {
        let random = themeColors.randomElement()!
        themeManager.themeColor = random.color
        addLog("🎲 随机颜色: \(random.name)", type: .success)
    }
    
    private func resetToDefault() {
        themeManager.themeColor = .blue
        addLog("🔄 恢复默认: Blue", type: .warning)
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
        if logMessages.count > 15 {
            logMessages.removeLast()
        }
    }
}

#Preview {
    NavigationStack {
        ThemeManagerDemoView()
    }
}
