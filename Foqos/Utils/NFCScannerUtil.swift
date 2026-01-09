import CoreNFC
import SwiftUI

/**
 工具类：NFC标签读写管理器（Utils/核心NFC集成层）
 
 1. 功能说明（输入/输出示例）
    - 输入：
      * 调用 `scan(profileName: String)` 激活读取模式，监听用户靠近的NFC标签
      * 调用 `writeURL(_ url: String)` 激活写入模式，将URL写入用户靠近的NFC标签
    - 输出：
      * 通过 `onTagScanned` 回调返回 `NFCResult(id: String, url: String?, DateScanned: Date)`
      * 通过 `onError` 回调返回错误信息字符串
    - 示例：
      ```swift
      let scanner = NFCScannerUtil()
      scanner.onTagScanned = { result in
        print("读取标签: \(result.id), URL: \(result.url ?? "无")")
      }
      scanner.scan(profileName: "工作")  // 弹起系统NFC扫描UI
      ```

 2. 项目内搜索与使用位置
    - NFCBlockingStrategy: 通过NFC标签启动/停止阻止策略（点击"NFC标签"策略 → 扫描标签 → 激活应用限制）
    - NFCManualBlockingStrategy/NFCTimerBlockingStrategy: 变体策略，继承同样的NFC读写能力
    - PhysicalReader: 跨类型物理标识符读取器（支持NFC和QR），用于验证解锁凭证

 3. 项目内用法总结
    - 用法A：策略层启动模式
      目的：在"管理阻止/应用限制"流程中，让用户通过NFC标签快速启动或停止限制
      UI流程：BlockedProfileView → 选择"NFC标签"策略 → 点击启动按钮 → 系统弹出"靠近NFC"UI
      代码示例：
      ```swift
      private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
      
      func startBlocking(context: ModelContext, profile: BlockedProfiles, forceStart: Bool?) -> (any View)? {
        nfcScanner.onTagScanned = { tag in
          let identifier = tag.url ?? tag.id  // 优先使用NDEF中的URL，否则使用硬件ID
          self.activateRestrictions(for: profile)
          self.createSession(withTag: identifier, forProfile: profile)
        }
        nfcScanner.scan(profileName: profile.name)  // 触发系统NFC读取界面
        return nil
      }
      ```

    - 用法B：物理标识解锁验证
      目的：在停止限制前，验证用户确实拥有对应的NFC标签（防止未授权解锁）
      UI流程：正在运行的限制卡片 → 点击"停止" → 要求扫描NFC → 验证ID匹配 → 解除限制
      代码示例：
      ```swift
      class PhysicalReader {
        private let nfcScanner: NFCScannerUtil = NFCScannerUtil()
        
        func readNFCTag(onSuccess: @escaping (String) -> Void) {
          nfcScanner.onTagScanned = { result in
            let tagId = result.url ?? result.id
            onSuccess(tagId)  // 返回标签唯一标识
          }
          nfcScanner.scan(profileName: "")
        }
      }
      ```

 4. GitHub常见用法模式分析
    常见的开源NFC阅读器实现（PassportReader, JapanNFCReader等）主要分为两大类：
    
    - 类型A：通用NDEF读取（ISO14443, ISO15693标准）
      模式：创建 `NFCTagReaderSession` → delegate处理 `didDetect` → 根据tag类型判断 → 读NDEF数据 → 回调
      通用流程适用于：普通商业卡、支付卡、身份证等支持NDEF的标签
    
    - 类型B：专有标签格式读取（FeliCa, MiFare, Passport等）
      模式：创建 `NFCNDEFReaderSession` → 查询NDEF状态 → 根据状态分支处理 → 读写数据
      专用流程适用于：特定区域的电子产品（日本FeliCa、欧洲MiFare）

 5. GitHub常见用法代码示例
    
    - 通用模式：标签类型判断与NDEF解析
      ```swift
      // 创建通用标签阅读会话
      let nfcSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], 
                                          delegate: self, queue: nil)
      nfcSession.begin()
      
      // 处理检测到的标签
      func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        session.connect(to: tag) { [weak self] error in
          if let error = error { return }
          
          // 根据标签类型分支处理
          switch tag {
          case .iso15693(let iso15693Tag):
            iso15693Tag.readNDEF { message, error in
              // 解析NDEF中的URL或其他数据
              if let payload = message?.records.first?.wellKnownTypeURIPayload() {
                // 处理URL
              }
            }
          case .miFare(let miFareTag):
            miFareTag.readNDEF { message, error in
              // MiFare特定处理
            }
          default:
            break
          }
        }
      }
      ```

    - NDEF写入模式：状态检查 → 权限验证 → 写入数据
      ```swift
      let ndefSession = NFCNDEFReaderSession(delegate: self, queue: nil, 
                                            invalidateAfterFirstRead: false)
      ndefSession.begin()
      
      // 检查标签是否支持NDEF写入
      func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }
        session.connect(to: tag) { [weak self] error in
          tag.queryNDEFStatus { status, capacity, error in
            switch status {
            case .readWrite:
              // 创建NDEF消息并写入
              let url = URL(string: "https://example.com")!
              let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)
              let message = NFCNDEFMessage(records: [payload])
              tag.writeNDEF(message) { error in
                if error == nil { print("写入成功") }
              }
            case .readOnly:
              // 标签为只读，无法写入
              break
            default:
              break
            }
          }
        }
      }
      ```

 重要注意事项：
 - NFC功能仅在真实iPhone设备上可用（模拟器不支持），开发时需使用 `NFCReaderSession.readingAvailable` 判断
 - 需要在 `Info.plist` 中声明 `NFCReaderUsageDescription` 权限描述，且设备需启用NFC功能
 - NDEF数据读取失败时（如旧标签或不兼容格式），框架自动降级到读取硬件ID（tag.identifier）
 - 标签数据与真机状态的同步：项目内通过 `tag.url ?? tag.id` 实现 NDEF优先、ID备选的多层级匹配策略
 */
struct NFCResult: Equatable {
  var id: String
  var url: String?
  var DateScanned: Date
}

class NFCScannerUtil: NSObject {
  // Callback closures for handling results and errors
  var onTagScanned: ((NFCResult) -> Void)?
  var onError: ((String) -> Void)?

  private var nfcSession: NFCReaderSession?
  private var urlToWrite: String?

  func scan(profileName: String) {
    guard NFCReaderSession.readingAvailable else {
      self.onError?("NFC scanning not available on this device")
      return
    }

    nfcSession = NFCTagReaderSession(
      pollingOption: [.iso14443, .iso15693],
      delegate: self,
      queue: nil
    )
    nfcSession?.alertMessage = "Hold your iPhone near an NFC tag to trigger " + profileName
    nfcSession?.begin()
  }

  func writeURL(_ url: String) {
    guard NFCReaderSession.readingAvailable else {
      self.onError?("NFC writing not available on this device")
      return
    }

    guard URL(string: url) != nil else {
      self.onError?("Invalid URL format")
      return
    }

    urlToWrite = url

    // Using NFCNDEFReaderSession for writing
    let ndefSession = NFCNDEFReaderSession(
      delegate: self, queue: nil, invalidateAfterFirstRead: false)
    ndefSession.alertMessage =
      "Hold your iPhone near an NFC tag to write the profile."
    ndefSession.begin()
  }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCScannerUtil: NFCTagReaderSessionDelegate {
  func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    // Session started
  }

  func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
    DispatchQueue.main.async {
      self.onError?(error.localizedDescription)
    }
  }

  func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
    guard let tag = tags.first else { return }

    session.connect(to: tag) { error in
      if let error = error {
        session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
        return
      }

      switch tag {
      case .iso15693(let tag):
        self.readISO15693Tag(tag, session: session)
      case .miFare(let tag):
        self.readMiFareTag(tag, session: session)
      default:
        session.invalidate(errorMessage: "Unsupported tag type")
      }
    }
  }

  private func updateWithNDEFMessageURL(_ message: NFCNDEFMessage) -> String? {
    let urls: [URLComponents] = message.records.compactMap {
      (payload: NFCNDEFPayload) -> URLComponents? in
      if let url = payload.wellKnownTypeURIPayload() {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if components?.host == "foqos.app" && components?.scheme == "https" {
          return components
        }
      }
      return nil
    }

    guard urls.count == 1, let item = urls.first?.string else {
      return nil
    }

    return item
  }

  private func readMiFareTag(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
    tag.readNDEF { (message: NFCNDEFMessage?, error: Error?) in
      if error != nil || message == nil {
        let tagId = tag.identifier.hexEncodedString()

        if let error = error {
          print(
            "⚠️ NDEF read failed (non-critical): \(error.localizedDescription). using tag id: \(tagId)"
          )
        }

        // Still use the identifier - works for all tag types
        self.handleTagData(
          id: tagId,
          url: nil,
          session: session
        )
        return
      }

      let url = self.updateWithNDEFMessageURL(message!)
      self.handleTagData(
        id: tag.identifier.hexEncodedString(),
        url: url,
        session: session
      )
    }
  }

  private func readISO15693Tag(_ tag: NFCISO15693Tag, session: NFCTagReaderSession) {
    tag.readNDEF { (message: NFCNDEFMessage?, error: Error?) in
      if error != nil || message == nil {
        let tagId = tag.identifier.hexEncodedString()

        if let error = error {
          print(
            "⚠️ ISO15693 NDEF read failed (non-critical): \(error.localizedDescription). using tag id: \(tagId)"
          )
        }

        self.handleTagData(
          id: tagId,
          url: nil,
          session: session
        )
        return
      }

      let url = self.updateWithNDEFMessageURL(message!)
      self.handleTagData(
        id: tag.identifier.hexEncodedString(),
        url: url,
        session: session
      )
    }
  }

  private func handleTagData(id: String, url: String?, session: NFCTagReaderSession) {
    let result = NFCResult(id: id, url: url, DateScanned: Date())

    DispatchQueue.main.async {
      self.onTagScanned?(result)
      session.invalidate()
    }
  }
}

// New NDEF Writing Support
extension NFCScannerUtil: NFCNDEFReaderSessionDelegate {
  func readerSession(
    _ session: NFCNDEFReaderSession,
    didDetectNDEFs messages: [NFCNDEFMessage]
  ) {
    // Not used for writing
  }

  func readerSession(
    _ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]
  ) {
    guard let tag = tags.first else {
      session.invalidate(errorMessage: "No tag found")
      return
    }

    session.connect(to: tag) { error in
      if let error = error {
        session.invalidate(
          errorMessage:
            "Connection error: \(error.localizedDescription)")
        return
      }

      tag.queryNDEFStatus { status, capacity, error in
        guard error == nil else {
          session.invalidate(errorMessage: "Failed to query tag")
          return
        }

        switch status {
        case .notSupported:
          session.invalidate(
            errorMessage: "Tag is not NDEF compliant")
        case .readOnly:
          session.invalidate(errorMessage: "Tag is read-only")
        case .readWrite:
          self.handleReadWrite(session, tag: tag)
        @unknown default:
          session.invalidate(errorMessage: "Unknown tag status")
        }
      }
    }
  }

  func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    // Session became active
  }

  func readerSession(
    _ session: NFCNDEFReaderSession, didInvalidateWithError error: Error
  ) {
    DispatchQueue.main.async {
      if let readerError = error as? NFCReaderError {
        switch readerError.code {
        case .readerSessionInvalidationErrorFirstNDEFTagRead,
          .readerSessionInvalidationErrorUserCanceled:
          // User canceled or first tag read
          break
        default:
          self.onError?(readerError.localizedDescription)
        }
      }
    }
  }

  private func handleReadWrite(
    _ session: NFCNDEFReaderSession, tag: NFCNDEFTag
  ) {
    guard let urlString = self.urlToWrite,
      let url = URL(string: urlString),
      let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)
    else {
      session.invalidate(errorMessage: "Invalid URL")
      return
    }

    let message = NFCNDEFMessage(records: [urlPayload])
    tag.writeNDEF(message) { error in
      if let error = error {
        session.invalidate(
          errorMessage: "Write failed: \(error.localizedDescription)")
      } else {
        session.alertMessage = "Successfully wrote URL to tag"
        session.invalidate()
      }
    }
  }
}

extension Data {
  func hexEncodedString() -> String {
    return map { String(format: "%02hhX", $0) }.joined()
  }
}
