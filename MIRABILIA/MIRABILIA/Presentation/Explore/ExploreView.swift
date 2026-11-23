//
//  ExploreView.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

private enum ExploreDestination: Hashable {
    case group(TaxonGroup)
    case underTheRadar
}

/// Home screen and root of the navigation stack. Static content renders
/// immediately; the network is only used when the user searches or opens a list.
struct ExploreView: View {
    private let repository: any TaxonRepository
    private let observationRepository: any ObservationRepository
    private let locale: String
    @StateObject private var search: SearchViewModel
    @FocusState private var searchFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    init(repository: any TaxonRepository, observationRepository: any ObservationRepository, locale: String) {
        self.repository = repository
        self.observationRepository = observationRepository
        self.locale = locale
        _search = StateObject(wrappedValue: SearchViewModel(
            searchUseCase: SearchTaxaUseCase(repository: repository),
            locale: locale
        ))
    }

    private var isSearching: Bool {
        if case .idle = search.state { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    BrandHeader()

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Look closer.")
                            .font(Typography.display)
                            .foregroundStyle(Palette.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text("A world of extraordinary life awaits.")
                            .font(Typography.body)
                            .foregroundStyle(Palette.textSecondary)
                    }

                    SearchField(
                        text: Binding(
                            get: { search.query },
                            set: { search.updateQuery($0) }
                        ),
                        isFocused: $searchFocused
                    )

                    if isSearching {
                        TaxonResultsList(
                            state: search.state,
                            isRefreshing: search.isRefreshing,
                            emptyMessage: "No organisms found for this search."
                        ) { search.retry() }
                    } else {
                        browseContent
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.lg)
                // Tapping empty space hides the keyboard. The tap target sits *behind* the
                // content, so the text field, links and buttons receive their own touches.
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { searchFocused = false }
                }
            }
            // Scrolling hides the keyboard. The query is kept.
            .scrollDismissesKeyboard(.immediately)
            .background(Palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ExploreDestination.self) { destination in
                switch destination {
                case .group(let group):
                    ResultsScreen(viewModel: .group(group, repository: repository, locale: locale))
                case .underTheRadar:
                    ResultsScreen(viewModel: .underTheRadar(repository: repository, locale: locale))
                }
            }
            .navigationDestination(for: SpeciesRoute.self) { route in
                SpeciesDetailView(viewModel: SpeciesDetailViewModel(
                    taxon: route.taxon,
                    observations: observationRepository,
                    locale: locale
                ))
            }
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(TaxonGroup.allCases, id: \.self) { group in
                NavigationLink(value: ExploreDestination.group(group)) {
                    GroupTile(group: group)
                }
                .buttonStyle(.plain)
            }
        }

        NavigationLink(value: ExploreDestination.underTheRadar) {
            UnderTheRadarSection()
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    ExploreView(repository: iNaturalistTaxonRepository(), observationRepository: iNaturalistObservationRepository(), locale: "en")
}

#Preview("Dark") {
    ExploreView(repository: iNaturalistTaxonRepository(), observationRepository: iNaturalistObservationRepository(), locale: "en").preferredColorScheme(.dark)
}
