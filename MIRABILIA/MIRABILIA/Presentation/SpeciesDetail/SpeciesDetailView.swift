//
//  SpeciesDetailView.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

struct SpeciesDetailView: View {
    @StateObject private var viewModel: SpeciesDetailViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm, alignment: .top), count: 3)

    init(viewModel: SpeciesDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var taxon: Taxon { viewModel.taxon }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                hero
                identity
                gallerySection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadGallery() }
        .sheet(item: Binding(
            get: { viewModel.selectedPhoto },
            set: { if $0 == nil { viewModel.dismissPhoto() } }
        )) { photo in
            PhotoViewerView(photo: photo) { viewModel.dismissPhoto() }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let photo = taxon.photo {
                RemotePhoto(url: photo.url, license: photo.license)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .accessibilityLabel("Photograph of \(taxon.commonName ?? taxon.scientificName)")
                PhotoCredit(attribution: photo.attribution, license: photo.license)
            } else {
                EditorialFallbackView()
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    // MARK: Identity

    private var identity: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let group = taxon.group {
                Text(group.title.uppercased())
                    .font(Typography.overline)
                    .tracking(1.5)
                    .foregroundStyle(Palette.accent)
            }

            Text(taxon.commonName ?? taxon.scientificName)
                .font(Typography.display)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if taxon.commonName != nil {
                Text(taxon.scientificName)
                    .font(Typography.sectionTitle.italic())
                    .foregroundStyle(Palette.textSecondary)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                fact("Rank", taxon.rank.capitalized)
                fact("Observations", taxon.observationsCount.formatted())
            }
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fact(_ label: String, _ value: String) -> some View {
        // Side by side when there is room; stacked at large Dynamic Type sizes.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                factLabel(label)
                Spacer(minLength: Spacing.md)
                factValue(value)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                factLabel(label)
                factValue(value)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func factLabel(_ label: String) -> some View {
        Text(label.uppercased())
            .font(Typography.overline)
            .tracking(1.5)
            .foregroundStyle(Palette.textSecondary)
    }

    private func factValue(_ value: String) -> some View {
        Text(value)
            .font(Typography.body)
            .foregroundStyle(Palette.textPrimary)
    }

    // MARK: Gallery

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Gallery")
                .font(Typography.sectionTitle)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)

            switch viewModel.gallery {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .accessibilityLabel("Loading gallery")
            case .loaded(let photos):
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(photos) { photo in
                        galleryCell(photo)
                    }
                }
            case .empty:
                message("No additional photographs available.")
            case .failed:
                VStack(spacing: Spacing.md) {
                    message("The gallery could not be loaded.")
                    Button("Try again") { Task { await viewModel.reloadGallery() } }
                        .font(Typography.body.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                        .frame(minWidth: Spacing.minTapTarget, minHeight: Spacing.minTapTarget)
                }
            }
        }
    }

    private func galleryCell(_ photo: ObservationPhoto) -> some View {
        Button { viewModel.select(photo) } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                RemotePhoto(url: photo.url, license: photo.license)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                PhotoCredit(attribution: photo.attribution, license: photo.license, lineLimit: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cellLabel(photo))
        .accessibilityHint("Opens the enlarged photograph")
    }

    private func cellLabel(_ photo: ObservationPhoto) -> String {
        ["Photograph", photo.attribution, PhotoLicense.displayName(photo.license)]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(Typography.body)
            .foregroundStyle(Palette.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 80)
    }
}
