//
//  NetworkError.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

enum NetworkError: Error, Sendable {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(Error)
}
