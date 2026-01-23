import SwiftUI

// MARK: - Time Duration Picker
/// 时长选择器组件 - 用于选择分钟数
struct DurationPickerView: View {
    let title: String
    let icon: String
    @Binding var selectedMinutes: Int
    var options: [Int] = [5, 10, 15, 25, 30, 45, 60, 90, 120]
    var allowCustom: Bool = true
    @State private var showCustomInput = false
    @State private var customValue = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                Spacer()
                
                Menu {
                    ForEach(options, id: \.self) { minutes in
                        Button {
                            selectedMinutes = minutes
                        } label: {
                            if selectedMinutes == minutes {
                                Label("\(minutes) 分钟", systemImage: "checkmark")
                            } else {
                                Text("\(minutes) 分钟")
                            }
                        }
                    }
                    
                    if allowCustom {
                        Divider()
                        Button {
                            showCustomInput = true
                        } label: {
                            Label("自定义...", systemImage: "pencil")
                        }
                    }
                } label: {
                    HStack {
                        Text("\(selectedMinutes) 分钟")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .alert("自定义时长", isPresented: $showCustomInput) {
            TextField("分钟数", text: $customValue)
                .keyboardType(.numberPad)
            Button("取消", role: .cancel) { }
            Button("确定") {
                if let value = Int(customValue), value > 0 {
                    selectedMinutes = value
                }
                customValue = ""
            }
        }
    }
}

// MARK: - Count Picker
/// 次数选择器组件
struct CountPickerView: View {
    let title: String
    let icon: String
    @Binding var selectedCount: Int
    var options: [Int] = [1, 2, 3, 4, 5, 10]
    var suffix: String = "次"
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
            Spacer()
            
            Picker("", selection: $selectedCount) {
                ForEach(options, id: \.self) { count in
                    Text("\(count) \(suffix)").tag(count)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Toggle Setting Row
/// 开关设置行组件
struct ToggleSettingRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var isOn: Bool
    var iconColor: Color = .accentColor
    
    init(title: String, subtitle: String? = nil, icon: String, isOn: Binding<Bool>, iconColor: Color = .accentColor) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
        self.iconColor = iconColor
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Shield Theme Settings
/// Shield主题设置组件
struct ShieldThemeSettingsView: View {
    @Binding var selectedMessage: String
    @Binding var selectedColor: Color
    var defaultMessages: [String]
    var showCustomInput: Bool = true
    @State private var isCustomMessage = false
    @State private var customMessageText = ""
    
    private let colorOptions: [(String, Color)] = [
        ("红色", .red),
        ("橙色", .orange),
        ("蓝色", .blue),
        ("绿色", .green),
        ("紫色", .purple),
        ("粉色", .pink),
        ("青色", .cyan),
        ("靛蓝", .indigo)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题/消息选择
            VStack(alignment: .leading, spacing: 8) {
                Text("Shield 消息")
                    .font(.subheadline.bold())
                
                ForEach(defaultMessages, id: \.self) { message in
                    Button {
                        selectedMessage = message
                        isCustomMessage = false
                    } label: {
                        HStack {
                            Text(message)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedMessage == message && !isCustomMessage {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                if showCustomInput {
                    Button {
                        isCustomMessage = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("自定义消息...")
                                .foregroundColor(.primary)
                            Spacer()
                            if isCustomMessage {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    if isCustomMessage {
                        TextField("输入自定义消息", text: $customMessageText)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: customMessageText) { _, newValue in
                                selectedMessage = newValue
                            }
                    }
                }
            }
            
            Divider()
            
            // 颜色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("主题颜色")
                    .font(.subheadline.bold())
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(colorOptions, id: \.0) { name, color in
                        Button {
                            selectedColor = color
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                Text(name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // 预览
            VStack(alignment: .leading, spacing: 8) {
                Text("预览")
                    .font(.subheadline.bold())
                
                VStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(selectedColor)
                    
                    Text(selectedMessage.isEmpty ? "Shield 消息" : selectedMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Button("打开 ZenBound") { }
                        .buttonStyle(.borderedProminent)
                        .tint(selectedColor)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Schedule Picker
/// 时间段选择器
struct SchedulePickerView: View {
    @Binding var startHour: Int
    @Binding var startMinute: Int
    @Binding var endHour: Int
    @Binding var endMinute: Int
    @Binding var selectedDays: Set<Weekday>
    
    private let weekdays: [(Weekday, String)] = [
        (.sunday, "日"),
        (.monday, "一"),
        (.tuesday, "二"),
        (.wednesday, "三"),
        (.thursday, "四"),
        (.friday, "五"),
        (.saturday, "六")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 时间选择
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("开始时间")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Picker("", selection: $startHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50, height: 80)
                        .clipped()
                        
                        Text(":")
                        
                        Picker("", selection: $startMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50, height: 80)
                        .clipped()
                    }
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("结束时间")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Picker("", selection: $endHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50, height: 80)
                        .clipped()
                        
                        Text(":")
                        
                        Picker("", selection: $endMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50, height: 80)
                        .clipped()
                    }
                }
            }
            
            // 星期选择
            VStack(alignment: .leading, spacing: 8) {
                Text("选择日期")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(weekdays, id: \.0) { day, label in
                        Button {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        } label: {
                            Text(label)
                                .font(.caption)
                                .frame(width: 36, height: 36)
                                .background(selectedDays.contains(day) ? Color.accentColor : Color(.systemGray5))
                                .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                .cornerRadius(18)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Action Buttons View
/// 操作按钮组件（保存/取消）
struct ActionButtonsView: View {
    let onSave: () -> Void
    let onCancel: () -> Void
    var saveTitle: String = "保存"
    var cancelTitle: String = "取消"
    var saveColor: Color = .accentColor
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                onCancel()
            } label: {
                Text(cancelTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button {
                onSave()
            } label: {
                Text(saveTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(saveColor)
        }
        .padding()
    }
}

// MARK: - Section Header
/// 分区标题组件
struct ConfigSectionHeader: View {
    let title: String
    let icon: String
    var color: Color = .accentColor
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
        }
        .padding(.top, 8)
    }
}

// MARK: - App Selection Placeholder
/// App选择占位符（实际需要FamilyActivityPicker）
struct AppSelectionPlaceholder: View {
    let title: String
    let selectedCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "apps.iphone")
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("已选择 \(selectedCount) 个")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Task Selection View
/// 任务选择组件
struct TaskSelectionView: View {
    @Binding var selectedTasks: Set<String>
    
    let availableTasks = [
        ("figure.walk", "Physical Exercise", "体育锻炼"),
        ("brain.head.profile", "Knowledge Quiz", "知识问答"),
        ("envelope.open", "Wish Bottle", "许愿瓶"),
        ("heart.text.square", "Emotion Diary", "情绪日记"),
        ("person.2", "Cooperative Tasks", "合作任务"),
        ("function", "Math Drills", "数学练习"),
        ("textformat.abc", "Vocabulary Memorization", "单词记忆")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(availableTasks, id: \.1) { icon, id, name in
                Button {
                    if selectedTasks.contains(id) {
                        selectedTasks.remove(id)
                    } else {
                        selectedTasks.insert(id)
                    }
                } label: {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        
                        Text(name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedTasks.contains(id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(selectedTasks.contains(id) ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Configuration Components") {
    ScrollView {
        VStack(spacing: 20) {
            DurationPickerView(
                title: "专注时长",
                icon: "timer",
                selectedMinutes: .constant(25)
            )
            
            CountPickerView(
                title: "番茄周期",
                icon: "repeat",
                selectedCount: .constant(4)
            )
            
            ToggleSettingRow(
                title: "严格模式",
                subtitle: "启用后无法轻易停止",
                icon: "lock.shield",
                isOn: .constant(true)
            )
            
            AppSelectionPlaceholder(
                title: "选择干扰应用",
                selectedCount: 12
            ) { }
        }
        .padding()
    }
}

