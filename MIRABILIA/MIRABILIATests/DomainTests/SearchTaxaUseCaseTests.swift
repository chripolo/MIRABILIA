//
//  SearchTaxaUseCaseTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 21/11/26.
//

import Testing
@testable import MIRABILIA

// MARK: - Test doubles

struct SucceedingRepository: TaxonRepository, @unchecked Sendable {
    let results: [Taxon]

    func search(query: String, locale: String) async throws -> [Taxon] {
        results
    }

    func explore(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
    func underTheRadar(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
    func underTheRadar(locale: String, page: Int) async throws -> [Taxon] { [] }
}

actor QueryCapturingRepository: TaxonRepository {
    private(set) var capturedQuery: String?

    func search(query: String, locale: String) async throws -> [Taxon] {
        capturedQuery = query
        return []
    }

    func explore(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
    func underTheRadar(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
    func underTheRadar(locale: String, page: Int) async throws -> [Taxon] { [] }
}

// MARK: - Suite

@Suite("SearchTaxaUseCase")
struct SearchTaxaUseCaseTests {

    @Test func searchWithValidQueryReturnsResults() async throws {
        let taxon = Taxon(id: 1, scientificName: "Apis mellifera", commonName: "Honey bee", rank: "species", observationsCount: 100)
        let useCase = SearchTaxaUseCase(repository: SucceedingRepository(results: [taxon]))

        let results = try await useCase.search(query: "bee", locale: "en")

        #expect(results.count == 1)
        #expect(results[0].scientificName == "Apis mellifera")
    }

    @Test func normalizesLeadingAndTrailingSpaces() async throws {
        let repository = QueryCapturingRepository()
        let useCase = SearchTaxaUseCase(repository: repository)

        _ = try await useCase.search(query: "  bee  ", locale: "en")

        let captured = await repository.capturedQuery
        #expect(captured == "bee")
    }

    @Test func emptyQueryThrowsEmptyQueryError() async throws {
        let useCase = SearchTaxaUseCase(repository: SucceedingRepository(results: []))

        await #expect(throws: SearchTaxaError.emptyQuery) {
            _ = try await useCase.search(query: "", locale: "en")
        }
    }

    @Test func whitespaceOnlyQueryThrowsEmptyQueryError() async throws {
        let useCase = SearchTaxaUseCase(repository: SucceedingRepository(results: []))

        await #expect(throws: SearchTaxaError.emptyQuery) {
            _ = try await useCase.search(query: "   ", locale: "en")
        }
    }

    @Test func propagatesRepositoryError() async throws {
        struct RepositoryError: Error, Sendable, Equatable {}

        struct ThrowingRepository: TaxonRepository, @unchecked Sendable {
            func search(query: String, locale: String) async throws -> [Taxon] {
                throw RepositoryError()
            }
            func explore(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
            func underTheRadar(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
            func underTheRadar(locale: String, page: Int) async throws -> [Taxon] { [] }
        }

        let useCase = SearchTaxaUseCase(repository: ThrowingRepository())

        await #expect(throws: RepositoryError.self) {
            _ = try await useCase.search(query: "bee", locale: "en")
        }
    }
}
