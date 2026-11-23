//
//  SpeciesDetailViewModel.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import Combine
import Foundation

enum GalleryState {
    case idle
    case loading
    case loaded([ObservationPhoto])
    case empty
    case failed
}

/// The taxon (identity and main photo) is known on arrival; only the gallery is
/// fetched, so a gallery failure never hides what is already shown.
@MainActor
final class SpeciesDetailViewModel: ObservableObject {
    let taxon: Taxon
    @Published private(set) var gallery: GalleryState = .idle
    @Published private(set) var selectedPhoto: ObservationPhoto?

    private let observations: any ObservationRepository
    private let locale: String

    init(taxon: Taxon, observations: any ObservationRepository, locale: String) {
        self.taxon = taxon
        self.observations = observations
        self.locale = locale
    }

    func loadGallery() async {
        guard case .idle = gallery else { return }
        await reloadGallery()
    }

    func reloadGallery() async {
        if case .loading = gallery { return }
        gallery = .loading
        do {
            let found = try await observations.observations(taxonID: taxon.id, locale: locale, page: 1)
            guard !Task.isCancelled else { gallery = .idle; return }
            let photos = Self.uniquePhotos(found.flatMap(\.photos))
            gallery = photos.isEmpty ? .empty : .loaded(photos)
        } catch {
            gallery = Task.isCancelled ? .idle : .failed
        }
    }

    func select(_ photo: ObservationPhoto) {
        selectedPhoto = photo
    }

    func dismissPhoto() {
        selectedPhoto = nil
    }

    private static func uniquePhotos(_ photos: [ObservationPhoto]) -> [ObservationPhoto] {
        var seen = Set<URL>()
        return photos.filter { seen.insert($0.url).inserted }
    }
}

extension ObservationPhoto: Identifiable {
    var id: URL { url }
}
