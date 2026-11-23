//
//  PhotoDetailDTO.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

// Shared photo structure used in both /taxa and /observations responses.
struct PhotoDetailDTO: Decodable {
    let url: String?
    let licenseCode: String?
    let attribution: String?
}
