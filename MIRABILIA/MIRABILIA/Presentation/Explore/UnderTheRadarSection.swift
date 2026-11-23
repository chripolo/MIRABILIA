//
//  UnderTheRadarSection.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Editorial presentation of the Under the Radar collection
struct UnderTheRadarSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Under the Radar")
                        .font(Typography.sectionTitle)
                        .foregroundStyle(Palette.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Fewer observations recorded on iNaturalist.")
                        .font(Typography.supporting)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
            }

            LocalPhotoBackground(assetName: "ExploreUnderTheRadar", focus: 0.2, fallbackShowsCaption: true)
                .aspectRatio(4 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    UnderTheRadarSection()
        .padding()
        .background(Palette.background)
}
