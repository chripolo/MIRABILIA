//
//  ObservationMapper.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation

enum ObservationMapper {

    // Returns nil when the DTO lacks `taxon.id`, which makes the observation
    // unassignable to any taxon and therefore unusable in the app.
    static func observation(from dto: ObservationDTO) -> Observation? {
        guard let taxonID = dto.taxon?.id else { return nil }
        return Observation(
            id: dto.id,
            taxonID: taxonID,
            observedOn: dto.observedOn,
            placeGuess: dto.placeGuess,
            photos: photos(from: dto.photos)
        )
    }

    // MARK: - Private

    private static func photos(from dtos: [PhotoDetailDTO]?) -> [ObservationPhoto] {
        guard let dtos else { return [] }
        return dtos.compactMap { observationPhoto(from: $0) }
    }

    private static func observationPhoto(from dto: PhotoDetailDTO) -> ObservationPhoto? {
        guard let license = dto.licenseCode, PhotoPolicy.isLicenseAllowed(license) else { return nil }
        guard let squareURL = dto.url,
              let url = PhotoPolicy.mediumURL(fromSquare: squareURL) else { return nil }
        return ObservationPhoto(
            url: url,
            license: license,
            attribution: dto.attribution,
            largeURL: PhotoPolicy.largeURL(fromSquare: squareURL)
        )
    }
}
