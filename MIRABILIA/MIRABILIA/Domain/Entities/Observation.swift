//
//  Observation.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation

struct ObservationPhoto: Sendable {
    let url: URL
    let license: String
    let attribution: String?
    let largeURL: URL?

    init(url: URL, license: String, attribution: String?, largeURL: URL? = nil) {
        self.url = url
        self.license = license
        self.attribution = attribution
        self.largeURL = largeURL
    }
}

struct Observation: Sendable {
    let id: Int
    let taxonID: Int
    let observedOn: String?
    let placeGuess: String?
    let photos: [ObservationPhoto]

    init(id: Int, taxonID: Int, observedOn: String?, placeGuess: String?, photos: [ObservationPhoto]) {
        self.id = id
        self.taxonID = taxonID
        self.observedOn = observedOn
        self.placeGuess = placeGuess
        self.photos = photos
    }
}
