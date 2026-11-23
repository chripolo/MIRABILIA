//
//  TaxonMapper.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation

enum TaxonMapper {

    static func taxon(from dto: TaxonDTO, expectedGroup: TaxonGroup) -> Taxon? {
        let groupInfo = TaxonGroupIDs.info(for: expectedGroup)
        guard dto.iconicTaxonName == groupInfo.iconicTaxonName else { return nil }
        return Taxon(
            id: dto.id,
            scientificName: dto.name,
            commonName: dto.preferredCommonName,
            rank: dto.rank,
            observationsCount: dto.observationsCount,
            photo: photo(from: dto),
            group: expectedGroup
        )
    }

    // Maps one /observations/species_counts entry to a Domain Taxon, or nil when the
    // entry is not a species of `expectedGroup` or has no displayable photo.
    //
    // Observation-count semantics: `entry.count` is the number of observations
    // matching the species_counts query (used only by the API to order results),
    // while `entry.taxon.observationsCount` is the taxon's total on iNaturalist.
    // They were measured to agree for most taxa when the query has no photo or
    // quality filters, but they are not guaranteed to be identical. The two are not
    // mixed: the Domain value always comes from `taxon.observationsCount`, the same
    // field used by search and group exploration.
    static func taxon(fromSpeciesCount entry: SpeciesCountDTO, expectedGroup: TaxonGroup) -> Taxon? {
        guard entry.taxon.rank == "species", entry.taxon.observationsCount > 0 else { return nil }
        guard let taxon = taxon(from: entry.taxon, expectedGroup: expectedGroup),
              taxon.photo != nil else { return nil }
        return taxon
    }

    // Maps a DTO to a Domain Taxon without group validation (used for search results).
    static func taxon(from dto: TaxonDTO) -> Taxon {
        Taxon(
            id: dto.id,
            scientificName: dto.name,
            commonName: dto.preferredCommonName,
            rank: dto.rank,
            observationsCount: dto.observationsCount,
            photo: photo(from: dto),
            group: TaxonGroupIDs.group(forIconicName: dto.iconicTaxonName)
        )
    }

    // MARK: - Private

    private static func photo(from dto: TaxonDTO) -> TaxonPhoto? {
        guard let detail = dto.taxonPhotos?.first?.photo ?? dto.defaultPhoto else { return nil }
        guard let license = detail.licenseCode, PhotoPolicy.isLicenseAllowed(license) else { return nil }
        guard let squareURL = detail.url,
              let url = PhotoPolicy.mediumURL(fromSquare: squareURL) else { return nil }
        return TaxonPhoto(
            url: url,
            license: license,
            attribution: detail.attribution
        )
    }
}
