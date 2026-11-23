//
//  SearchViewModel.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var query = ""
    @Published private(set) var state: ResultsState = .idle
    @Published private(set) var isRefreshing = false

    private(set) var searchTask: Task<Void, Never>?
    private var activeQuery: String?

    private let searchUseCase: SearchTaxaUseCase
    private let locale: String
    private let debounce: Duration

    init(searchUseCase: SearchTaxaUseCase, locale: String, debounce: Duration = .milliseconds(300)) {
        self.searchUseCase = searchUseCase
        self.locale = locale
        self.debounce = debounce
    }

    func updateQuery(_ newValue: String) {
        guard newValue != query else { return }
        query = newValue
        scheduleSearch(after: debounce)
    }

    func retry() {
        activeQuery = nil
        scheduleSearch(after: .zero)
    }

    private func scheduleSearch(after delay: Duration) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            searchTask?.cancel()
            searchTask = nil
            activeQuery = nil
            isRefreshing = false
            state = .idle
            return
        }
        guard trimmed != activeQuery else { return }

        searchTask?.cancel()
        activeQuery = trimmed
        if case .loaded = state {
            isRefreshing = true
        } else {
            state = .loading
        }

        searchTask = Task {
            // Throws when cancelled, which also drops searches superseded during the debounce.
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await performSearch(trimmed)
        }
    }

    private func performSearch(_ trimmed: String) async {
        do {
            let taxa = try await searchUseCase.search(query: trimmed, locale: locale)
            // A newer query (or clearing the field) cancelled this task: drop the result.
            guard !Task.isCancelled else { return }
            state = taxa.isEmpty ? .empty : .loaded(taxa)
        } catch {
            guard !Task.isCancelled else { return }
            activeQuery = nil
            state = .failed
        }
        isRefreshing = false
    }
}
