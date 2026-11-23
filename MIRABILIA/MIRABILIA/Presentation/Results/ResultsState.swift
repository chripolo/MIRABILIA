//
//  ResultsState.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

enum ResultsState {
    case idle
    case loading
    case loaded([Taxon])
    case empty
    case failed
}
