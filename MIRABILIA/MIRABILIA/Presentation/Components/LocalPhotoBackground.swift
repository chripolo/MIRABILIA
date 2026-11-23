//
//  LocalPhotoBackground.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI
import UIKit

/// Full-bleed local photograph from the asset catalog, cropped to fill its container.
/// Falls back to the editorial artwork when the asset is missing.
///
/// `focus` positions the visible window along the horizontal slack of the crop:
/// 0 shows the left edge of the image, 1 the right edge, 0.5 the centre.
/// The container's size never depends on the image (it is drawn inside a `GeometryReader`
/// over a flat base), so it cannot widen the layout.
struct LocalPhotoBackground: View {
    let assetName: String
    var focus: CGFloat = 0.5
    var fallbackShowsCaption = false

    var body: some View {
        if let image = UIImage(named: assetName) {
            Palette.deepOcean
                .overlay { photo(image) }
                .clipped()
                .accessibilityHidden(true)
        } else {
            EditorialFallbackView(showsCaption: fallbackShowsCaption)
        }
    }

    private func photo(_ image: UIImage) -> some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / image.size.width, geo.size.height / image.size.height)
            let width = image.size.width * scale
            let height = image.size.height * scale

            Image(uiImage: image)
                .resizable()
                .frame(width: width, height: height)
                .offset(
                    x: -(width - geo.size.width) * min(max(focus, 0), 1),
                    y: -(height - geo.size.height) / 2
                )
        }
    }
}
