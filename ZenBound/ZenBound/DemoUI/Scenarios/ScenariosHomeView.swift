import SwiftUI

/// 应用场景入口 - 展示实用场景和配置模板
struct ScenariosHomeView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        List {
            // MARK: - 场景介绍
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🎯 实用场景指南")
                        .font(.headline)
                    
                    Text("以下场景展示了如何组合ZenBound的各项功能来满足不同的屏幕时间管理需求。每个场景都包含详细的功能说明、代码示例和改进建议。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            // MARK: - 配置模板 (新增)
            Section {
                NavigationLink {
                    FocusGroupConfigView()
                } label: {
                    ScenarioRowView(
                        icon: "brain.head.profile",
                        title: "专注组配置",
                        subtitle: "番茄工作法 · 强制休息 · 健康习惯",
                        color: .red,
                        isNew: true
                    )
                }
                
                NavigationLink {
                    StrictGroupConfigView()
                } label: {
                    ScenarioRowView(
                        icon: "lock.shield.fill",
                        title: "严格组配置",
                        subtitle: "每日限制 · 时间段调度 · 紧急解锁",
                        color: .orange,
                        isNew: true
                    )
                }
                
                NavigationLink {
                    EntertainmentGroupConfigView()
                } label: {
                    ScenarioRowView(
                        icon: "gamecontroller.fill",
                        title: "娱乐组配置",
                        subtitle: "周末假期 · 延长使用 · 活动任务",
                        color: .green,
                        isNew: true
                    )
                }
            } header: {
                Label("🎨 配置模板", systemImage: "slider.horizontal.3")
            } footer: {
                Text("三种预设配置模板，快速创建专属屏蔽配置")
            }
            
            // MARK: - 工作与学习
            Section {
                NavigationLink {
                    WorkFocusScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "briefcase.fill",
                        title: "工作专注模式",
                        subtitle: "一键启动专注，实时显示进度",
                        color: .blue
                    )
                }
                
                NavigationLink {
                    StudyPlanScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "book.fill",
                        title: "学习计划模式",
                        subtitle: "自动日程安排，追踪学习统计",
                        color: .purple
                    )
                }
                
                NavigationLink {
                    PomodoroTechniqueScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "timer",
                        title: "番茄工作法",
                        subtitle: "25分钟专注 + 5分钟休息循环",
                        color: .red
                    )
                }
            } header: {
                Label("💼 工作与学习", systemImage: "desktopcomputer")
            }
            
            // MARK: - 健康与习惯
            Section {
                NavigationLink {
                    SocialMediaDetoxScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "社交媒体戒断",
                        subtitle: "减少社交媒体依赖，培养健康习惯",
                        color: .orange
                    )
                }
                
                NavigationLink {
                    BedtimeDigitalDetoxScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "moon.fill",
                        title: "睡前数字戒断",
                        subtitle: "改善睡眠质量，减少蓝光暴露",
                        color: .indigo
                    )
                }
            } header: {
                Label("🌙 健康与习惯", systemImage: "heart.fill")
            }
            
            // MARK: - 家庭与共享
            Section {
                NavigationLink {
                    FamilySharingScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "person.3.fill",
                        title: "家庭共享管理",
                        subtitle: "多配置文件，家庭成员共享",
                        color: .green
                    )
                }
            } header: {
                Label("👨‍👩‍👧‍👦 家庭与共享", systemImage: "house.fill")
            }
            
            // MARK: - 高级功能
            Section {
                NavigationLink {
                    EmergencyUnlockScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "exclamationmark.shield.fill",
                        title: "紧急解锁机制",
                        subtitle: "严格模式下的安全阀门",
                        color: .red
                    )
                }
                
                NavigationLink {
                    SessionAnalyticsScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "chart.bar.fill",
                        title: "会话数据分析",
                        subtitle: "统计趋势，洞察专注习惯",
                        color: .cyan
                    )
                }
                
                NavigationLink {
                    NFCPhysicalUnlockScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "wave.3.right",
                        title: "NFC物理解锁",
                        subtitle: "使用NFC标签物理解锁屏蔽",
                        color: .teal
                    )
                }
                
                NavigationLink {
                    ShortcutsIntegrationScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "command",
                        title: "快捷指令集成",
                        subtitle: "Siri语音控制，自动化工作流",
                        color: .pink
                    )
                }
                
                NavigationLink {
                    ContentPrivacyRestrictionsScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "hand.raised.fill",
                        title: "内容与隐私权限制",
                        subtitle: "App Store、媒体内容、系统设置限制",
                        color: .purple,
                        isNew: true
                    )
                }
            } header: {
                Label("⚙️ 高级功能", systemImage: "gearshape.2.fill")
            }
            
            // MARK: - 智能场景
            Section {
                NavigationLink {
                    LocationBasedScenarioView()
                } label: {
                    ScenarioRowView(
                        icon: "location.fill",
                        title: "地理位置组配置",
                        subtitle: "在家、学校、办公室自动切换策略",
                        color: .teal,
                        isNew: true
                    )
                }
            } header: {
                Label("🌍 智能场景", systemImage: "sparkles")
            } footer: {
                Text("根据上下文自动调整屏蔽策略")
            }
        }
        .navigationTitle("应用场景")
        .listStyle(.insetGrouped)
        .tint(themeManager.themeColor)
    }
}

// MARK: - Scenario Row Component
struct ScenarioRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isNew: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                    
                    if isNew {
                        Text("NEW")
                            .font(.caption2.bold())
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ScenariosHomeView()
    }
}
