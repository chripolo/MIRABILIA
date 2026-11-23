//
//  iNaturalistTaxonRepository.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

struct iNaturalistTaxonRepository: TaxonRepository {
    private let client: iNaturalistClient
    private let searchCache: SearchCache

    init(client: iNaturalistClient = iNaturalistClient(), searchCache: SearchCache = SearchCache()) {
        self.client = client
        self.searchCache = searchCache
    }

    func search(query: String, locale: String) async throws -> [Taxon] {
        let key = SearchCacheKey(query: query, locale: locale)
        if let cached = await searchCache.value(for: key) {
            return cached
        }

        let response = try await client.searchTaxa(query: key.query, locale: locale)
        let taxa = response.results.map { TaxonMapper.taxon(from: $0) }

        try Task.checkCancellation()
        await searchCache.set(taxa, for: key)
        return taxa
    }

    func explore(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] {
        let info = TaxonGroupIDs.info(for: group)
        let response = try await client.fetchTaxa(
            taxonID: info.taxonID,
            rank: "species",
            orderBy: "observations_count",
            order: "desc",
            perPage: 100,
            page: page,
            locale: locale
        )
        return response.results.compactMap { TaxonMapper.taxon(from: $0, expectedGroup: group) }
    }

    func underTheRadar(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon] {
        try await leastObserved(group: group, perPage: 100, locale: locale, page: page)
    }

    func underTheRadar(locale: String, page: Int) async throws -> [Taxon] {
        let groups = TaxonGroup.allCases
        let lists = try await withThrowingTaskGroup(of: (Int, [Taxon]).self) { taskGroup in
            for (index, group) in groups.enumerated() {
                taskGroup.addTask {
                    (index, try await leastObserved(group: group, perPage: 25, locale: locale, page: page))
                }
            }
            var collected = Array(repeating: [Taxon](), count: groups.count)
            for try await (index, taxa) in taskGroup { collected[index] = taxa }
            return collected
        }
        return Self.interleaved(lists)
    }

    // MARK: - Private

    private func leastObserved(group: TaxonGroup, perPage: Int, locale: String, page: Int) async throws -> [Taxon] {
        let info = TaxonGroupIDs.info(for: group)
        let response = try await client.fetchSpeciesCounts(
            taxonID: info.taxonID,
            order: "asc",
            perPage: perPage,
            page: page,
            locale: locale
        )
        return response.results.compactMap { TaxonMapper.taxon(fromSpeciesCount: $0, expectedGroup: group) }
    }

    private static func interleaved(_ lists: [[Taxon]]) -> [Taxon] {
        var result: [Taxon] = []
        let longest = lists.map(\.count).max() ?? 0
        for index in 0..<longest {
            for list in lists where index < list.count {
                result.append(list[index])
            }
        }
        return result
    }
}
