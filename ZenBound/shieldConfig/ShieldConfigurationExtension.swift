//
//  ShieldConfigurationExtension.swift
//  shieldConfig
//
//  Created by Jack on 21/1/2026.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// MARK: - App Group Constants
private let appGroupID = "group.dev.zenbound.data"

// MARK: - SharedData Keys
private enum SharedDataKey {
    static let shieldConfig = "shieldConfigSnapshot"
    static let activeSession = "activeSessionSnapshot"
}

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    private var currentConfig: ShieldConfigSnapshot? {
        guard let data = userDefaults?.data(forKey: SharedDataKey.shieldConfig),
              let config = try? JSONDecoder().decode(ShieldConfigSnapshot.self, from: data) else {
            return nil
        }
        return config
    }
    
    private var sessionType: String? {
        guard let data = userDefaults?.data(forKey: SharedDataKey.activeSession),
              let snapshot = try? JSONDecoder().decode(SessionSnapshot.self, from: data) else {
            return nil
        }
        return snapshot.groupType
    }
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return buildConfiguration()
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return buildConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return buildConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return buildConfiguration()
    }
    
    // MARK: - Build Configuration
    
    private func buildConfiguration() -> ShieldConfiguration {
        let config = currentConfig
        let type = sessionType ?? "focus"
        
        // Default values based on session type
        let (defaultTitle, defaultSubtitle, defaultEmoji, defaultColor) = defaultValues(for: type)
        
        let title = config?.title ?? defaultTitle
        let subtitle = config?.message ?? defaultSubtitle
        let emoji = config?.emoji ?? defaultEmoji
        let color = hexToUIColor(config?.colorHex ?? defaultColor)
        
        // Create icon from emoji
        let icon = createEmojiIcon(emoji)
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: color.withAlphaComponent(0.9),
            icon: icon,
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .white.withAlphaComponent(0.8)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "打开 ZenBound", color: color),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(text: buttonLabel(for: type), color: .white.withAlphaComponent(0.7))
        )
    }
    
    // MARK: - Helpers
    
    private func defaultValues(for type: String) -> (String, String, String, String) {
        switch type {
        case "focus":
            return ("专注时间 🎯", "保持专注，你可以的！", "🎯", "#4A90D9")
        case "strict":
            return ("时间限制 ⏰", "今日使用时间已达上限", "⏰", "#E74C3C")
        case "entertainment":
            return ("休息一下 🌟", "该休息眼睛了", "🌟", "#27AE60")
        default:
            return ("ZenBound", "专注当下", "🧘", "#9B59B6")
        }
    }
    
    private func buttonLabel(for type: String) -> String {
        switch type {
        case "focus":
            return "继续专注"
        case "strict":
            return "紧急解锁"
        case "entertainment":
            return "延长时间"
        default:
            return "稍后再说"
        }
    }
    
    private func hexToUIColor(_ hex: String) -> UIColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        return UIColor(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
    
    private func createEmojiIcon(_ emoji: String) -> UIImage? {
        let size = CGSize(width: 60, height: 60)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40),
            .paragraphStyle: paragraphStyle
        ]
        
        let textSize = emoji.size(withAttributes: attributes)
        let rect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        emoji.draw(in: rect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - Snapshot Models

private struct ShieldConfigSnapshot: Codable {
    var title: String
    var message: String
    var colorHex: String
    var emoji: String
}

private struct SessionSnapshot: Codable {
    var groupId: String
    var groupType: String
    var activitySelectionBase64: String
    var startTime: Date
    var completedPomodoros: Int
    var totalPomodoros: Int
}
