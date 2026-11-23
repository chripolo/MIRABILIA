//
//  SpeciesCountDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

// One entry of /observations/species_counts
struct SpeciesCountDTO: Decodable {
    let count: Int
    let taxon: TaxonDTO
}
