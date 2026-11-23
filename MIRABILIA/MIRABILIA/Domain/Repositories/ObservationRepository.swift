//
//  ObservationRepository.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

protocol ObservationRepository: Sendable {
    func observations(taxonID: Int, locale: String, page: Int) async throws -> [Observation]
}
