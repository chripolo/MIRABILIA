//
//  TaxonPhoto.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation

struct TaxonPhoto: Sendable {
    let url: URL
    let license: String
    let attribution: String?

    init(url: URL, license: String, attribution: String?) {
        self.url = url
        self.license = license
        self.attribution = attribution
    }
}
