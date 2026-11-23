//
//  TaxonResultsList.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Renders a `ResultsState`. Shared by Search, Taxon Group and Under the Radar.
struct TaxonResultsList: View {
    let state: ResultsState
    var isRefreshing = false
    var emptyMessage = "No results found."
    let retry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 120)
                .accessibilityLabel("Loading")
        case .loaded(let taxa):
            LazyVStack(spacing: 0) {
                ForEach(taxa, id: \.id) { taxon in
                    TaxonRow(taxon: taxon)
                    Divider().overlay(Palette.hairline.opacity(0.4))
                }
            }
            .opacity(isRefreshing ? 0.5 : 1)
            .overlay(alignment: .top) {
                if isRefreshing { ProgressView().padding(.top, Spacing.lg) }
            }
        case .empty:
            message(emptyMessage)
        case .failed:
            VStack(spacing: Spacing.md) {
                message("Something went wrong. Check your connection and try again.")
                Button("Try again", action: retry)
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(minWidth: Spacing.minTapTarget, minHeight: Spacing.minTapTarget)
            }
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(Typography.body)
            .foregroundStyle(Palette.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}
