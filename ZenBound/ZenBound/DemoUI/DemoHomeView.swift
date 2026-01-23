import SwiftUI

/// Demo 首页 - 按功能模块分组展示所有 Demo 页面
struct DemoHomeView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - 应用场景 (新增)
                Section {
                    NavigationLink {
                        ScenariosHomeView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("10种应用场景")
                                    .font(.headline)
                                Text("功能组合实战演示")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("NEW")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("🎯 应用场景", systemImage: "star.fill")
                } footer: {
                    Text("将多个功能组合成完整的使用场景")
                }
                
                // MARK: - Models 数据模型
                Section {
                    NavigationLink {
                        BlockedProfilesDemoView()
                    } label: {
                        DemoRowView(
                            icon: "person.crop.rectangle.stack",
                            title: "BlockedProfiles",
                            subtitle: "屏蔽配置主模型 - CRUD操作演示"
                        )
                    }
                    
                    NavigationLink {
                        BlockedProfileSessionsDemoView()
                    } label: {
                        DemoRowView(
                            icon: "clock.badge.checkmark",
                            title: "BlockedProfileSessions",
                            subtitle: "会话记录管理 - 开始/结束/休息"
                        )
                    }
                    
                    NavigationLink {
                        ScheduleDemoView()
                    } label: {
                        DemoRowView(
                            icon: "calendar.badge.clock",
                            title: "Schedule",
                            subtitle: "日程安排 - Weekday 与时间段"
                        )
                    }
                    
                    NavigationLink {
                        SharedDataDemoView()
                    } label: {
                        DemoRowView(
                            icon: "square.and.arrow.up.on.square",
                            title: "SharedData",
                            subtitle: "App Group 跨进程数据共享"
                        )
                    }
                    
                    NavigationLink {
                        StrategiesDemoView()
                    } label: {
                        DemoRowView(
                            icon: "shield.lefthalf.filled",
                            title: "Strategies",
                            subtitle: "屏蔽策略 - Manual/NFC/QR/Timer"
                        )
                    }
                    
                    NavigationLink {
                        TimersDemoView()
                    } label: {
                        DemoRowView(
                            icon: "timer",
                            title: "Timers",
                            subtitle: "定时器活动 - Schedule/Break/Strategy"
                        )
                    }
                } header: {
                    Label("📦 Models - 数据模型", systemImage: "square.stack.3d.up")
                } footer: {
                    Text("SwiftData 持久化模型，定义应用核心数据结构")
                }
                
                // MARK: - Utils 工具类
                Section {
                    NavigationLink {
                        AppBlockerUtilDemoView()
                    } label: {
                        DemoRowView(
                            icon: "lock.shield",
                            title: "AppBlockerUtil",
                            subtitle: "Screen Time API 屏蔽控制"
                        )
                    }
                    
                    NavigationLink {
                        DeviceActivityCenterUtilDemoView()
                    } label: {
                        DemoRowView(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "DeviceActivityCenterUtil",
                            subtitle: "设备活动监控调度"
                        )
                    }
                    
                    NavigationLink {
                        FamilyActivityUtilDemoView()
                    } label: {
                        DemoRowView(
                            icon: "person.2.badge.gearshape",
                            title: "FamilyActivityUtil",
                            subtitle: "家庭活动选择计数"
                        )
                    }
                    
                    NavigationLink {
                        FocusMessagesDemoView()
                    } label: {
                        DemoRowView(
                            icon: "quote.bubble",
                            title: "FocusMessages",
                            subtitle: "专注提示语集合"
                        )
                    }
                    
                    NavigationLink {
                        ProfileInsightsUtilDemoView()
                    } label: {
                        DemoRowView(
                            icon: "chart.bar.xaxis",
                            title: "ProfileInsightsUtil",
                            subtitle: "会话统计与趋势分析"
                        )
                    }
                    
                    NavigationLink {
                        RatingManagerDemoView()
                    } label: {
                        DemoRowView(
                            icon: "star.bubble",
                            title: "RatingManager",
                            subtitle: "App Store 评分请求管理"
                        )
                    }
                    
                    NavigationLink {
                        RequestAuthorizerDemoView()
                    } label: {
                        DemoRowView(
                            icon: "checkmark.shield",
                            title: "RequestAuthorizer",
                            subtitle: "Screen Time 权限授权"
                        )
                    }
                    
                    NavigationLink {
                        StrategyManagerDemoView()
                    } label: {
                        DemoRowView(
                            icon: "gearshape.2",
                            title: "StrategyManager",
                            subtitle: "会话生命周期协调器"
                        )
                    }
                    
                    NavigationLink {
                        ThemeManagerDemoView()
                    } label: {
                        DemoRowView(
                            icon: "paintpalette",
                            title: "ThemeManager",
                            subtitle: "主题颜色管理"
                        )
                    }
                    
                    NavigationLink {
                        TimersUtilDemoView()
                    } label: {
                        DemoRowView(
                            icon: "bell.badge.waveform",
                            title: "TimersUtil",
                            subtitle: "通知与后台任务调度"
                        )
                    }
                } header: {
                    Label("🛠️ Utils - 工具类", systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text("封装系统 API 的工具类，提供业务逻辑支持")
                }
            }
            .navigationTitle("ZenBound Demo")
            .listStyle(.insetGrouped)
        }
        .tint(themeManager.themeColor)
    }
}

// MARK: - Demo Row Component
struct DemoRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DemoHomeView()
}
