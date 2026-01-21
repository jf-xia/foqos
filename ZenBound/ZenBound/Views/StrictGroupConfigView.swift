//
//  StrictGroupConfigView.swift
//  ZenBound
//
//  严格组配置视图 - 时间限制设置
//

import FamilyControls
import SwiftUI

struct StrictGroupConfigView: View {
    @Bindable var group: StrictGroup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager
    
    @State private var showAppPicker = false
    @State private var newWebsite = ""
    @State private var newKeyword = ""
    
    var body: some View {
        Form {
            // 基本信息
            Section("基本信息") {
                TextField("组名称", text: $group.name)
                
                Button(action: { showAppPicker = true }) {
                    HStack {
                        Text("选择分心应用")
                        Spacer()
                        Text("\(group.selectedActivity.applicationTokens.count) 个应用")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 网站屏蔽
            Section("屏蔽网站") {
                ForEach(group.blockedWebsites, id: \.self) { website in
                    HStack {
                        Text(website)
                        Spacer()
                        Button(action: {
                            group.blockedWebsites.removeAll { $0 == website }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("添加网站", text: $newWebsite)
                    Button(action: {
                        if !newWebsite.isEmpty {
                            group.blockedWebsites.append(newWebsite)
                            newWebsite = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .disabled(newWebsite.isEmpty)
                }
            }
            
            // 关键词屏蔽
            Section("屏蔽关键词") {
                ForEach(group.blockedKeywords, id: \.self) { keyword in
                    HStack {
                        Text(keyword)
                        Spacer()
                        Button(action: {
                            group.blockedKeywords.removeAll { $0 == keyword }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("添加关键词", text: $newKeyword)
                    Button(action: {
                        if !newKeyword.isEmpty {
                            group.blockedKeywords.append(newKeyword)
                            newKeyword = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .disabled(newKeyword.isEmpty)
                }
            }
            
            // 时间限制设置
            Section("严格限制设置") {
                Picker("每日使用时长", selection: $group.dailyTimeLimit) {
                    Text("5 分钟").tag(5)
                    Text("10 分钟").tag(10)
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                    Text("45 分钟").tag(45)
                    Text("60 分钟").tag(60)
                    Text("90 分钟").tag(90)
                    Text("120 分钟").tag(120)
                }
                
                Picker("单次使用时长", selection: $group.singleSessionLimit) {
                    Text("5 分钟").tag(5)
                    Text("10 分钟").tag(10)
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                }
            }
            
            // 时间表设置
            Section("时间表") {
                Toggle("始终活动", isOn: $group.alwaysActive)
                
                if !group.alwaysActive {
                    Text("添加时间表功能即将推出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 其他设置
            Section("其他设置") {
                Toggle("紧急解锁", isOn: $group.enableEmergencyUnlock)
                
                if group.enableEmergencyUnlock {
                    Picker("紧急使用次数", selection: $group.emergencyUnlockCount) {
                        ForEach([1, 2, 3, 5, 10], id: \.self) { count in
                            Text("\(count) 次").tag(count)
                        }
                    }
                    
                    HStack {
                        Text("已使用")
                        Spacer()
                        Text("\(group.emergencyUnlocksUsed)/\(group.emergencyUnlockCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("限制 App Store 安装新应用", isOn: $group.blockAppStoreInstall)
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
                            .fill(Color(hex: group.shieldColorHex) ?? .red)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            // 操作按钮
            Section {
                Toggle("启用严格模式", isOn: $group.isActive)
                    .onChange(of: group.isActive) { _, newValue in
                        if newValue {
                            sessionManager.startStrictSession(group: group, context: modelContext)
                        } else {
                            sessionManager.stopCurrentSession(context: modelContext)
                        }
                    }
            }
            
            Section {
                Button("删除组", role: .destructive) {
                    modelContext.delete(group)
                    dismiss()
                }
            }
        }
        .navigationTitle("严格组设置")
        .familyActivityPicker(
            isPresented: $showAppPicker,
            selection: $group.selectedActivity
        )
        .onChange(of: group.selectedActivity) { _, _ in
            group.updatedAt = Date()
        }
    }
}

#Preview {
    NavigationStack {
        StrictGroupConfigView(group: StrictGroup(name: "社交媒体限制"))
    }
    .environmentObject(SessionManager.shared)
}
