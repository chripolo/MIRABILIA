//
//  SpeciesCountsResponseDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

// Response of /observations/species_counts.
struct SpeciesCountsResponseDTO: Decodable {
    let totalResults: Int?
    let results: [SpeciesCountDTO]

    private enum CodingKeys: String, CodingKey { case totalResults, results }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalResults = try? container.decodeIfPresent(Int.self, forKey: .totalResults)
        results = try container.decode(LossyArray<SpeciesCountDTO>.self, forKey: .results).elements
    }
}
