//
//  ResultsScreen.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Pushed screen for a taxon group or Under the Radar. Loads on demand.
struct ResultsScreen: View {
    @StateObject private var viewModel: ResultsViewModel

    init(viewModel: ResultsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .font(Typography.supporting)
                        .foregroundStyle(Palette.textSecondary)
                }
                TaxonResultsList(state: viewModel.state) {
                    Task { await viewModel.reload() }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
    }
}
