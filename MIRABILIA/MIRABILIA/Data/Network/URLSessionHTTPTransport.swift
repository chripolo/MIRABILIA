//
//  URLSessionHTTPTransport.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

import Foundation

struct URLSessionHTTPTransport: HTTPTransport {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
