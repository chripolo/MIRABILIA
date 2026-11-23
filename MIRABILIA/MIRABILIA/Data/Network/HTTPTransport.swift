//
//  HTTPTransport.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

import Foundation

protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
