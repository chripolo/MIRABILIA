//
//  ResultsViewModel.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Combine

/// Loads a single list of taxa on demand (a taxon group or Under the Radar).
@MainActor
final class ResultsViewModel: ObservableObject {
    let title: String
    let subtitle: String?
    @Published private(set) var state: ResultsState = .idle

    private let load: @Sendable () async throws -> [Taxon]

    init(title: String, subtitle: String? = nil, load: @escaping @Sendable () async throws -> [Taxon]) {
        self.title = title
        self.subtitle = subtitle
        self.load = load
    }

    static func group(_ group: TaxonGroup, repository: any TaxonRepository, locale: String) -> ResultsViewModel {
        ResultsViewModel(title: group.title) {
            try await repository.explore(group: group, locale: locale, page: 1)
        }
    }

    static func underTheRadar(repository: any TaxonRepository, locale: String) -> ResultsViewModel {
        ResultsViewModel(title: "Under the Radar", subtitle: "Fewer observations recorded on iNaturalist.") {
            try await repository.underTheRadar(locale: locale, page: 1)
        }
    }

    /// Loads once; returning from a detail screen does not refetch.
    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await reload()
    }

    func reload() async {
        if case .loading = state { return }
        state = .loading
        do {
            let taxa = try await load()
            guard !Task.isCancelled else { state = .idle; return }
            state = taxa.isEmpty ? .empty : .loaded(taxa)
        } catch {
            state = Task.isCancelled ? .idle : .failed
        }
    }
}
