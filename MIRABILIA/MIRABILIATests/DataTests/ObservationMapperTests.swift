//
//  ObservationMapperTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation
import Testing
@testable import MIRABILIA

@Suite("ObservationMapper")
struct ObservationMapperTests {

    // MARK: - Helpers

    private func makePhotoDTO(
        url: String? = "https://inaturalist-open-data.s3.amazonaws.com/photos/9/square.jpg",
        licenseCode: String? = "cc-by",
        attribution: String? = "(c) observer"
    ) -> PhotoDetailDTO {
        PhotoDetailDTO(url: url, licenseCode: licenseCode, attribution: attribution)
    }

    private func makeObservationDTO(
        id: Int = 10,
        taxonId: Int? = 47219,
        observedOn: String? = "2024-05-01",
        placeGuess: String? = "Madrid, Spain",
        photos: [PhotoDetailDTO]? = nil
    ) -> ObservationDTO {
        ObservationDTO(id: id, taxon: taxonId.map { ObservationDTO.TaxonRef(id: $0) }, observedOn: observedOn, placeGuess: placeGuess, photos: photos)
    }

    // MARK: - Basic mapping

    @Test func mapsIdAndTaxonID() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(id: 42, taxonId: 100))
        #expect(obs?.id == 42)
        #expect(obs?.taxonID == 100)
    }

    @Test func mapsOptionalDate() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(observedOn: "2024-06-15"))
        #expect(obs?.observedOn == "2024-06-15")
    }

    @Test func nilDatePreservedAsNil() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(observedOn: nil))
        #expect(obs?.observedOn == nil)
    }

    @Test func mapsPlaceGuess() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(placeGuess: "Barcelona"))
        #expect(obs?.placeGuess == "Barcelona")
    }

    @Test func nilTaxonIDReturnsNil() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(taxonId: nil))
        #expect(obs == nil)
    }

    // MARK: - Photo mapping

    @Test func noPhotosResultsInEmptyArray() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: nil))
        #expect(obs?.photos.isEmpty == true)
    }

    @Test func emptyPhotosArrayResultsInEmptyArray() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: []))
        #expect(obs?.photos.isEmpty == true)
    }

    @Test func validPhotoMapped() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: [makePhotoDTO()]))
        #expect(obs?.photos.count == 1)
        #expect(obs?.photos.first?.url.absoluteString.contains("/medium.") == true)
        #expect(obs?.photos.first?.license == "cc-by")
        #expect(obs?.photos.first?.attribution == "(c) observer")
    }

    @Test func photoWithRejectedLicenseDropped() {
        let photo = makePhotoDTO(licenseCode: "all-rights-reserved")
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: [photo]))
        #expect(obs?.photos.isEmpty == true)
    }

    @Test func photoWithNilLicenseDropped() {
        let photo = makePhotoDTO(licenseCode: nil)
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: [photo]))
        #expect(obs?.photos.isEmpty == true)
    }

    @Test func photoWithNilURLDropped() {
        let photo = makePhotoDTO(url: nil)
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: [photo]))
        #expect(obs?.photos.isEmpty == true)
    }

    @Test func onlyValidPhotosRetained() {
        let valid = makePhotoDTO(licenseCode: "cc-by-nc")
        let invalid = makePhotoDTO(licenseCode: "all-rights-reserved")
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: [valid, invalid]))
        #expect(obs?.photos.count == 1)
    }

    // MARK: - Empty responses

    @Test func emptyResultsMappedToEmptyArray() {
        let dtos: [ObservationDTO] = []
        let result = dtos.compactMap { ObservationMapper.observation(from: $0) }
        #expect(result.isEmpty)
    }

    // MARK: - Large URL

    @Test func photoCarriesLargeURLDerivedByPolicy() {
        let obs = ObservationMapper.observation(from: makeObservationDTO(photos: [makePhotoDTO()]))
        #expect(obs?.photos.first?.largeURL?.absoluteString == "https://inaturalist-open-data.s3.amazonaws.com/photos/9/large.jpg")
    }
}
