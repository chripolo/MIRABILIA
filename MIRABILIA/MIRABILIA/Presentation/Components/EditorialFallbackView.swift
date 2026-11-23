//
//  EditorialFallbackView.swift
//  MIRABILIA
//
//  Created by Christian Polo on 22/11/26.
//

import SwiftUI

/// Graphic fallback shown wherever a valid photograph is not available.
/// Abstract botanical artwork on Deep Ocean; it intentionally does not
/// depict any specific organism. Fills whatever size its container offers.
struct EditorialFallbackView: View {
    /// Set to `false` when another view overlays its own text (e.g. a group tile).
    var showsCaption: Bool = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Palette.deepOcean

            BotanicalIllustration()

            if showsCaption {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Awaiting discovery")
                        .font(Typography.fallbackTitle)
                        .foregroundStyle(Palette.mist)
                    Text("NO PHOTOGRAPH AVAILABLE")
                        .font(Typography.overline)
                        .tracking(1.5)
                        .foregroundStyle(Palette.softTeal)
                }
                .padding(Spacing.lg)
            }
        }
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showsCaption ? "No photograph available. Awaiting discovery." : "")
        .accessibilityHidden(!showsCaption)
    }
}

// MARK: - Illustration

private struct BotanicalIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Circle()
                    .stroke(Palette.botanicalTeal.opacity(0.6), lineWidth: 1)
                    .frame(width: min(w, h) * 0.7)
                    .position(x: w * 0.7, y: h * 0.36)

                frond(leaves: 6, tint: Palette.botanicalTeal)
                    .frame(width: w * 0.5, height: h * 0.9)
                    .position(x: w * 0.34, y: h * 0.5)

                frond(leaves: 5, tint: Palette.sage)
                    .frame(width: w * 0.36, height: h * 0.7)
                    .position(x: w * 0.72, y: h * 0.52)
                    .scaleEffect(x: -1, y: 1)

                frond(leaves: 4, tint: Palette.moss)
                    .frame(width: w * 0.3, height: h * 0.5)
                    .position(x: w * 0.55, y: h * 0.7)
            }
        }
    }

    private func frond(leaves: Int, tint: Color) -> some View {
        ZStack {
            FrondStem().stroke(tint, lineWidth: 1.5)
            FrondLeaves(count: leaves).fill(tint.opacity(0.85))
        }
    }
}

/// Quadratic curve shared by the stem and its leaves.
private struct FrondCurve {
    let p0: CGPoint
    let p1: CGPoint
    let p2: CGPoint

    init(in rect: CGRect) {
        p0 = CGPoint(x: rect.minX + rect.width * 0.5, y: rect.maxY)
        p1 = CGPoint(x: rect.minX + rect.width * 0.1, y: rect.minY + rect.height * 0.55)
        p2 = CGPoint(x: rect.minX + rect.width * 0.62, y: rect.minY)
    }

    func point(at t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x,
            y: u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
        )
    }

    func angle(at t: CGFloat) -> CGFloat {
        let dx = 2 * (1 - t) * (p1.x - p0.x) + 2 * t * (p2.x - p1.x)
        let dy = 2 * (1 - t) * (p1.y - p0.y) + 2 * t * (p2.y - p1.y)
        return atan2(dy, dx)
    }
}

private struct FrondStem: Shape {
    func path(in rect: CGRect) -> Path {
        let curve = FrondCurve(in: rect)
        var path = Path()
        path.move(to: curve.p0)
        path.addQuadCurve(to: curve.p2, control: curve.p1)
        return path
    }
}

private struct FrondLeaves: Shape {
    let count: Int

    func path(in rect: CGRect) -> Path {
        let curve = FrondCurve(in: rect)
        var path = Path()
        guard count > 1 else { return path }

        for index in 0..<count {
            let t = 0.2 + 0.75 * CGFloat(index) / CGFloat(count - 1)
            let length = rect.width * 0.42 * (1 - 0.55 * t)
            let leaf = Self.leaf(length: length, width: length * 0.32)

            for side in [CGFloat(-1), 1] {
                let angle = curve.angle(at: t) + side * (.pi / 3.2)
                let origin = curve.point(at: t)
                let transform = CGAffineTransform(translationX: origin.x, y: origin.y)
                    .rotated(by: angle)
                path.addPath(leaf, transform: transform)
            }
        }
        return path
    }

    /// Pointed leaf: base at the origin, tip at (length, 0).
    private static func leaf(length: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: length, y: 0), control: CGPoint(x: length * 0.5, y: -width))
        path.addQuadCurve(to: .zero, control: CGPoint(x: length * 0.5, y: width))
        path.closeSubpath()
        return path
    }
}

#Preview("Fallback – wide") {
    EditorialFallbackView()
        .aspectRatio(4 / 3, contentMode: .fit)
        .padding()
}

#Preview("Fallback – tile") {
    EditorialFallbackView(showsCaption: false)
        .frame(width: 160, height: 160)
}
