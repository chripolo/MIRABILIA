//
//  ObservationDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

struct ObservationDTO: Decodable {
    let id: Int
    let taxon: TaxonRef?
    let observedOn: String?
    let placeGuess: String?
    let photos: [PhotoDetailDTO]?

    struct TaxonRef: Decodable {
        let id: Int
    }
}
