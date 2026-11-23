//
//  TaxonRow.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Compact row for a taxon: photo first, then names and observation count.
/// Must be shown inside a NavigationStack that handles `SpeciesRoute`.
struct TaxonRow: View {
    let taxon: Taxon

    private var primaryName: String { taxon.commonName ?? taxon.scientificName }

    private var observationsText: String {
        let count = taxon.observationsCount
        return "\(count.formatted()) \(count == 1 ? "observation" : "observations")"
    }

    var body: some View {
        NavigationLink(value: SpeciesRoute(taxon: taxon)) {
            HStack(spacing: Spacing.md) {
                thumbnail
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(primaryName)
                        .font(Typography.rowTitle)
                        .foregroundStyle(Palette.textPrimary)
                    if taxon.commonName != nil {
                        Text(taxon.scientificName)
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    Text(observationsText)
                        .font(Typography.supporting)
                        .foregroundStyle(Palette.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Spacing.minTapTarget)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let photo = taxon.photo {
            RemotePhoto(url: photo.url, license: photo.license)
        } else {
            EditorialFallbackView(showsCaption: false)
        }
    }

    private var accessibilityLabel: String {
        var parts = [primaryName]
        if taxon.commonName != nil { parts.append(taxon.scientificName) }
        parts.append(observationsText)
        return parts.joined(separator: ", ")
    }
}

#Preview {
    VStack {
        TaxonRow(taxon: Taxon(id: 1, scientificName: "Apis mellifera", commonName: "Western honey bee", rank: "species", observationsCount: 1_234_567))
        TaxonRow(taxon: Taxon(id: 2, scientificName: "Mycena aciculata", commonName: nil, rank: "species", observationsCount: 1))
    }
    .padding()
    .background(Palette.background)
}
