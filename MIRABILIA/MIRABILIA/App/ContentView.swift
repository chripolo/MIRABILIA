//
//  ContentView.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

import SwiftUI

struct ContentView: View {
    let repository: any TaxonRepository
    let observationRepository: any ObservationRepository
    let locale: String

    var body: some View {
        ExploreView(repository: repository, observationRepository: observationRepository, locale: locale)
    }
}

#Preview {
    ContentView(
        repository: iNaturalistTaxonRepository(),
        observationRepository: iNaturalistObservationRepository(),
        locale: "en"
    )
}
