//
//  ZenBoundApp.swift
//  ZenBound
//
//  屏幕时间管理应用 - 宠物猫养成 + 番茄钟 + 任务系统
//

import SwiftData
import SwiftUI

// MARK: - Model Container
private let container: ModelContainer = {
    do {
        return try ModelContainer(
            for: FocusGroup.self,
                 StrictGroup.self,
                 EntertainmentGroup.self,
                 GroupSchedule.self,
                 FocusSession.self,
                 StrictSession.self,
                 EntertainmentSession.self,
                 Pet.self,
                 ZenTask.self,
                 Achievement.self
        )
    } catch {
        fatalError("Couldn't create ModelContainer: \(error)")
    }
}()

@main
struct ZenBoundApp: App {
    // MARK: - Environment Objects
    
    /// 权限授权管理器
    @StateObject private var requestAuthorizer = RequestAuthorizer()
    
    /// 会话管理器 (Singleton)
    @StateObject private var sessionManager = SessionManager.shared
    
    /// 宠物管理器 (Singleton)
    @StateObject private var petManager = PetManager.shared
    
    /// 任务管理器 (Singleton)
    @StateObject private var taskManager = TaskManager.shared
    
    /// 成就管理器 (Singleton)
    @StateObject private var achievementManager = AchievementManager.shared
    
    // MARK: - App Storage
    @AppStorage("showIntroScreen") private var showIntroScreen = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(requestAuthorizer)
                .environmentObject(sessionManager)
                .environmentObject(petManager)
                .environmentObject(taskManager)
                .environmentObject(achievementManager)
                .onAppear {
                    initializeApp()
                }
        }
        .modelContainer(container)
    }
    
    // MARK: - Initialization
    
    private func initializeApp() {
        // 检查授权状态
        requestAuthorizer.checkAuthorizationStatus()
        
        // 初始化宠物
        let context = container.mainContext
        petManager.loadOrCreatePet(context: context)
        
        // 初始化任务
        taskManager.loadTasks(context: context)
        
        // 初始化成就
        achievementManager.initializeAchievements(context: context)
    }
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var requestAuthorizer: RequestAuthorizer
    @AppStorage("showIntroScreen") private var showIntroScreen = true
    
    var body: some View {
        Group {
            if showIntroScreen || requestAuthorizer.needsAuthorization {
                IntroView()
            } else {
                MainTabView()
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            PetView()
                .tabItem {
                    Label("宠物", systemImage: "pawprint.fill")
                }
                .tag(1)
            
            TaskListView()
                .tabItem {
                    Label("任务", systemImage: "checklist")
                }
                .tag(2)
            
            AchievementView()
                .tabItem {
                    Label("成就", systemImage: "trophy.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.purple)
    }
}
