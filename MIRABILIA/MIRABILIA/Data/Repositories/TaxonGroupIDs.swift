//
//  TaxonGroupIDs.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

enum TaxonGroupIDs {

    struct GroupInfo {
        let taxonID: Int
        let iconicTaxonName: String

        init(taxonID: Int, iconicTaxonName: String) {
            self.taxonID = taxonID
            self.iconicTaxonName = iconicTaxonName
        }
    }

    static func info(for group: TaxonGroup) -> GroupInfo {
        switch group {
        case .insects: return GroupInfo(taxonID: 47158, iconicTaxonName: "Insecta")
        case .plants:  return GroupInfo(taxonID: 47126, iconicTaxonName: "Plantae")
        case .birds:   return GroupInfo(taxonID: 3,     iconicTaxonName: "Aves")
        case .fungi:   return GroupInfo(taxonID: 47170, iconicTaxonName: "Fungi")
        }
    }

    static func group(forIconicName name: String?) -> TaxonGroup? {
        guard let name else { return nil }
        return TaxonGroup.allCases.first { info(for: $0).iconicTaxonName == name }
    }
}
