//
//  MIRABILIAApp.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

import SwiftUI

@main
struct MIRABILIAApp: App {
    private let repository = iNaturalistTaxonRepository()
    private let observationRepository = iNaturalistObservationRepository()
    private let locale = Locale.current.language.languageCode?.identifier ?? "en"

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository, observationRepository: observationRepository, locale: locale)
        }
    }
}
