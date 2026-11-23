//
//  TaxonDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

struct TaxonDTO: Decodable {
    let id: Int
    let name: String
    let rank: String
    let preferredCommonName: String?
    let observationsCount: Int
    let iconicTaxonName: String?
    let taxonPhotos: [TaxonPhotoDTO]?
    var defaultPhoto: PhotoDetailDTO? = nil
}
