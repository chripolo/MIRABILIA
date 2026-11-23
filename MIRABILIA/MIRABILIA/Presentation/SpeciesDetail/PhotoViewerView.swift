//
//  PhotoViewerView.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Enlarged gallery photograph with its credit and a link to the full-size file.
struct PhotoViewerView: View {
    let photo: ObservationPhoto
    let close: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Whole photo, never cropped (required for ND licenses).
                    AsyncImage(url: photo.url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            EditorialFallbackView().aspectRatio(4 / 3, contentMode: .fit)
                        default:
                            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                        }
                    }
                    .accessibilityLabel("Enlarged photograph")

                    PhotoCredit(attribution: photo.attribution, license: photo.license)

                    if let largeURL = photo.largeURL {
                        Link(destination: largeURL) {
                            Label("Open full-size photo", systemImage: "arrow.up.right.square")
                                .font(Typography.body.weight(.semibold))
                                .frame(minHeight: Spacing.minTapTarget)
                        }
                        .foregroundStyle(Palette.accent)
                    }
                }
                .padding(Spacing.xl)
            }
            .background(Palette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                        .frame(minWidth: Spacing.minTapTarget, minHeight: Spacing.minTapTarget)
                }
            }
        }
    }
}
