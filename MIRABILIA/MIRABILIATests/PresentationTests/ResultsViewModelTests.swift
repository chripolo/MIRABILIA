//
//  ResultsViewModelTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Testing
@testable import MIRABILIA

private actor FlakyLoader {
    private var calls = 0
    func next() throws -> [Taxon] {
        calls += 1
        if calls == 1 { throw PresentationTestError() }
        return [presentationTaxon(1)]
    }
}

private actor SlowLoader {
    private(set) var calls = 0
    func next() async throws -> [Taxon] {
        calls += 1
        try await Task.sleep(for: .milliseconds(100))
        return [presentationTaxon(1)]
    }
}

@MainActor
@Suite("ResultsViewModel")
struct ResultsViewModelTests {

    @Test func groupLoadsOnlyThatGroupOnDemand() async {
        let repository = StubTaxonRepository(listResult: .success([presentationTaxon(1)]))
        let viewModel = ResultsViewModel.group(.birds, repository: repository, locale: "en")

        guard case .idle = viewModel.state else { Issue.record("must not load before being opened"); return }
        #expect(await repository.exploredGroups.isEmpty)

        await viewModel.loadIfNeeded()

        #expect(viewModel.title == "Birds")
        #expect(await repository.exploredGroups == [.birds])
        guard case .loaded(let taxa) = viewModel.state else { Issue.record("expected .loaded"); return }
        #expect(taxa.map(\.id) == [1])
    }

    @Test func underTheRadarUsesTheGlobalOperation() async {
        let repository = StubTaxonRepository(listResult: .success([presentationTaxon(1)]))
        let viewModel = ResultsViewModel.underTheRadar(repository: repository, locale: "en")

        await viewModel.loadIfNeeded()

        #expect(await repository.globalRadarCalls == 1)
        #expect(await repository.groupRadarCalls == 0)
        #expect(viewModel.subtitle == "Fewer observations recorded on iNaturalist.")
    }

    @Test func emptyListProducesEmptyState() async {
        let viewModel = ResultsViewModel.group(.fungi, repository: StubTaxonRepository(), locale: "en")

        await viewModel.loadIfNeeded()

        guard case .empty = viewModel.state else { Issue.record("expected .empty"); return }
    }

    @Test func failureCanBeRetried() async {
        let loader = FlakyLoader()
        let viewModel = ResultsViewModel(title: "Test") { try await loader.next() }

        await viewModel.loadIfNeeded()
        guard case .failed = viewModel.state else { Issue.record("expected .failed"); return }

        await viewModel.reload()
        guard case .loaded = viewModel.state else { Issue.record("expected .loaded"); return }
    }

    @Test func repeatedReloadWhileLoadingDoesNotStartASecondLoad() async {
        let loader = SlowLoader()
        let viewModel = ResultsViewModel(title: "Test") { try await loader.next() }

        async let first: Void = viewModel.reload()
        async let second: Void = viewModel.reload()
        _ = await (first, second)

        #expect(await loader.calls == 1)
        guard case .loaded = viewModel.state else { Issue.record("expected .loaded"); return }
    }

    @Test func loadIfNeededDoesNotRefetchOnReturn() async {
        let repository = StubTaxonRepository(listResult: .success([presentationTaxon(1)]))
        let viewModel = ResultsViewModel.group(.plants, repository: repository, locale: "en")

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(await repository.exploredGroups.count == 1)
    }
}
