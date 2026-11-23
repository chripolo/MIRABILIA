//
//  iNaturalistClient.swift
//  MIRABILIA
//
//  Created by Christian Polo on 21/11/26.
//

import Foundation

struct iNaturalistClient: Sendable {
    private static let baseURL = "https://api.inaturalist.org/v1"
    private static let userAgent = "MIRABILIA/1.0 (iOS)"

    private let transport: any HTTPTransport

    init(transport: any HTTPTransport = URLSessionHTTPTransport()) {
        self.transport = transport
    }

    // MARK: - Taxa

    func searchTaxa(query: String, locale: String) async throws -> TaxaResponseDTO {
        guard var components = URLComponents(string: "\(Self.baseURL)/taxa") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "per_page", value: "25"),
        ]
        return try await get(components: components, as: TaxaResponseDTO.self)
    }

    func fetchTaxa(
        taxonID: Int,
        rank: String,
        orderBy: String,
        order: String,
        perPage: Int,
        page: Int,
        locale: String
    ) async throws -> TaxaResponseDTO {
        guard var components = URLComponents(string: "\(Self.baseURL)/taxa") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "taxon_id", value: String(taxonID)),
            URLQueryItem(name: "rank", value: rank),
            URLQueryItem(name: "order_by", value: orderBy),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "locale", value: locale),
        ]
        return try await get(components: components, as: TaxaResponseDTO.self)
    }

    // MARK: - Species counts

    // Deliberately sends no `photos`/`photo_license`/`quality_grade` filters: with them,
    // `count` only measures filtered observations and diverges from the taxon's total.
    // Photo eligibility is enforced afterwards through TaxonMapper and PhotoPolicy.
    func fetchSpeciesCounts(
        taxonID: Int,
        order: String,
        perPage: Int,
        page: Int,
        locale: String
    ) async throws -> SpeciesCountsResponseDTO {
        guard var components = URLComponents(string: "\(Self.baseURL)/observations/species_counts") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "taxon_id", value: String(taxonID)),
            URLQueryItem(name: "rank", value: "species"),
            URLQueryItem(name: "order_by", value: "observation_count"),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "locale", value: locale),
        ]
        return try await get(components: components, as: SpeciesCountsResponseDTO.self)
    }

    // MARK: - Observations

    func fetchObservations(taxonID: Int, locale: String, page: Int) async throws -> ObservationResponseDTO {
        guard var components = URLComponents(string: "\(Self.baseURL)/observations") else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "taxon_id", value: String(taxonID)),
            URLQueryItem(name: "photos", value: "true"),
            URLQueryItem(name: "photo_license", value: PhotoPolicy.allowedLicensesQueryValue),
            URLQueryItem(name: "per_page", value: "50"),
            URLQueryItem(name: "order_by", value: "observed_on"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "page", value: String(page)),
        ]
        return try await get(components: components, as: ObservationResponseDTO.self)
    }

    // MARK: - Private

    private func get<T: Decodable>(components: URLComponents, as type: T.Type) async throws -> T {
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await transport.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.httpError(statusCode: 0)
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.httpError(statusCode: http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
