//
//  Palette.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI
import UIKit

/// Semantic colours for MIRABILIA
enum Palette {

    // MARK: Semantic roles (adapt to Light / Dark)

    /// Paper / Night
    static let background = dynamic(light: 0xF7F6F0, dark: 0x101D22)
    /// Mist / Deep Surface
    static let surface = dynamic(light: 0xE8E9E1, dark: 0x1C3035)
    /// Ink / Moon
    static let textPrimary = dynamic(light: 0x242D2C, dark: 0xE9EDE7)
    /// Botanical Teal / Silver. Stone (#858D88)
    static let textSecondary = dynamic(light: 0x39766F, dark: 0xA6B2AC)
    /// Botanical Teal / Soft Teal
    static let accent = dynamic(light: 0x39766F, dark: 0x79AAA0)
    /// Stone / Muted Teal. Non-text only (hairlines, borders).
    static let hairline = dynamic(light: 0x858D88, dark: 0x30464A)

    // MARK: Fixed colours (identical in both appearances)

    static let deepOcean = Color(hex: 0x142D36)
    static let botanicalTeal = Color(hex: 0x39766F)
    static let softTeal = Color(hex: 0x79AAA0)
    static let mist = Color(hex: 0xE8E9E1)
    static let moss = Color(hex: 0x4F8A73)
    static let sage = Color(hex: 0x8DB5A0)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
