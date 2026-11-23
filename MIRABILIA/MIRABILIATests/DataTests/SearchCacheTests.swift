//
//  SearchCacheTests.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Testing
import Foundation
import os
@testable import MIRABILIA

// MARK: - Helpers

// Manually advanced clock: tests never sleep.
private final class TestClock: Sendable {
    private let current = OSAllocatedUnfairLock(initialState: Date(timeIntervalSince1970: 1_000))

    var now: @Sendable () -> Date {
        { [current] in current.withLock { $0 } }
    }

    func advance(by seconds: TimeInterval) {
        current.withLock { $0 = $0.addingTimeInterval(seconds) }
    }
}

private func makeTaxon(id: Int, name: String = "Apis mellifera") -> Taxon {
    Taxon(id: id, scientificName: name, commonName: nil, rank: "species", observationsCount: 1)
}

// MARK: - Cache (actor)

@Suite("SearchCache")
struct SearchCacheTests {

    private let key = SearchCacheKey(query: "bee", locale: "en")

    @Test func missReturnsNil() async {
        let cache = SearchCache()
        #expect(await cache.value(for: key) == nil)
    }

    @Test func hitReturnsStoredValue() async {
        let cache = SearchCache()
        await cache.set([makeTaxon(id: 1)], for: key)

        let cached = await cache.value(for: key)

        #expect(cached?.map(\.id) == [1])
    }

    @Test func defaultTTLIsThreeMinutes() {
        #expect(SearchCache.defaultTTL == 180)
    }

    @Test func entryIsValidJustBeforeTTL() async {
        let clock = TestClock()
        let cache = SearchCache(ttl: 180, now: clock.now)
        await cache.set([makeTaxon(id: 1)], for: key)

        clock.advance(by: 179)

        #expect(await cache.value(for: key) != nil)
    }

    @Test func entryExpiresAtTTL() async {
        let clock = TestClock()
        let cache = SearchCache(ttl: 180, now: clock.now)
        await cache.set([makeTaxon(id: 1)], for: key)

        clock.advance(by: 180)

        #expect(await cache.value(for: key) == nil)
    }

    @Test func customTTLIsRespected() async {
        let clock = TestClock()
        let cache = SearchCache(ttl: 10, now: clock.now)
        await cache.set([makeTaxon(id: 1)], for: key)

        clock.advance(by: 10)

        #expect(await cache.value(for: key) == nil)
    }

    @Test func settingAgainReplacesValueAndRestartsTTL() async {
        let clock = TestClock()
        let cache = SearchCache(ttl: 100, now: clock.now)
        await cache.set([makeTaxon(id: 1)], for: key)
        clock.advance(by: 90)

        await cache.set([makeTaxon(id: 2)], for: key)
        clock.advance(by: 90) // 180s since first store, 90s since update

        #expect(await cache.value(for: key)?.map(\.id) == [2])
    }

    @Test func removeValueDeletesEntry() async {
        let cache = SearchCache()
        await cache.set([makeTaxon(id: 1)], for: key)

        await cache.removeValue(for: key)

        #expect(await cache.value(for: key) == nil)
    }

    // MARK: Keys

    @Test func differentQueriesUseDifferentEntries() async {
        let cache = SearchCache()
        await cache.set([makeTaxon(id: 1)], for: SearchCacheKey(query: "bee", locale: "en"))

        #expect(await cache.value(for: SearchCacheKey(query: "wasp", locale: "en")) == nil)
    }

    @Test func differentLocalesUseDifferentEntries() async {
        let cache = SearchCache()
        await cache.set([makeTaxon(id: 1)], for: SearchCacheKey(query: "bee", locale: "en"))

        #expect(await cache.value(for: SearchCacheKey(query: "bee", locale: "es")) == nil)
    }

    @Test func surroundingWhitespaceIsNormalized() {
        #expect(SearchCacheKey(query: "  bee ", locale: "en") == SearchCacheKey(query: "bee", locale: "en"))
    }
}

// MARK: - Repository integration

private actor RequestCounter {
    private(set) var count = 0
    func increment() { count += 1 }
}

private let searchJSON = """
{
  "total_results": 1,
  "results": [
    {
      "id": 47219,
      "name": "Apis mellifera",
      "rank": "species",
      "preferred_common_name": "Western honey bee",
      "observations_count": 1234567,
      "iconic_taxon_name": "Insecta"
    }
  ]
}
""".data(using: .utf8)!

private func okResponse(status: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://api.inaturalist.org/v1/taxa")!,
        statusCode: status,
        httpVersion: nil,
        headerFields: nil
    )!
}

@Suite("iNaturalistTaxonRepository search caching")
struct SearchCachingTests {

    private func makeRepository(
        cache: SearchCache = SearchCache(),
        counter: RequestCounter,
        handler: @escaping @Sendable () async throws -> (Data, URLResponse) = { (searchJSON, okResponse()) }
    ) -> iNaturalistTaxonRepository {
        let transport = MockHTTPTransport { _ in
            await counter.increment()
            return try await handler()
        }
        return iNaturalistTaxonRepository(
            client: iNaturalistClient(transport: transport),
            searchCache: cache
        )
    }

    @Test func missCallsAPIAndStoresResult() async throws {
        let cache = SearchCache()
        let counter = RequestCounter()
        let repository = makeRepository(cache: cache, counter: counter)

        let taxa = try await repository.search(query: "bee", locale: "en")

        #expect(taxa.count == 1)
        #expect(await counter.count == 1)
        #expect(await cache.value(for: SearchCacheKey(query: "bee", locale: "en")) != nil)
    }

    @Test func hitDoesNotCallAPIAgain() async throws {
        let counter = RequestCounter()
        let repository = makeRepository(counter: counter)

        let first = try await repository.search(query: "bee", locale: "en")
        let second = try await repository.search(query: "bee", locale: "en")

        #expect(await counter.count == 1)
        #expect(first.map(\.id) == second.map(\.id))
    }

    @Test func equivalentQueryHitsSameEntry() async throws {
        let counter = RequestCounter()
        let repository = makeRepository(counter: counter)

        _ = try await repository.search(query: "bee", locale: "en")
        _ = try await repository.search(query: "  bee ", locale: "en")

        #expect(await counter.count == 1)
    }

    @Test func differentQueryOrLocaleCallsAPIAgain() async throws {
        let counter = RequestCounter()
        let repository = makeRepository(counter: counter)

        _ = try await repository.search(query: "bee", locale: "en")
        _ = try await repository.search(query: "wasp", locale: "en")
        _ = try await repository.search(query: "bee", locale: "es")

        #expect(await counter.count == 3)
    }

    @Test func expiredEntryCallsAPIAndRefreshesCache() async throws {
        let clock = TestClock()
        let cache = SearchCache(ttl: 180, now: clock.now)
        let counter = RequestCounter()
        let repository = makeRepository(cache: cache, counter: counter)

        _ = try await repository.search(query: "bee", locale: "en")
        clock.advance(by: 181)
        _ = try await repository.search(query: "bee", locale: "en")
        // The refresh restarted the TTL, so this one is a hit again.
        _ = try await repository.search(query: "bee", locale: "en")

        #expect(await counter.count == 2)
    }

    @Test func httpErrorIsNotCached() async throws {
        let cache = SearchCache()
        let counter = RequestCounter()
        let repository = makeRepository(cache: cache, counter: counter) {
            (Data(), okResponse(status: 500))
        }

        await #expect(throws: NetworkError.self) {
            try await repository.search(query: "bee", locale: "en")
        }

        #expect(await cache.value(for: SearchCacheKey(query: "bee", locale: "en")) == nil)
    }

    @Test func cancellationDuringRequestIsNotCached() async throws {
        let cache = SearchCache()
        let counter = RequestCounter()
        let repository = makeRepository(cache: cache, counter: counter) {
            throw CancellationError()
        }

        await #expect(throws: CancellationError.self) {
            try await repository.search(query: "bee", locale: "en")
        }

        #expect(await cache.value(for: SearchCacheKey(query: "bee", locale: "en")) == nil)
    }

    @Test func lateCancellationDoesNotStoreResponse() async throws {
        let cache = SearchCache()
        let counter = RequestCounter()
        // The response is valid, but the task is cancelled while the request is "in flight".
        let repository = makeRepository(cache: cache, counter: counter) {
            withUnsafeCurrentTask { $0?.cancel() }
            return (searchJSON, okResponse())
        }

        let task = Task { try await repository.search(query: "bee", locale: "en") }
        let result = await task.result

        #expect(throws: CancellationError.self) { try result.get() }
        #expect(await cache.value(for: SearchCacheKey(query: "bee", locale: "en")) == nil)
    }
}
