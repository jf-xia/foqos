//
//  IntroView.swift
//  ZenBound
//
//  引导页视图
//

import SwiftUI

struct IntroView: View {
    @EnvironmentObject var requestAuthorizer: RequestAuthorizer
    @AppStorage("showIntroScreen") private var showIntroScreen = true
    @State private var currentPage = 0
    
    let pages = [
        IntroPage(
            title: "欢迎来到 ZenBound",
            subtitle: "你的屏幕时间伙伴",
            description: "养成健康的手机使用习惯，和可爱的宠物猫一起成长！",
            imageName: "pawprint.circle.fill",
            color: .purple
        ),
        IntroPage(
            title: "专注模式",
            subtitle: "番茄工作法",
            description: "使用番茄钟保持专注，完成任务后获得奖励，解锁更多玩法。",
            imageName: "timer",
            color: .orange
        ),
        IntroPage(
            title: "养成习惯",
            subtitle: "任务与成就",
            description: "完成每日任务，收集成就徽章，让你的宠物越来越开心！",
            imageName: "star.fill",
            color: .yellow
        ),
        IntroPage(
            title: "需要授权",
            subtitle: "屏幕使用时间",
            description: "为了帮助你管理屏幕时间，我们需要访问屏幕使用时间的权限。",
            imageName: "lock.shield.fill",
            color: .blue
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [pages[currentPage].color.opacity(0.3), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                
                // 内容
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        IntroPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 按钮
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // 最后一页：授权按钮
                        Button(action: {
                            requestAuthorizer.requestAuthorization()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("授权并开始")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .cornerRadius(16)
                        }
                        
                        if requestAuthorizer.isAuthorized {
                            Button(action: {
                                showIntroScreen = false
                            }) {
                                Text("已授权，开始使用")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // 跳过授权按钮（用于模拟器测试）
                        #if DEBUG
                        Button(action: {
                            showIntroScreen = false
                        }) {
                            Text("跳过授权（仅供测试）")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        #endif
                    } else {
                        // 下一页按钮
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("继续")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .cornerRadius(16)
                        }
                    }
                    
                    // 跳过按钮
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }) {
                            Text("跳过")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onChange(of: requestAuthorizer.isAuthorized) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showIntroScreen = false
                }
            }
        }
    }
}

// MARK: - Intro Page Model
struct IntroPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
}

// MARK: - Intro Page View
struct IntroPageView: View {
    let page: IntroPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 图标
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .padding(30)
                .background(
                    Circle()
                        .fill(page.color.opacity(0.2))
                )
            
            // 标题
            VStack(spacing: 8) {
                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundColor(page.color)
                    .fontWeight(.medium)
                
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // 描述
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    IntroView()
        .environmentObject(RequestAuthorizer())
}
