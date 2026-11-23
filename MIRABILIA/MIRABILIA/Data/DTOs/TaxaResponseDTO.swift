//
//  TaxaResponseDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

struct TaxaResponseDTO: Decodable {
    let totalResults: Int?
    let results: [TaxonDTO]

    private enum CodingKeys: String, CodingKey { case totalResults, results }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalResults = try? container.decodeIfPresent(Int.self, forKey: .totalResults)
        results = try container.decode(LossyArray<TaxonDTO>.self, forKey: .results).elements
    }
}

// Decodes a JSON array element by element and drops the ones that fail, so a single
// malformed entry from iNaturalist does not discard the rest of the list.
struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]

    private struct Skip: Decodable {}

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        while !container.isAtEnd {
            do {
                elements.append(try container.decode(Element.self))
            } catch {
                // Advances past the bad element (an empty Decodable accepts any JSON value).
                _ = try container.decode(Skip.self)
            }
        }
        self.elements = elements
    }
}
