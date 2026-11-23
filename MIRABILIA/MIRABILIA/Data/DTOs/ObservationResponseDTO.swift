//
//  ObservationResponseDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

struct ObservationResponseDTO: Decodable {
    let totalResults: Int?
    let results: [ObservationDTO]

    private enum CodingKeys: String, CodingKey { case totalResults, results }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalResults = try? container.decodeIfPresent(Int.self, forKey: .totalResults)
        results = try container.decode(LossyArray<ObservationDTO>.self, forKey: .results).elements
    }
}
