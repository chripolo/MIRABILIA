//
//  Typography.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

enum Typography {
    // Serif (New York)
    static let wordmark = Font.system(.subheadline, design: .serif).weight(.semibold)
    static let display = Font.system(.largeTitle, design: .serif).weight(.medium)
    static let sectionTitle = Font.system(.title2, design: .serif)
    static let tileTitle = Font.system(.title3, design: .serif)
    static let fallbackTitle = Font.system(.title3, design: .serif).italic()
    static let rowTitle = Font.system(.headline, design: .serif)

    // SF Pro
    static let body = Font.body
    static let supporting = Font.subheadline
    static let rowSubtitle = Font.footnote.italic()
    static let caption = Font.caption
    static let overline = Font.caption2.weight(.semibold)
}
