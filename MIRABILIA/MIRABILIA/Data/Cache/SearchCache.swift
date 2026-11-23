//
//  SearchCache.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation

// Identifies a search result.
struct SearchCacheKey: Hashable, Sendable {
    let query: String
    let locale: String

    init(query: String, locale: String) {
        // Same normalization as SearchTaxaUseCase
        self.query = query.trimmingCharacters(in: .whitespaces)
        self.locale = locale
    }
}

// In-memory cache for search results. All mutable state lives inside the actor.
// Entries expire `ttl` seconds after being stored; the clock is injected so tests
// can control time without sleeping
actor SearchCache {
    static let defaultTTL: TimeInterval = 3 * 60

    private struct Entry {
        let taxa: [Taxon]
        let expiresAt: Date
    }

    private var entries: [SearchCacheKey: Entry] = [:]
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date

    init(ttl: TimeInterval = SearchCache.defaultTTL, now: @escaping @Sendable () -> Date = { Date() }) {
        self.ttl = ttl
        self.now = now
    }

    // Returns the stored value, or nil if there is none or it has expired
    func value(for key: SearchCacheKey) -> [Taxon]? {
        guard let entry = entries[key] else { return nil }
        guard now() < entry.expiresAt else {
            entries[key] = nil
            return nil
        }
        return entry.taxa
    }

    // Stores or replaces the value and restarts its TTL
    func set(_ taxa: [Taxon], for key: SearchCacheKey) {
        entries[key] = Entry(taxa: taxa, expiresAt: now().addingTimeInterval(ttl))
    }

    func removeValue(for key: SearchCacheKey) {
        entries[key] = nil
    }
}
