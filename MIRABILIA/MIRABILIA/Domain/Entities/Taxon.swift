//
//  Taxon.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

struct Taxon: Sendable {
    let id: Int
    let scientificName: String
    let commonName: String?
    let rank: String
    let observationsCount: Int
    let photo: TaxonPhoto?
    let group: TaxonGroup?

    init(
        id: Int,
        scientificName: String,
        commonName: String?,
        rank: String,
        observationsCount: Int,
        photo: TaxonPhoto? = nil,
        group: TaxonGroup? = nil
    ) {
        self.id = id
        self.scientificName = scientificName
        self.commonName = commonName
        self.rank = rank
        self.observationsCount = observationsCount
        self.photo = photo
        self.group = group
    }
}
