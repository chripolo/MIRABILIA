//
//  PhotoCredit.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Author and license of a photograph, shown wherever the photo appears.
struct PhotoCredit: View {
    let attribution: String?
    let license: String
    var lineLimit: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let attribution {
                Text(attribution)
                    .lineLimit(lineLimit)
            }
            Text(PhotoLicense.displayName(license))
                .fontWeight(.semibold)
        }
        .font(Typography.caption)
        .foregroundStyle(Palette.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
