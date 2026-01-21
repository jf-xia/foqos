//
//  FocusGroupConfigView.swift
//  ZenBound
//
//  专注组配置视图 - 番茄工作法设置
//

import FamilyControls
import SwiftUI

struct FocusGroupConfigView: View {
    @Bindable var group: FocusGroup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager
    
    @State private var showAppPicker = false
    @State private var showShieldSettings = false
    
    var body: some View {
        Form {
            // 基本信息
            Section("基本信息") {
                TextField("组名称", text: $group.name)
                
                Button(action: { showAppPicker = true }) {
                    HStack {
                        Text("选择应用")
                        Spacer()
                        Text("\(group.selectedActivity.applicationTokens.count) 个应用")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 番茄钟设置
            Section("番茄钟设置") {
                Picker("番茄时长", selection: $group.pomodoroDuration) {
                    Text("15 分钟").tag(15)
                    Text("25 分钟").tag(25)
                    Text("30 分钟").tag(30)
                    Text("45 分钟").tag(45)
                    Text("60 分钟").tag(60)
                }
                
                Picker("休息时长", selection: $group.breakDuration) {
                    Text("5 分钟").tag(5)
                    Text("10 分钟").tag(10)
                    Text("15 分钟").tag(15)
                    Text("20 分钟").tag(20)
                }
                
                Picker("番茄周期", selection: $group.pomodoroCount) {
                    ForEach(1...8, id: \.self) { count in
                        Text("\(count) 个").tag(count)
                    }
                }
            }
            
            // 专注限制设置
            Section("专注限制设置") {
                Toggle("专注期间禁用通知", isOn: $group.disableNotifications)
                Toggle("专注期间禁止所有 App", isOn: $group.blockAllApps)
                Toggle("专注期间禁止切换 App", isOn: $group.blockAppSwitching)
                Toggle("完成番茄后拍照打卡", isOn: $group.requirePhotoCheck)
            }
            
            // 提醒设置
            Section("提醒设置") {
                Toggle("番茄结束前 5 分钟提醒", isOn: $group.reminderBeforeEnd)
                Toggle("休息结束前 1 分钟提醒", isOn: $group.reminderBeforeBreakEnd)
                
                Picker("完成番茄后奖励时间", selection: $group.extraTimePerPomodoro) {
                    Text("5 分钟").tag(5)
                    Text("10 分钟").tag(10)
                    Text("15 分钟").tag(15)
                    Text("20 分钟").tag(20)
                }
            }
            
            // Shield 设置
            Section("Shield 设置") {
                NavigationLink(destination: ShieldThemeSettingsView(
                    title: $group.shieldTitle,
                    message: $group.shieldMessage,
                    colorHex: $group.shieldColorHex,
                    emoji: $group.shieldEmoji
                )) {
                    HStack {
                        Text("主题设置")
                        Spacer()
                        Circle()
                            .fill(Color(hex: group.shieldColorHex) ?? .purple)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            // 操作按钮
            Section {
                if sessionManager.activeGroupId == group.id {
                    Button("停止专注", role: .destructive) {
                        sessionManager.stopCurrentSession(context: modelContext)
                    }
                } else {
                    Button("开始专注") {
                        sessionManager.startFocusSession(group: group, context: modelContext)
                        dismiss()
                    }
                    .disabled(group.selectedActivity.applicationTokens.isEmpty)
                }
            }
            
            Section {
                Button("删除组", role: .destructive) {
                    modelContext.delete(group)
                    dismiss()
                }
            }
        }
        .navigationTitle("专注组设置")
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: $group.selectedActivity
        )
        .onChange(of: group.selectedActivity) { _, _ in
            group.updatedAt = Date()
        }
    }
}

// MARK: - Shield Theme Settings View
struct ShieldThemeSettingsView: View {
    @Binding var title: String
    @Binding var message: String
    @Binding var colorHex: String
    @Binding var emoji: String
    
    let presetTitles = ["Focus Time!", "Stay Focused!", "You can do it!", "Keep going!"]
    let presetMessages = ["Take a deep breath", "Just a little longer", "You're doing great", "Stay strong"]
    let presetEmojis = ["🎯", "🧘", "💪", "🌟", "🔥", "✨", "🚀", "💎"]
    let presetColors = ["#4A90D9", "#E74C3C", "#27AE60", "#F39C12", "#9B59B6", "#1ABC9C"]
    
    var body: some View {
        Form {
            Section("标题") {
                TextField("自定义标题", text: $title)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(presetTitles, id: \.self) { preset in
                            Button(preset) {
                                title = preset
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            Section("消息") {
                TextField("自定义消息", text: $message)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(presetMessages, id: \.self) { preset in
                            Button(preset) {
                                message = preset
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            Section("图标") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presetEmojis, id: \.self) { emojiOption in
                            Button(action: { emoji = emojiOption }) {
                                Text(emojiOption)
                                    .font(.title)
                                    .padding(8)
                                    .background(emoji == emojiOption ? Color.purple.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            Section("颜色") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presetColors, id: \.self) { colorOption in
                            Button(action: { colorHex = colorOption }) {
                                Circle()
                                    .fill(Color(hex: colorOption) ?? .purple)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: colorHex == colorOption ? 3 : 0)
                                    )
                                    .shadow(color: colorHex == colorOption ? .black.opacity(0.3) : .clear, radius: 5)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            Section("预览") {
                VStack(spacing: 12) {
                    Text(emoji)
                        .font(.system(size: 50))
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button("打开 ZenBound 番茄时钟") {}
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundColor(Color(hex: colorHex) ?? .purple)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: colorHex) ?? .purple)
                .cornerRadius(16)
            }
        }
        .navigationTitle("Shield 主题")
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

#Preview {
    NavigationStack {
        FocusGroupConfigView(group: FocusGroup(name: "工作专注"))
    }
    .environmentObject(SessionManager.shared)
}
