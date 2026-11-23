//
//  iNaturalistTaxonRepositoryTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Testing
import Foundation
@testable import MIRABILIA

@Suite("iNaturalistTaxonRepository Under the Radar")
struct UnderTheRadarRepositoryTests {

    private static let iconicNames: [Int: String] = [47158: "Insecta", 47126: "Plantae", 3: "Aves", 47170: "Fungi"]

    private func entry(id: Int, iconic: String, rank: String = "species", photo: Bool = true) -> String {
        let photoJSON = photo
            ? #","default_photo": {"url": "https://x/photos/\#(id)/square.jpg", "license_code": "cc-by", "attribution": "a"}"#
            : ""
        return #"{"count": 1, "taxon": {"id": \#(id), "name": "Taxon \#(id)", "rank": "\#(rank)", "observations_count": 3, "iconic_taxon_name": "\#(iconic)"\#(photoJSON)}}"#
    }

    private func response(_ entries: [String]) -> (Data, URLResponse) {
        let json = #"{"total_results": \#(entries.count), "results": [\#(entries.joined(separator: ","))]}"#
        let http = HTTPURLResponse(url: URL(string: "https://api.inaturalist.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(json.utf8), http)
    }

    private func taxonID(of request: URLRequest) -> Int {
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Int(items.first { $0.name == "taxon_id" }?.value ?? "") ?? -1
    }

    private func makeRepository(
        _ handler: @escaping @Sendable (URLRequest) -> (Data, URLResponse)
    ) -> iNaturalistTaxonRepository {
        iNaturalistTaxonRepository(client: iNaturalistClient(transport: MockHTTPTransport { handler($0) }))
    }

    @Test func groupMethodMapsSpeciesCountsAndDropsInvalidEntries() async throws {
        let repository = makeRepository { _ in
            self.response([
                self.entry(id: 1, iconic: "Aves"),
                self.entry(id: 2, iconic: "Aves", photo: false),
                self.entry(id: 3, iconic: "Aves", rank: "genus"),
                self.entry(id: 4, iconic: "Plantae"),
            ])
        }

        let taxa = try await repository.underTheRadar(group: .birds, locale: "en", page: 1)

        #expect(taxa.map(\.id) == [1])
    }

    @Test func globalMethodQueriesEachGroupOnceAndInterleaves() async throws {
        let captor = RequestedGroups()
        let repository = makeRepository { request in
            let groupID = self.taxonID(of: request)
            captor.record(groupID)
            let iconic = Self.iconicNames[groupID] ?? ""
            // Two taxa per group, ids encode the group: 47158 -> 1x, 47126 -> 2x, 3 -> 3x, 47170 -> 4x.
            let base = ["Insecta": 10, "Plantae": 20, "Aves": 30, "Fungi": 40][iconic] ?? 0
            return self.response([self.entry(id: base + 1, iconic: iconic), self.entry(id: base + 2, iconic: iconic)])
        }

        let taxa = try await repository.underTheRadar(locale: "en", page: 1)

        #expect(captor.sorted == [3, 47126, 47158, 47170])
        // Round-robin in TaxonGroup order: insects, plants, birds, fungi, then the second of each.
        #expect(taxa.map(\.id) == [11, 21, 31, 41, 12, 22, 32, 42])
    }

    @Test func globalMethodPropagatesGroupFailure() async {
        let repository = makeRepository { request in
            let http = HTTPURLResponse(url: request.url!, statusCode: self.taxonID(of: request) == 3 ? 500 : 200, httpVersion: nil, headerFields: nil)!
            return (Data(#"{"total_results":0,"results":[]}"#.utf8), http)
        }

        await #expect(throws: NetworkError.self) {
            _ = try await repository.underTheRadar(locale: "en", page: 1)
        }
    }
}

// Thread-safe collector for the taxon IDs requested by concurrent tasks.
private final class RequestedGroups: @unchecked Sendable {
    private let lock = NSLock()
    private var ids: [Int] = []
    func record(_ id: Int) { lock.withLock { ids.append(id) } }
    var sorted: [Int] { lock.withLock { ids.sorted() } }
}
