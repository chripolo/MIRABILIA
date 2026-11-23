//
//  TaxonPhotoDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

// Represents one entry in the `taxon_photos` array of a taxon response.
struct TaxonPhotoDTO: Decodable {
    let photo: PhotoDetailDTO
}
