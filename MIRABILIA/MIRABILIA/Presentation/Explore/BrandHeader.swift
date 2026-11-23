//
//  BrandHeader.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

struct BrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("MIRABILIA")
                .font(Typography.wordmark)
                .tracking(4)
                .foregroundStyle(Palette.textPrimary)
            Rectangle()
                .fill(Palette.hairline)
                .frame(width: Spacing.xxl, height: 1)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    BrandHeader()
        .padding()
        .background(Palette.background)
}
