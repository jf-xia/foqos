//
//  SettingsView.swift
//  ZenBound
//
//  设置视图
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var requestAuthorizer: RequestAuthorizer
    @AppStorage("showIntroScreen") private var showIntroScreen = true
    
    var body: some View {
        NavigationStack {
            List {
                // 授权状态
                Section("授权状态") {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(requestAuthorizer.statusColor)
                        
                        VStack(alignment: .leading) {
                            Text("屏幕使用时间")
                                .font(.subheadline)
                            Text(requestAuthorizer.statusDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(requestAuthorizer.statusColor)
                            .frame(width: 10, height: 10)
                    }
                    
                    if requestAuthorizer.needsAuthorization {
                        Button("请求授权") {
                            requestAuthorizer.requestAuthorization()
                        }
                    }
                }
                
                // 应用设置
                Section("应用设置") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("通知设置", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: ThemeSettingsView()) {
                        Label("主题设置", systemImage: "paintbrush.fill")
                    }
                    
                    NavigationLink(destination: DataExportView()) {
                        Label("数据导出", systemImage: "square.and.arrow.up")
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("隐私政策")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("服务条款")
                    }
                    
                    Link(destination: URL(string: "https://zenbound.app/support")!) {
                        HStack {
                            Text("帮助与反馈")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 开发者选项
                Section("开发者选项") {
                    Button("重置引导页") {
                        showIntroScreen = true
                    }
                    
                    Button("清除所有数据", role: .destructive) {
                        // TODO: 实现数据清除
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - Placeholder Views
struct NotificationSettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableSoundNotifications") private var enableSoundNotifications = true
    @AppStorage("enableBreakReminders") private var enableBreakReminders = true
    
    var body: some View {
        List {
            Section {
                Toggle("启用通知", isOn: $enableNotifications)
                Toggle("声音提醒", isOn: $enableSoundNotifications)
                Toggle("休息提醒", isOn: $enableBreakReminders)
            }
            
            Section("提醒时间") {
                Text("番茄钟结束前 5 分钟")
                Text("休息结束前 1 分钟")
            }
        }
        .navigationTitle("通知设置")
    }
}

struct ThemeSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "purple"
    
    let themes = ["purple", "blue", "green", "orange", "pink"]
    
    var body: some View {
        List {
            Section("主题颜色") {
                ForEach(themes, id: \.self) { theme in
                    HStack {
                        Circle()
                            .fill(colorFor(theme))
                            .frame(width: 30, height: 30)
                        
                        Text(theme.capitalized)
                        
                        Spacer()
                        
                        if selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.purple)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTheme = theme
                    }
                }
            }
        }
        .navigationTitle("主题设置")
    }
    
    func colorFor(_ theme: String) -> Color {
        switch theme {
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "pink": return .pink
        default: return .purple
        }
    }
}

struct DataExportView: View {
    var body: some View {
        List {
            Section {
                Button("导出任务记录") {
                    // TODO: 实现导出
                }
                
                Button("导出成就数据") {
                    // TODO: 实现导出
                }
                
                Button("导出所有数据") {
                    // TODO: 实现导出
                }
            }
        }
        .navigationTitle("数据导出")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("""
            隐私政策
            
            ZenBound 尊重并保护您的隐私。
            
            1. 数据收集
            我们仅收集应用运行所必需的数据，包括：
            - 屏幕使用时间数据（用于显示和管理）
            - 任务完成记录
            - 成就进度
            
            2. 数据存储
            所有数据均存储在您的设备本地，我们不会将您的数据上传至服务器。
            
            3. 数据共享
            我们不会与任何第三方共享您的个人数据。
            
            4. 联系我们
            如有任何隐私相关问题，请联系 privacy@zenbound.app
            """)
            .padding()
        }
        .navigationTitle("隐私政策")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("""
            服务条款
            
            欢迎使用 ZenBound！
            
            1. 服务说明
            ZenBound 是一款屏幕时间管理应用，旨在帮助用户养成健康的手机使用习惯。
            
            2. 用户责任
            用户应合理使用本应用，不得用于任何非法目的。
            
            3. 免责声明
            本应用不对因使用本服务而产生的任何直接或间接损失负责。
            
            4. 条款修改
            我们保留随时修改本服务条款的权利。
            
            5. 联系我们
            如有任何问题，请联系 support@zenbound.app
            """)
            .padding()
        }
        .navigationTitle("服务条款")
    }
}

#Preview {
    SettingsView()
        .environmentObject(RequestAuthorizer())
}
