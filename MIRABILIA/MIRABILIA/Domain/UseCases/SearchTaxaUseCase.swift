//
//  SearchTaxaUseCase.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

import Foundation

enum SearchTaxaError: Error, Sendable {
    case emptyQuery
}

struct SearchTaxaUseCase: Sendable {
    private let repository: any TaxonRepository

    init(repository: any TaxonRepository) {
        self.repository = repository
    }

    func search(query: String, locale: String) async throws -> [Taxon] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw SearchTaxaError.emptyQuery }
        return try await repository.search(query: trimmed, locale: locale)
    }
}
