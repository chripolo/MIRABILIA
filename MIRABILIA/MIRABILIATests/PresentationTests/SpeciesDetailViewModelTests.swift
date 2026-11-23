//
//  SpeciesDetailViewModelTests.swift
//  MIRABILIATests
//
//  Created by Christian Polo on 22/11/26.
//

import Foundation
import Testing
@testable import MIRABILIA

private actor StubObservationRepository: ObservationRepository {
    private var results: [Result<[Observation], any Error>]
    private(set) var requests: [(taxonID: Int, page: Int)] = []

    var requestCount: Int { requests.count }

    /// Each call consumes the next result; the last one repeats.
    init(_ results: Result<[Observation], any Error>...) {
        self.results = results
    }

    func observations(taxonID: Int, locale: String, page: Int) async throws -> [Observation] {
        requests.append((taxonID, page))
        try? await Task.sleep(for: .milliseconds(100))
        let next = results.count > 1 ? results.removeFirst() : results[0]
        return try next.get()
    }
}

private func photo(_ id: Int) -> ObservationPhoto {
    ObservationPhoto(
        url: URL(string: "https://example.com/photos/\(id)/medium.jpg")!,
        license: "cc-by",
        attribution: "(c) author \(id)",
        largeURL: URL(string: "https://example.com/photos/\(id)/large.jpg")
    )
}

private func observation(_ id: Int, photos: [ObservationPhoto]) -> Observation {
    Observation(id: id, taxonID: 7, observedOn: nil, placeGuess: nil, photos: photos)
}

private let mainPhoto = TaxonPhoto(url: URL(string: "https://example.com/main/medium.jpg")!, license: "cc-by", attribution: "(c) main")
private let sampleTaxon = Taxon(
    id: 7, scientificName: "Rallus aquaticus", commonName: "Water rail", rank: "species",
    observationsCount: 42, photo: mainPhoto, group: .birds
)

@MainActor
@Suite("SpeciesDetailViewModel")
struct SpeciesDetailViewModelTests {

    private func makeViewModel(_ repository: StubObservationRepository) -> SpeciesDetailViewModel {
        SpeciesDetailViewModel(taxon: sampleTaxon, observations: repository, locale: "en")
    }

    @Test func loadsGalleryFromObservationsRemovingDuplicates() async {
        let repository = StubObservationRepository(.success([
            observation(1, photos: [photo(1), photo(2)]),
            observation(2, photos: [photo(2), photo(3)]),
        ]))
        let viewModel = makeViewModel(repository)

        await viewModel.loadGallery()

        guard case .loaded(let photos) = viewModel.gallery else { Issue.record("expected .loaded"); return }
        #expect(photos.map(\.url.absoluteString) == [
            "https://example.com/photos/1/medium.jpg",
            "https://example.com/photos/2/medium.jpg",
            "https://example.com/photos/3/medium.jpg",
        ])
        #expect(photos.map(\.attribution) == ["(c) author 1", "(c) author 2", "(c) author 3"])
        #expect(await repository.requests.first?.taxonID == 7)
    }

    @Test func noPhotosProducesEmptyGalleryAndKeepsIdentity() async {
        let repository = StubObservationRepository(.success([observation(1, photos: [])]))
        let viewModel = makeViewModel(repository)

        await viewModel.loadGallery()

        guard case .empty = viewModel.gallery else { Issue.record("expected .empty"); return }
        #expect(viewModel.taxon.scientificName == "Rallus aquaticus")
    }

    @Test func galleryFailureKeepsMainDataAndCanBeRetried() async {
        struct GalleryError: Error {}
        let repository = StubObservationRepository(
            .failure(GalleryError()),
            .success([observation(1, photos: [photo(1)])])
        )
        let viewModel = makeViewModel(repository)

        await viewModel.loadGallery()

        guard case .failed = viewModel.gallery else { Issue.record("expected .failed"); return }
        // Identity and main photograph are untouched by the failure.
        #expect(viewModel.taxon.id == 7)
        #expect(viewModel.taxon.commonName == "Water rail")
        #expect(viewModel.taxon.photo?.attribution == "(c) main")

        await viewModel.reloadGallery()

        guard case .loaded = viewModel.gallery else { Issue.record("expected .loaded after retry"); return }
    }

    @Test func repeatedReloadWhileLoadingDoesNotStartASecondRequest() async {
        let repository = StubObservationRepository(.success([observation(1, photos: [photo(1)])]))
        let viewModel = makeViewModel(repository)

        async let first: Void = viewModel.reloadGallery()
        async let second: Void = viewModel.reloadGallery()
        _ = await (first, second)

        #expect(await repository.requestCount == 1)
        guard case .loaded = viewModel.gallery else { Issue.record("expected .loaded"); return }
    }

    @Test func loadGalleryDoesNotRefetchOnceLoaded() async {
        let repository = StubObservationRepository(.success([observation(1, photos: [photo(1)])]))
        let viewModel = makeViewModel(repository)

        await viewModel.loadGallery()
        await viewModel.loadGallery()

        #expect(await repository.requests.count == 1)
    }

    @Test func selectingAPhotoPresentsItAndDismissClearsIt() {
        let viewModel = makeViewModel(StubObservationRepository(.success([])))
        #expect(viewModel.selectedPhoto == nil)

        viewModel.select(photo(2))
        #expect(viewModel.selectedPhoto?.attribution == "(c) author 2")
        #expect(viewModel.selectedPhoto?.largeURL?.lastPathComponent == "large.jpg")

        viewModel.dismissPhoto()
        #expect(viewModel.selectedPhoto == nil)
    }
}
