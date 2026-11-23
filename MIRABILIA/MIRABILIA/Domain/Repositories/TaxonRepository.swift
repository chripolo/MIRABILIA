//
//  TaxonRepository.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

protocol TaxonRepository: Sendable {
    func search(query: String, locale: String) async throws -> [Taxon]
    func explore(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon]
    func underTheRadar(group: TaxonGroup, locale: String, page: Int) async throws -> [Taxon]
    func underTheRadar(locale: String, page: Int) async throws -> [Taxon]
}
