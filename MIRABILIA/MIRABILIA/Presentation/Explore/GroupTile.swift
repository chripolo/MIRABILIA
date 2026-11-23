//
//  GroupTile.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Visual tile for a taxon group. Non-interactive for now.
struct GroupTile: View {
    let group: TaxonGroup

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LocalPhotoBackground(assetName: group.imageName, focus: group.imageFocus)

            LinearGradient(
                colors: [.clear, Palette.deepOcean.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(group.title)
                .font(Typography.tileTitle)
                .foregroundStyle(Palette.mist)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(Spacing.md)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(group.title)
    }
}

private extension TaxonGroup {
    /// Asset-catalog image for this group's tile.
    var imageName: String {
        switch self {
        case .insects: "ExploreInsects"
        case .plants: "ExplorePlants"
        case .birds: "ExploreBirds"
        case .fungi: "ExploreFungi"
        }
    }

    var imageFocus: CGFloat {
        switch self {
        case .insects: 0.5
        case .plants: 0.6
        case .birds: 0.4
        case .fungi: 0.5
        }
    }
}

extension TaxonGroup {
    /// Display name used by the UI.
    var title: String {
        switch self {
        case .insects: "Insects"
        case .plants: "Plants"
        case .birds: "Birds"
        case .fungi: "Fungi"
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        ForEach(TaxonGroup.allCases, id: \.self) { GroupTile(group: $0) }
    }
    .padding()
    .background(Palette.background)
}
