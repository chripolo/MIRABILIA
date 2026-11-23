//
//  SpeciesRoute.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

/// Navigation value for Species Detail. The taxon id is its identity; the taxon
/// travels along so the detail can show it immediately, without another request.
struct SpeciesRoute: Hashable {
    let taxon: Taxon

    static func == (lhs: SpeciesRoute, rhs: SpeciesRoute) -> Bool {
        lhs.taxon.id == rhs.taxon.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(taxon.id)
    }
}
