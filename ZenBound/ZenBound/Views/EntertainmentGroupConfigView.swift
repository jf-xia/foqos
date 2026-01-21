//
//  EntertainmentGroupConfigView.swift
//  ZenBound
//
//  娱乐组配置视图 - 假期模式设置
//

import FamilyControls
import SwiftUI

struct EntertainmentGroupConfigView: View {
    @Bindable var group: EntertainmentGroup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager
    
    @State private var showAppPicker = false
    @State private var showHolidayPicker = false
    @State private var selectedHoliday = Date()
    
    var body: some View {
        Form {
            // 基本信息
            Section("基本信息") {
                TextField("组名称", text: $group.name)
                
                Button(action: { showAppPicker = true }) {
                    HStack {
                        Text("选择娱乐应用")
                        Spacer()
                        Text("\(group.selectedActivity.applicationTokens.count) 个应用")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 假期选择
            Section("假期选择") {
                Toggle("周末放松", isOn: $group.enableWeekends)
                
                // 假期日期
                DisclosureGroup("假期日期 (\(group.holidayDates.count) 天)") {
                    ForEach(group.holidayDates, id: \.self) { date in
                        HStack {
                            Text(date, style: .date)
                            Spacer()
                            Button(action: {
                                group.holidayDates.removeAll { $0 == date }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    DatePicker("添加假期", selection: $selectedHoliday, displayedComponents: .date)
                    
                    Button("添加") {
                        if !group.holidayDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: selectedHoliday) }) {
                            group.holidayDates.append(selectedHoliday)
                        }
                    }
                }
                
                // 自定义日期
                DisclosureGroup("自定义日期 (\(group.customDates.count) 天)") {
                    ForEach(group.customDates, id: \.self) { date in
                        HStack {
                            Text(date, style: .date)
                            Spacer()
                            Button(action: {
                                group.customDates.removeAll { $0 == date }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            // 娱乐限制设置
            Section("娱乐限制设置") {
                Picker("每日使用时长", selection: $group.dailyTimeLimit) {
                    Text("60 分钟").tag(60)
                    Text("90 分钟").tag(90)
                    Text("120 分钟").tag(120)
                    Text("180 分钟").tag(180)
                    Text("240 分钟").tag(240)
                }
                
                Picker("单次使用时长", selection: $group.singleSessionLimit) {
                    Text("10 分钟").tag(10)
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                    Text("45 分钟").tag(45)
                    Text("60 分钟").tag(60)
                }
            }
            
            // 延长时间设置
            Section("延长时间") {
                Toggle("允许延长使用时间", isOn: $group.allowExtension)
                
                if group.allowExtension {
                    Picker("延长次数", selection: $group.extensionCount) {
                        ForEach(1...5, id: \.self) { count in
                            Text("\(count) 次").tag(count)
                        }
                    }
                    
                    Picker("每次延长时间", selection: $group.extensionDuration) {
                        Text("5 分钟").tag(5)
                        Text("10 分钟").tag(10)
                        Text("15 分钟").tag(15)
                        Text("20 分钟").tag(20)
                    }
                    
                    HStack {
                        Text("今日已使用")
                        Spacer()
                        Text("\(group.extensionsUsedToday)/\(group.extensionCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 休息屏蔽设置
            Section("休息提醒") {
                Toggle("启用休息提醒", isOn: $group.enableRestBlock)
                
                if group.enableRestBlock {
                    Toggle("休息时屏蔽所有应用", isOn: $group.blockAllAppsWhenRest)
                    
                    Picker("提醒间隔", selection: $group.restReminderInterval) {
                        Text("30 分钟").tag(30)
                        Text("60 分钟").tag(60)
                        Text("90 分钟").tag(90)
                        Text("120 分钟").tag(120)
                    }
                    
                    TextField("提醒消息", text: $group.restReminderMessage)
                }
            }
            
            // 活动任务设置
            Section("活动任务") {
                Toggle("启用活动任务", isOn: $group.enableActivityTasks)
                
                if group.enableActivityTasks {
                    DisclosureGroup("选择任务类型 (\(group.selectedTasks.count) 个)") {
                        ForEach(ActivityTaskType.allCases, id: \.rawValue) { taskType in
                            Toggle(isOn: Binding(
                                get: { group.selectedTasks.contains(taskType.rawValue) },
                                set: { isSelected in
                                    if isSelected {
                                        group.selectedTasks.append(taskType.rawValue)
                                    } else {
                                        group.selectedTasks.removeAll { $0 == taskType.rawValue }
                                    }
                                }
                            )) {
                                Label(taskType.displayName, systemImage: taskType.icon)
                            }
                        }
                    }
                    
                    Picker("每个任务奖励时间", selection: $group.extraTimePerTask) {
                        Text("5 分钟").tag(5)
                        Text("10 分钟").tag(10)
                        Text("15 分钟").tag(15)
                        Text("20 分钟").tag(20)
                    }
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
                            .fill(Color(hex: group.shieldColorHex) ?? .green)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            // 操作按钮
            Section {
                HStack {
                    Text("今日娱乐")
                    Spacer()
                    if group.isEntertainmentAllowedToday() {
                        Label("允许", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("不允许", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Toggle("启用娱乐模式", isOn: $group.isActive)
                    .disabled(!group.isEntertainmentAllowedToday())
                    .onChange(of: group.isActive) { _, newValue in
                        if newValue {
                            sessionManager.startEntertainmentSession(group: group, context: modelContext)
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
        .navigationTitle("娱乐组设置")
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
        EntertainmentGroupConfigView(group: EntertainmentGroup(name: "周末娱乐"))
    }
    .environmentObject(SessionManager.shared)
}
