//
//  SearchViewModelTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Testing
@testable import MIRABILIA

// MARK: - Test doubles (shared with ResultsViewModelTests)

struct PresentationTestError: Error, Sendable {}

func presentationTaxon(_ id: Int) -> Taxon {
    Taxon(id: id, scientificName: "Taxon \(id)", commonName: nil, rank: "species", observationsCount: 1)
}

/// Returns canned results and records the calls it receives.
actor StubTaxonRepository: TaxonRepository {
    private let searchResult: Result<[Taxon], any Error>
    private let listResult: Result<[Taxon], any Error>

    private(set) var searchedQueries: [String] = []
    private(set) var exploredGroups: [TaxonGroup] = []
    private(set) var groupRadarCalls = 0
    private(set) var globalRadarCalls = 0

    init(
        searchResult: Result<[Taxon], any Error> = .success([]),
        listResult: Result<[Taxon], any Error> = .success([])
    ) {
        self.searchResult = searchResult
        self.listResult = listResult
    }

    func search(query: String, locale: String) async throws -> [Taxon] {
        searchedQueries.append(query)
        return try searchResult.get()
    }

    func explore(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] {
        exploredGroups.append(group)
        return try listResult.get()
    }

    func underTheRadar(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] {
        groupRadarCalls += 1
        return try listResult.get()
    }

    func underTheRadar(locale: String, page: Int) async throws -> [Taxon] {
        globalRadarCalls += 1
        return try listResult.get()
    }
}

/// Search suspends until the test resolves each query, so tests control response order.
/// It ignores cancellation on purpose to model a response arriving after being superseded.
actor GatedSearchRepository: TaxonRepository {
    private var pending: [String: CheckedContinuation<[Taxon], any Error>] = [:]
    private var started: Set<String> = []

    func search(query: String, locale: String) async throws -> [Taxon] {
        started.insert(query)
        return try await withCheckedThrowingContinuation { pending[query] = $0 }
    }

    func finish(_ query: String, with taxa: [Taxon]) {
        pending.removeValue(forKey: query)?.resume(returning: taxa)
    }

    func waitUntilStarted(_ query: String) async {
        for _ in 0..<10_000 where !started.contains(query) { await Task.yield() }
    }

    func explore(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
    func underTheRadar(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] { [] }
    func underTheRadar(locale: String, page: Int) async throws -> [Taxon] { [] }
}

// MARK: - Suite

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {

    private func makeViewModel(_ repository: any TaxonRepository) -> SearchViewModel {
        // Zero debounce: superseded searches are still dropped by cancellation, without real sleeps.
        SearchViewModel(searchUseCase: SearchTaxaUseCase(repository: repository), locale: "en", debounce: .zero)
    }

    @Test func successfulSearchLoadsResults() async {
        let repository = StubTaxonRepository(searchResult: .success([presentationTaxon(1)]))
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("bee")
        await viewModel.searchTask?.value

        guard case .loaded(let taxa) = viewModel.state else { Issue.record("expected .loaded"); return }
        #expect(taxa.map(\.id) == [1])
        #expect(await repository.searchedQueries == ["bee"])
    }

    @Test func blankQueryNeverSearches() async {
        let repository = StubTaxonRepository()
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("   ")
        await viewModel.searchTask?.value

        guard case .idle = viewModel.state else { Issue.record("expected .idle"); return }
        #expect(viewModel.searchTask == nil)
        #expect(await repository.searchedQueries.isEmpty)
    }

    @Test func noMatchesProducesEmptyState() async {
        let viewModel = makeViewModel(StubTaxonRepository(searchResult: .success([])))

        viewModel.updateQuery("zzz")
        await viewModel.searchTask?.value

        guard case .empty = viewModel.state else { Issue.record("expected .empty"); return }
    }

    @Test func rapidTypingOnlySearchesTheLatestQuery() async {
        let repository = StubTaxonRepository(searchResult: .success([presentationTaxon(1)]))
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("b")
        viewModel.updateQuery("be")
        viewModel.updateQuery("bee")
        await viewModel.searchTask?.value

        #expect(await repository.searchedQueries == ["bee"])
    }

    @Test func staleResponseDoesNotOverwriteNewerResults() async {
        let repository = GatedSearchRepository()
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("a")
        let first = viewModel.searchTask
        await repository.waitUntilStarted("a")
        viewModel.updateQuery("ab")
        let second = viewModel.searchTask
        await repository.waitUntilStarted("ab")

        await repository.finish("ab", with: [presentationTaxon(2)])
        await second?.value
        // The superseded request answers last.
        await repository.finish("a", with: [presentationTaxon(1)])
        await first?.value

        guard case .loaded(let taxa) = viewModel.state else { Issue.record("expected .loaded"); return }
        #expect(taxa.map(\.id) == [2])
    }

    @Test func failureShowsErrorAndRetryRepeatsTheSearch() async {
        let repository = StubTaxonRepository(searchResult: .failure(PresentationTestError()))
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("bee")
        await viewModel.searchTask?.value
        guard case .failed = viewModel.state else { Issue.record("expected .failed"); return }

        viewModel.retry()
        await viewModel.searchTask?.value

        #expect(await repository.searchedQueries == ["bee", "bee"])
    }

    @Test func clearingQueryResetsStateAndDiscardsInFlightResult() async {
        let repository = GatedSearchRepository()
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("a")
        let inFlight = viewModel.searchTask
        await repository.waitUntilStarted("a")
        viewModel.updateQuery("")

        guard case .idle = viewModel.state else { Issue.record("expected .idle"); return }
        await repository.finish("a", with: [presentationTaxon(1)])
        await inFlight?.value

        guard case .idle = viewModel.state else { Issue.record("late result must be discarded"); return }
        #expect(!viewModel.isRefreshing)
    }

    @Test func identicalTrimmedQueryDoesNotRepeatTheRequest() async {
        let repository = StubTaxonRepository(searchResult: .success([presentationTaxon(1)]))
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("bee")
        await viewModel.searchTask?.value
        viewModel.updateQuery("bee ")
        await viewModel.searchTask?.value

        #expect(await repository.searchedQueries == ["bee"])
    }

    @Test func newSearchKeepsPreviousResultsVisibleWhileRefreshing() async {
        let repository = GatedSearchRepository()
        let viewModel = makeViewModel(repository)

        viewModel.updateQuery("a")
        await repository.waitUntilStarted("a")
        await repository.finish("a", with: [presentationTaxon(1)])
        await viewModel.searchTask?.value

        viewModel.updateQuery("ab")

        #expect(viewModel.isRefreshing)
        if case .loaded = viewModel.state {} else { Issue.record("expected previous results") }

        // Let the pending request finish so no continuation is left dangling.
        await repository.waitUntilStarted("ab")
        await repository.finish("ab", with: [])
        await viewModel.searchTask?.value
    }
}
