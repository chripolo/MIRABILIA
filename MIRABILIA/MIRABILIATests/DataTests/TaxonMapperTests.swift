//
//  TaxonMapperTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Testing
@testable import MIRABILIA
import Foundation

@Suite("TaxonMapper")
struct TaxonMapperTests {

    // MARK: - Helpers

    private func makePhotoDTO(
        url: String? = "https://inaturalist-open-data.s3.amazonaws.com/photos/1/square.jpg",
        licenseCode: String? = "cc-by-nc",
        attribution: String? = "(c) user"
    ) -> TaxonPhotoDTO {
        TaxonPhotoDTO(photo: PhotoDetailDTO(url: url, licenseCode: licenseCode, attribution: attribution))
    }

    private func makeDTO(
        id: Int = 1,
        name: String = "Apis mellifera",
        rank: String = "species",
        preferredCommonName: String? = "Western honey bee",
        observationsCount: Int = 1_000,
        iconicTaxonName: String? = "Insecta",
        taxonPhotos: [TaxonPhotoDTO]? = nil
    ) -> TaxonDTO {
        TaxonDTO(
            id: id,
            name: name,
            rank: rank,
            preferredCommonName: preferredCommonName,
            observationsCount: observationsCount,
            iconicTaxonName: iconicTaxonName,
            taxonPhotos: taxonPhotos
        )
    }

    // MARK: - Basic mapping (no group)

    @Test func mapsScientificNameAndRank() {
        let taxon = TaxonMapper.taxon(from: makeDTO())
        #expect(taxon.scientificName == "Apis mellifera")
        #expect(taxon.rank == "species")
    }

    @Test func mapsOptionalCommonName() {
        let taxon = TaxonMapper.taxon(from: makeDTO(preferredCommonName: "Bee"))
        #expect(taxon.commonName == "Bee")
    }

    @Test func nilCommonNamePreservedAsNil() {
        let taxon = TaxonMapper.taxon(from: makeDTO(preferredCommonName: nil))
        #expect(taxon.commonName == nil)
    }

    @Test func mapsObservationsCount() {
        let taxon = TaxonMapper.taxon(from: makeDTO(observationsCount: 42))
        #expect(taxon.observationsCount == 42)
    }

    @Test func noPhotosResultsInNilPhoto() {
        let taxon = TaxonMapper.taxon(from: makeDTO(taxonPhotos: nil))
        #expect(taxon.photo == nil)
    }

    @Test func validPhotoMapped() {
        let dto = makeDTO(taxonPhotos: [makePhotoDTO()])
        let taxon = TaxonMapper.taxon(from: dto)
        #expect(taxon.photo != nil)
        #expect(taxon.photo?.url.absoluteString.contains("/medium.") == true)
        #expect(taxon.photo?.license == "cc-by-nc")
        #expect(taxon.photo?.attribution == "(c) user")
    }

    @Test func photoWithRejectedLicenseDropped() {
        let dto = makeDTO(taxonPhotos: [makePhotoDTO(licenseCode: "all-rights-reserved")])
        let taxon = TaxonMapper.taxon(from: dto)
        #expect(taxon.photo == nil)
    }

    @Test func photoWithNilLicenseDropped() {
        let dto = makeDTO(taxonPhotos: [makePhotoDTO(licenseCode: nil)])
        let taxon = TaxonMapper.taxon(from: dto)
        #expect(taxon.photo == nil)
    }

    @Test func photoWithNilURLDropped() {
        let dto = makeDTO(taxonPhotos: [makePhotoDTO(url: nil)])
        let taxon = TaxonMapper.taxon(from: dto)
        #expect(taxon.photo == nil)
    }

    @Test func photoWithNoSquareTokenDropped() {
        let dto = makeDTO(taxonPhotos: [makePhotoDTO(url: "https://example.com/original.jpg")])
        let taxon = TaxonMapper.taxon(from: dto)
        #expect(taxon.photo == nil)
    }

    // MARK: - Group membership validation

    @Test func correctGroupMembershipReturnsNonNil() {
        let dto = makeDTO(iconicTaxonName: "Insecta")
        #expect(TaxonMapper.taxon(from: dto, expectedGroup: .insects) != nil)
    }

    @Test func wrongGroupMembershipReturnsNil() {
        let dto = makeDTO(iconicTaxonName: "Plantae")
        #expect(TaxonMapper.taxon(from: dto, expectedGroup: .insects) == nil)
    }

    @Test func nilIconicTaxonNameReturnsNil() {
        let dto = makeDTO(iconicTaxonName: nil)
        #expect(TaxonMapper.taxon(from: dto, expectedGroup: .birds) == nil)
    }

    @Test func groupIDsAreCorrect() {
        #expect(TaxonGroupIDs.info(for: .insects).taxonID == 47158)
        #expect(TaxonGroupIDs.info(for: .plants).taxonID == 47126)
        #expect(TaxonGroupIDs.info(for: .birds).taxonID == 3)
        #expect(TaxonGroupIDs.info(for: .fungi).taxonID == 47170)
    }

    @Test func allGroupsHaveIconicNames() {
        for group in TaxonGroup.allCases {
            let info = TaxonGroupIDs.info(for: group)
            #expect(!info.iconicTaxonName.isEmpty)
        }
    }

    // MARK: - Under the Radar filter (observationsCount == 0 and no photo)

    @Test func zeroObservationsDiscardedByRepository() {
        // The repository filters out count == 0; the mapper itself still maps them.
        // This test validates that taxons with 0 observations decode correctly.
        let dto = makeDTO(observationsCount: 0, iconicTaxonName: "Insecta")
        let taxon = TaxonMapper.taxon(from: dto, expectedGroup: .insects)
        #expect(taxon?.observationsCount == 0)
    }

    // MARK: - Species counts

    private func makeEntry(
        count: Int = 1,
        rank: String = "species",
        observationsCount: Int = 42,
        iconicTaxonName: String? = "Aves",
        defaultPhoto: PhotoDetailDTO? = PhotoDetailDTO(
            url: "https://inaturalist-open-data.s3.amazonaws.com/photos/1/square.jpg",
            licenseCode: "cc-by",
            attribution: "(c) user"
        )
    ) -> SpeciesCountDTO {
        var dto = makeDTO(
            rank: rank,
            observationsCount: observationsCount,
            iconicTaxonName: iconicTaxonName
        )
        dto.defaultPhoto = defaultPhoto
        return SpeciesCountDTO(count: count, taxon: dto)
    }

    @Test func speciesCountUsesTaxonObservationsCountNotCount() {
        let taxon = TaxonMapper.taxon(fromSpeciesCount: makeEntry(count: 1, observationsCount: 42), expectedGroup: .birds)
        #expect(taxon?.observationsCount == 42)
    }

    @Test func speciesCountUsesDefaultPhotoWhenAllowed() {
        let taxon = TaxonMapper.taxon(fromSpeciesCount: makeEntry(), expectedGroup: .birds)
        #expect(taxon?.photo?.url.absoluteString == "https://inaturalist-open-data.s3.amazonaws.com/photos/1/medium.jpg")
        #expect(taxon?.photo?.license == "cc-by")
    }

    @Test func speciesCountWithoutPhotoIsDiscarded() {
        #expect(TaxonMapper.taxon(fromSpeciesCount: makeEntry(defaultPhoto: nil), expectedGroup: .birds) == nil)
    }

    @Test func speciesCountWithDisallowedLicenseIsDiscarded() {
        let photo = PhotoDetailDTO(url: "https://x/photos/1/square.jpg", licenseCode: nil, attribution: nil)
        #expect(TaxonMapper.taxon(fromSpeciesCount: makeEntry(defaultPhoto: photo), expectedGroup: .birds) == nil)
    }

    @Test func speciesCountNonSpeciesRankIsDiscarded() {
        #expect(TaxonMapper.taxon(fromSpeciesCount: makeEntry(rank: "hybrid"), expectedGroup: .birds) == nil)
    }

    @Test func speciesCountOfOtherGroupIsDiscarded() {
        #expect(TaxonMapper.taxon(fromSpeciesCount: makeEntry(iconicTaxonName: "Plantae"), expectedGroup: .birds) == nil)
    }

    @Test func speciesCountWithZeroObservationsIsDiscarded() {
        #expect(TaxonMapper.taxon(fromSpeciesCount: makeEntry(observationsCount: 0), expectedGroup: .birds) == nil)
    }

    // MARK: - Group

    @Test func validatedMappingCarriesExpectedGroup() {
        let taxon = TaxonMapper.taxon(from: makeDTO(iconicTaxonName: "Aves"), expectedGroup: .birds)
        #expect(taxon?.group == .birds)
    }

    @Test func unvalidatedMappingDerivesGroupFromIconicName() {
        #expect(TaxonMapper.taxon(from: makeDTO(iconicTaxonName: "Fungi")).group == .fungi)
        #expect(TaxonMapper.taxon(from: makeDTO(iconicTaxonName: "Mammalia")).group == nil)
        #expect(TaxonMapper.taxon(from: makeDTO(iconicTaxonName: nil)).group == nil)
    }
}
