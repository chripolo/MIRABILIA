//
//  SearchField.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Search field UI. It only edits the bound text; the owner decides what to do with it.
struct SearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.textSecondary)
                .accessibilityHidden(true)

            TextField(
                "Search species",
                text: $text,
                prompt: Text("Search species").foregroundStyle(Palette.textPrimary.opacity(0.7))
            )
            .font(Typography.body)
            .foregroundStyle(Palette.textPrimary)
            .tint(Palette.accent)
            .submitLabel(.search)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused(isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: Spacing.minTapTarget, height: Spacing.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, Spacing.md)
        .padding(.trailing, text.isEmpty ? Spacing.md : 0)
        .frame(minHeight: Spacing.minTapTarget)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Palette.hairline.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    struct Host: View {
        @State private var text = "Apis"
        @FocusState private var focused: Bool

        var body: some View {
            SearchField(text: $text, isFocused: $focused)
                .padding()
                .background(Palette.background)
        }
    }
    return Host()
}
