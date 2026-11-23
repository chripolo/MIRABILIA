//
//  RemotePhoto.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Remote photograph that respects its license: ND photos are shown whole
/// (letterboxed); others fill the container. Falls back to the editorial artwork.
struct RemotePhoto: View {
    let url: URL
    let license: String

    var body: some View {
        Palette.surface
            .overlay {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        if PhotoLicense.forbidsDerivatives(license) {
                            image.resizable().scaledToFit()
                        } else {
                            image.resizable().scaledToFill()
                        }
                    case .failure:
                        EditorialFallbackView(showsCaption: false)
                    default:
                        ProgressView()
                    }
                }
            }
            .clipped()
    }
}
