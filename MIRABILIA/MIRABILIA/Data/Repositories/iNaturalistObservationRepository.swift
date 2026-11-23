//
//  iNaturalistObservationRepository.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

struct iNaturalistObservationRepository: ObservationRepository {
    private let client: iNaturalistClient

    init(client: iNaturalistClient = iNaturalistClient()) {
        self.client = client
    }

    func observations(taxonID: Int, locale: String, page: Int) async throws -> [Observation] {
        let response = try await client.fetchObservations(taxonID: taxonID, locale: locale, page: page)
        return response.results.compactMap { ObservationMapper.observation(from: $0) }
    }
}
