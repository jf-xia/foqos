import SwiftUI
import SwiftData

/// 场景9: NFC物理解锁
/// 使用NFC标签物理解锁屏蔽
struct NFCPhysicalUnlockScenarioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [BlockedProfiles]
    
    @State private var logMessages: [LogMessage] = []
    @State private var selectedProfile: BlockedProfiles?
    @State private var nfcTagId: String = ""
    @State private var isScanning = false
    @State private var scanResult: ScanResult?
    
    enum ScanResult {
        case success(String)
        case mismatch
        case error(String)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - 场景描述
                DemoSectionView(title: "📖 场景描述", icon: "doc.text") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("**NFC物理解锁**通过扫描预设的NFC标签来解锁屏蔽，增加解锁摩擦力。")
                        
                        Text("**使用场景：**")
                        BulletPointView(text: "将NFC标签放在办公室，强迫自己离开手机")
                        BulletPointView(text: "家长持有NFC标签，控制孩子的手机使用")
                        BulletPointView(text: "增加解锁难度，防止冲动解锁")
                        
                        Text("**核心特点：**")
                        BulletPointView(text: "物理标签绑定")
                        BulletPointView(text: "扫描验证解锁")
                        BulletPointView(text: "增加行为成本")
                    }
                }
                
                // MARK: - 依赖组件
                DemoSectionView(title: "🔧 依赖组件", icon: "puzzlepiece.extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        DependencyRowView(
                            name: "physicalUnblockNFCTagId",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "NFC标签ID - 存储绑定的标签标识"
                        )
                        DependencyRowView(
                            name: "BlockedProfiles",
                            path: "ZenBound/Models/BlockedProfiles.swift",
                            description: "配置管理 - 关联NFC标签"
                        )
                        DependencyRowView(
                            name: "BlockingStrategy",
                            path: "ZenBound/Models/Strategies/BlockingStrategy.swift",
                            description: "解锁策略 - 验证NFC后解锁"
                        )
                        DependencyRowView(
                            name: "StrategyManager",
                            path: "ZenBound/Utils/StrategyManager.swift",
                            description: "会话管理 - 协调解锁流程"
                        )
                        DependencyRowView(
                            name: "CoreNFC",
                            path: "系统框架",
                            description: "NFC读取 - iOS原生NFC支持"
                        )
                    }
                }
                
                // MARK: - NFC标签管理
                DemoSectionView(title: "📱 NFC标签管理", icon: "wave.3.right") {
                    VStack(spacing: 16) {
                        // 当前绑定状态
                        if nfcTagId.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "wave.3.right.circle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                
                                Text("未绑定NFC标签")
                                    .font(.headline)
                                
                                Text("请先扫描一个NFC标签进行绑定")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        } else {
                            HStack {
                                Image(systemName: "wave.3.right.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("已绑定NFC标签")
                                        .font(.headline)
                                    Text("ID: \(nfcTagId)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    unbindTag()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // 扫描按钮
                        Button {
                            startScan()
                        } label: {
                            HStack {
                                if isScanning {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "wave.3.right")
                                }
                                Text(nfcTagId.isEmpty ? "扫描并绑定标签" : "重新绑定标签")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .disabled(isScanning)
                        
                        // 扫描结果
                        if let result = scanResult {
                            switch result {
                            case .success(let tagId):
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("扫描成功: \(tagId)")
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                                
                            case .mismatch:
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("标签不匹配，请使用绑定的标签")
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                
                            case .error(let message):
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(message)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // MARK: - 解锁流程演示
                DemoSectionView(title: "🔓 解锁流程", icon: "lock.open") {
                    VStack(spacing: 16) {
                        // 流程步骤
                        ForEach(Array(unlockSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.teal)
                                        .frame(width: 28, height: 28)
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.subheadline.bold())
                                    Text(step.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // 模拟解锁
                        Button {
                            simulateUnlock()
                        } label: {
                            Label("模拟NFC解锁", systemImage: "wave.3.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(nfcTagId.isEmpty)
                    }
                }
                
                // MARK: - 代码示例
                DemoSectionView(title: "💻 核心代码", icon: "chevron.left.forwardslash.chevron.right") {
                    VStack(alignment: .leading, spacing: 12) {
                        ScenarioCardView(
                            title: "1. 绑定NFC标签",
                            description: "将标签ID保存到配置",
                            code: """
import CoreNFC

// NFC扫描会话
class NFCReader: NSObject, NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, 
                       didDetect tags: [NFCNDEFTag]) {
        // 读取标签ID
        let tag = tags.first!
        let tagId = tag.identifier.map { String(format: "%02X", $0) }
                                  .joined()
        
        // 保存到配置
        let _ = BlockedProfiles.updateProfile(
            profile, in: context,
            physicalUnblockNFCTagId: tagId
        )
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "2. 验证NFC解锁",
                            description: "在停止屏蔽时验证标签",
                            code: """
// 自定义 NFC 解锁策略
class NFCBlockingStrategy: BlockingStrategy {
    
    func stopBlocking(context: ModelContext, 
                      session: BlockedProfileSession) -> (any View)? {
        // 检查是否需要NFC验证
        guard let tagId = session.blockedProfile.physicalUnblockNFCTagId else {
            // 没有绑定NFC，直接停止
            return nil
        }
        
        // 返回NFC扫描视图
        return NFCScanView(
            expectedTagId: tagId,
            onSuccess: {
                // 验证通过，真正停止
                self.performStop(context: context, session: session)
            },
            onCancel: {
                // 取消解锁
            }
        )
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "3. NFC扫描视图",
                            description: "用户界面和扫描逻辑",
                            code: """
struct NFCScanView: View {
    let expectedTagId: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @State private var isScanning = false
    
    var body: some View {
        VStack {
            // 扫描动画
            LottieView(animation: "nfc_scan")
            
            Text("请将NFC标签靠近手机")
                .font(.headline)
            
            Button("开始扫描") {
                startNFCSession()
            }
        }
    }
    
    func startNFCSession() {
        let session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        session.begin()
    }
    
    // 验证扫描的标签
    func validateTag(_ scannedId: String) {
        if scannedId == expectedTagId {
            onSuccess()
        } else {
            // 显示错误：标签不匹配
        }
    }
}
"""
                        )
                        
                        ScenarioCardView(
                            title: "4. QR码备选方案",
                            description: "支持QR码作为备选解锁方式",
                            code: """
// 配置中同时支持NFC和QR码
let profile = BlockedProfiles.createProfile(
    in: context,
    name: "物理解锁配置",
    selection: apps,
    physicalUnblockNFCTagId: "A1B2C3D4",  // NFC
    physicalUnblockQRCodeId: "zenbound://unlock/xyz123"  // QR备选
)

// 解锁时可选择方式
if profile.physicalUnblockNFCTagId != nil {
    showNFCScanView()
} else if profile.physicalUnblockQRCodeId != nil {
    showQRScanView()
}
"""
                        )
                    }
                }
                
                // MARK: - 日志输出
                DemoLogView(messages: logMessages)
                
                // MARK: - 改进建议
                DemoSectionView(title: "💡 改进建议", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        ImprovementCardView(
                            priority: .high,
                            title: "支持多标签绑定",
                            description: "允许绑定多个NFC标签，放置在不同位置",
                            relatedFiles: ["BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .high,
                            title: "标签位置提示",
                            description: "记录标签位置描述，解锁时提示用户去哪找标签",
                            relatedFiles: ["BlockedProfiles.swift"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "定位解锁",
                            description: "支持到达特定地点（如公司）自动解锁",
                            relatedFiles: ["新建 LocationUnlock.swift", "CoreLocation"]
                        )
                        
                        ImprovementCardView(
                            priority: .medium,
                            title: "Apple Watch解锁",
                            description: "通过Apple Watch确认解锁，增加便利性",
                            relatedFiles: ["WatchConnectivity"]
                        )
                        
                        ImprovementCardView(
                            priority: .low,
                            title: "NFC标签购买引导",
                            description: "在App内推荐兼容的NFC标签购买渠道",
                            relatedFiles: ["新建 NFCTagGuide.swift"]
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("NFC物理解锁")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Computed Properties
    
    private var unlockSteps: [(title: String, description: String)] {
        [
            ("用户点击停止", "在严格模式下尝试停止屏蔽"),
            ("显示NFC扫描界面", "提示用户扫描绑定的NFC标签"),
            ("验证标签ID", "对比扫描的标签与绑定的标签"),
            ("解锁成功", "验证通过后解除屏蔽")
        ]
    }
    
    // MARK: - Private Methods
    
    private func startScan() {
        isScanning = true
        scanResult = nil
        addLog("📱 开始NFC扫描", type: .info)
        
        // 模拟扫描延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isScanning = false
            let mockTagId = "A1B2C3D4E5F6"
            nfcTagId = mockTagId
            scanResult = .success(mockTagId)
            addLog("✅ 扫描成功: \(mockTagId)", type: .success)
            addLog("💾 BlockedProfiles.updateProfile(physicalUnblockNFCTagId:)", type: .success)
        }
    }
    
    private func unbindTag() {
        addLog("🗑️ 解绑NFC标签: \(nfcTagId)", type: .warning)
        nfcTagId = ""
        scanResult = nil
        addLog("💾 BlockedProfiles.updateProfile(physicalUnblockNFCTagId: nil)", type: .success)
    }
    
    private func simulateUnlock() {
        addLog("🔓 模拟NFC解锁流程", type: .info)
        addLog("📱 NFCNDEFReaderSession.begin()", type: .info)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            addLog("✅ 标签验证通过", type: .success)
            addLog("🔓 StrategyManager.stopBlocking()", type: .success)
            addLog("✅ 屏蔽已解除", type: .success)
            scanResult = .success(nfcTagId)
        }
    }
    
    private func addLog(_ message: String, type: LogType) {
        logMessages.insert(LogMessage(message: message, type: type), at: 0)
    }
}

#Preview {
    NavigationStack {
        NFCPhysicalUnlockScenarioView()
    }
}
