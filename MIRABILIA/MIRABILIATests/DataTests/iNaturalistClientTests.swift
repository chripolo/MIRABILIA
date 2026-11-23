//
//  iNaturalistClientTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 21/11/26.
//

import Testing
import Foundation
@testable import MIRABILIA

// MARK: - Test doubles

struct MockHTTPTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}

// Collects the last request received by the transport.
actor RequestCaptor {
    private(set) var captured: URLRequest?
    func store(_ request: URLRequest) { captured = request }
}

// MARK: - Helpers

private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://api.inaturalist.org/v1/taxa")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

private let validJSON = """
{
  "total_results": 1,
  "results": [
    {
      "id": 47219,
      "name": "Apis mellifera",
      "rank": "species",
      "preferred_common_name": "Western honey bee",
      "observations_count": 1234567,
      "iconic_taxon_name": "Insecta"
    }
  ]
}
""".data(using: .utf8)!

private let emptyResultsJSON = """
{ "total_results": 0, "results": [] }
""".data(using: .utf8)!

// MARK: - Suite

@Suite("iNaturalistClient")
struct iNaturalistClientTests {

    @Test func urlAndQueryParamsAreBuiltCorrectly() async throws {
        let captor = RequestCaptor()
        let transport = MockHTTPTransport { request in
            await captor.store(request)
            return (validJSON, makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        _ = try await client.searchTaxa(query: "bee", locale: "es")

        let request = await captor.captured
        let url = try #require(request?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = try #require(components.queryItems)

        #expect(components.host == "api.inaturalist.org")
        #expect(components.path == "/v1/taxa")
        #expect(items.first(where: { $0.name == "q" })?.value == "bee")
        #expect(items.first(where: { $0.name == "locale" })?.value == "es")
        #expect(items.first(where: { $0.name == "per_page" })?.value == "25")
    }

    @Test func userAgentHeaderIsSet() async throws {
        let captor = RequestCaptor()
        let transport = MockHTTPTransport { request in
            await captor.store(request)
            return (validJSON, makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        _ = try await client.searchTaxa(query: "bee", locale: "en")

        let userAgent = await captor.captured?.value(forHTTPHeaderField: "User-Agent")
        #expect(userAgent?.isEmpty == false)
    }

    @Test func validResponseDecodesCorrectly() async throws {
        let transport = MockHTTPTransport { _ in
            (validJSON, makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        let response = try await client.searchTaxa(query: "bee", locale: "en")

        #expect(response.totalResults == 1)
        #expect(response.results.count == 1)
        let taxon = response.results[0]
        #expect(taxon.id == 47219)
        #expect(taxon.name == "Apis mellifera")
        #expect(taxon.rank == "species")
        #expect(taxon.preferredCommonName == "Western honey bee")
        #expect(taxon.observationsCount == 1_234_567)
        #expect(taxon.iconicTaxonName == "Insecta")
    }

    @Test func missingTotalResultsStillDecodes() async throws {
        let transport = MockHTTPTransport { _ in
            (Data(#"{"results":[{"id":1,"name":"A","rank":"species","observations_count":2}]}"#.utf8),
             makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        let response = try await client.searchTaxa(query: "a", locale: "en")

        #expect(response.totalResults == nil)
        #expect(response.results.map(\.id) == [1])
    }

    @Test func malformedEntryIsSkippedWithoutLosingTheRest() async throws {
        // The middle taxon has no `observations_count`; the others are valid.
        let json = #"""
        {"total_results": 3, "results": [
          {"id":1,"name":"A","rank":"species","observations_count":10},
          {"id":2,"name":"B","rank":"species"},
          {"id":3,"name":"C","rank":"species","observations_count":30}
        ]}
        """#
        let transport = MockHTTPTransport { _ in (Data(json.utf8), makeHTTPResponse(statusCode: 200)) }
        let client = iNaturalistClient(transport: transport)

        let response = try await client.searchTaxa(query: "a", locale: "en")

        #expect(response.results.map(\.id) == [1, 3])
    }

    @Test func nonObjectEntryIsSkipped() async throws {
        let transport = MockHTTPTransport { _ in
            (Data(#"{"results":[1,{"id":2,"name":"B","rank":"species","observations_count":5}]}"#.utf8),
             makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        let response = try await client.searchTaxa(query: "a", locale: "en")

        #expect(response.results.map(\.id) == [2])
    }

    @Test func httpErrorThrowsNetworkError() async throws {
        let transport = MockHTTPTransport { _ in
            (Data(), makeHTTPResponse(statusCode: 422))
        }
        let client = iNaturalistClient(transport: transport)

        do {
            _ = try await client.searchTaxa(query: "bee", locale: "en")
            Issue.record("Expected an error to be thrown")
        } catch NetworkError.httpError(let code) {
            #expect(code == 422)
        } catch {
            Issue.record("Expected NetworkError.httpError, got \(error)")
        }
    }

    @Test func malformedJSONThrowsDecodingError() async throws {
        let garbage = Data("not json".utf8)
        let transport = MockHTTPTransport { _ in
            (garbage, makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        do {
            _ = try await client.searchTaxa(query: "bee", locale: "en")
            Issue.record("Expected an error to be thrown")
        } catch NetworkError.decodingError {
            // expected path
        } catch {
            Issue.record("Expected NetworkError.decodingError, got \(error)")
        }
    }

    @Test func emptyResultsResponseDecodesCorrectly() async throws {
        let transport = MockHTTPTransport { _ in
            (emptyResultsJSON, makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        let response = try await client.searchTaxa(query: "unknown_xyz", locale: "en")

        #expect(response.totalResults == 0)
        #expect(response.results.isEmpty)
    }

    @Test func cancellationPropagates() async throws {
        let transport = MockHTTPTransport { _ in
            // Suspend long enough to be cancelled
            try await Task.sleep(nanoseconds: 30_000_000_000)
            return (validJSON, makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        let task = Task<TaxaResponseDTO, Error> {
            try await client.searchTaxa(query: "bee", locale: "en")
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    // MARK: - Species counts

    @Test func speciesCountsRequestIsBuiltWithoutPhotoFilters() async throws {
        let captor = RequestCaptor()
        let transport = MockHTTPTransport { request in
            await captor.store(request)
            return (Data(#"{"total_results":0,"results":[]}"#.utf8), makeHTTPResponse(statusCode: 200))
        }
        let client = iNaturalistClient(transport: transport)

        _ = try await client.fetchSpeciesCounts(taxonID: 3, order: "asc", perPage: 25, page: 2, locale: "es")

        let url = try #require(await captor.captured?.url)
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
        #expect(url.path == "/v1/observations/species_counts")
        #expect(query["taxon_id"] == "3")
        #expect(query["rank"] == "species")
        #expect(query["order_by"] == "observation_count")
        #expect(query["order"] == "asc")
        #expect(query["per_page"] == "25")
        #expect(query["page"] == "2")
        #expect(query["locale"] == "es")
        // Filters would make `count` diverge from the taxon's observations_count.
        #expect(query["photos"] == nil)
        #expect(query["photo_license"] == nil)
        #expect(query["quality_grade"] == nil)
    }

    @Test func speciesCountsResponseDecodesCountAndDefaultPhoto() async throws {
        let json = """
        {"total_results": 1, "results": [{"count": 1, "taxon": {
          "id": 7, "name": "Rallus aquaticus", "rank": "species",
          "preferred_common_name": "Water rail", "observations_count": 42,
          "iconic_taxon_name": "Aves",
          "default_photo": {"url": "https://x/photos/1/square.jpg", "license_code": "cc-by", "attribution": "(c) a"}
        }}]}
        """
        let transport = MockHTTPTransport { _ in (Data(json.utf8), makeHTTPResponse(statusCode: 200)) }
        let client = iNaturalistClient(transport: transport)

        let response = try await client.fetchSpeciesCounts(taxonID: 3, order: "asc", perPage: 25, page: 1, locale: "en")

        #expect(response.results[0].count == 1)
        #expect(response.results[0].taxon.observationsCount == 42)
        #expect(response.results[0].taxon.defaultPhoto?.licenseCode == "cc-by")
    }

    // MARK: - Observations (realistic response shape)

    // Mirrors a real /observations response: no top-level `taxon_id` (the id is in
    // `taxon`), extra unmodelled fields, and photos with different licenses.
    private static let observationsJSON = """
    {
      "total_results": 3,
      "page": 1,
      "per_page": 50,
      "results": [
        {
          "id": 1001,
          "uuid": "11111111-2222-3333-4444-555555555555",
          "observed_on": "2024-05-01",
          "place_guess": "Madrid, Spain",
          "license_code": "cc-by-nc",
          "user": {"id": 9, "login": "observer"},
          "taxon": {"id": 508969, "name": "Passer domesticus", "rank": "species", "iconic_taxon_name": "Aves"},
          "photos": [
            {"id": 1, "license_code": "cc-by-nc", "attribution": "(c) observer, some rights reserved (CC BY-NC)",
             "url": "https://inaturalist-open-data.s3.amazonaws.com/photos/1/square.jpg"},
            {"id": 2, "license_code": null, "attribution": "(c) observer, all rights reserved",
             "url": "https://inaturalist-open-data.s3.amazonaws.com/photos/2/square.jpg"}
          ]
        },
        {
          "id": 1002,
          "observed_on": null,
          "place_guess": null,
          "taxon": {"id": 508969},
          "photos": [
            {"id": 3, "license_code": "cc-by-nd", "attribution": "(c) other, some rights reserved (CC BY-ND)",
             "url": "https://inaturalist-open-data.s3.amazonaws.com/photos/3/square.jpeg"}
          ]
        },
        {
          "id": 1003,
          "taxon": null,
          "photos": []
        }
      ]
    }
    """

    @Test func observationsResponseDecodesNestedTaxonAndMapsValidPhotos() async throws {
        let transport = MockHTTPTransport { _ in
            (Data(Self.observationsJSON.utf8), makeHTTPResponse(statusCode: 200))
        }
        let repository = iNaturalistObservationRepository(client: iNaturalistClient(transport: transport))

        let observations = try await repository.observations(taxonID: 508969, locale: "en", page: 1)

        // The observation without `taxon` cannot be assigned to a taxon and is dropped.
        #expect(observations.map(\.id) == [1001, 1002])
        #expect(observations.map(\.taxonID) == [508969, 508969])
        #expect(observations[0].observedOn == "2024-05-01")
        #expect(observations[0].placeGuess == "Madrid, Spain")
        #expect(observations[1].observedOn == nil)

        // The photo without a license is discarded; the allowed ones keep license and attribution.
        #expect(observations[0].photos.count == 1)
        #expect(observations[0].photos[0].license == "cc-by-nc")
        #expect(observations[0].photos[0].attribution == "(c) observer, some rights reserved (CC BY-NC)")
        #expect(observations[0].photos[0].url.absoluteString == "https://inaturalist-open-data.s3.amazonaws.com/photos/1/medium.jpg")
        #expect(observations[0].photos[0].largeURL?.absoluteString == "https://inaturalist-open-data.s3.amazonaws.com/photos/1/large.jpg")
        #expect(observations[1].photos.map(\.license) == ["cc-by-nd"])
    }
}
