//
//  TourOverlayView.swift
//  KeynoteCompanionMacos
//
//  Renders the active tour step: a neutral dim with a crisp, lifted spotlight cut-out
//  over the target control, plus a native-popover-style callout (rounded card with a
//  directional beak). The cut-out's `contentShape` excludes the hole, so the highlighted
//  control stays tappable through it while the rest of the window is blocked.
//

import SwiftUI

struct TourOverlayView: View {
    @ObservedObject var controller: TourController
    let anchors: [TourStep: Anchor<CGRect>]
    let proxy: GeometryProxy

    @State private var calloutSize: CGSize = .zero

    private enum Metrics {
        static let spotlightPadding: CGFloat = 8
        static let liftShadowWidth: CGFloat = 3
        static let liftShadowBlur: CGFloat = 4
        static let calloutWidth: CGFloat = 300
        static let calloutCornerRadius: CGFloat = 20
        static let beakWidth: CGFloat = 24
        static let beakHeight: CGFloat = 11
        static let beakGap: CGFloat = 6
        static let screenMargin: CGFloat = 16
    }

    var body: some View {
        if let step = controller.activeStep, let anchor = anchors[step] {
            content(step: step, target: proxy[anchor])
        }
    }

    private func content(step: TourStep, target: CGRect) -> some View {
        let size = proxy.size
        let hole = spotlightRect(for: target, in: size)
        let cornerRadius = step.spotlightShape.cornerRadius(for: hole.size)
        let cardCenterX = calloutCenterX(for: target, in: size)
        let beakCenterX = target.midX - (cardCenterX - Metrics.calloutWidth / 2)
        let cardCenter = calloutCenter(
            step: step,
            target: target,
            centerX: cardCenterX
        )

        return ZStack(alignment: .topLeading) {
            spotlightScrim(hole: hole, cornerRadius: cornerRadius)

            callout(step: step, beakCenterX: beakCenterX)
                .frame(width: Metrics.calloutWidth)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { calloutSize = $0 }
                .position(cardCenter)
                .opacity(calloutSize == .zero ? 0 : 1)
        }
        .animation(.smooth(duration: 0.3), value: controller.activeStep)
    }

    // MARK: - Spotlight (crisp cut-out + subtle lift shadow)

    private func spotlightScrim(hole: CGRect, cornerRadius: CGFloat) -> some View {
        Rectangle()
            .fill(AppColor.scrim)
            .reverseMask {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
            }
            .overlay {
                // Soft halo hugging the crisp hole so the control reads as lifted.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColor.shadow, lineWidth: Metrics.liftShadowWidth)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
                    .blur(radius: Metrics.liftShadowBlur)
                    .allowsHitTesting(false)
            }
            // Hittable everywhere except the hole, so the control underneath receives taps.
            .contentShape(
                SpotlightCutoutShape(hole: hole, cornerRadius: cornerRadius),
                eoFill: true
            )
            .onTapGesture {}
    }

    // MARK: - Callout (native popover look with a beak)

    private func callout(step: TourStep, beakCenterX: CGFloat) -> some View {
        let placement = step.calloutPlacement

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: step.iconSystemName)
                    .font(AppFont.sizeIcon)
                    .foregroundStyle(AppColor.iconPrimary)
                    .frame(width: AppSpacing.xxl)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(step.title)
                        .font(AppFont.onboardingFeatureTitle)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(step.message)
                        .font(AppFont.settingDescription)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            Button {
                controller.skipCurrent()
            } label: {
                Text(step.actionTitle)
                    .font(step.isFinalStep ? AppFont.primaryButton : AppFont.button)
                    .foregroundStyle(
                        step.isFinalStep ? AppColor.textPrimary : AppColor.textTertiary
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.lg)
        // Reserve space for the beak on the side facing the target.
        .padding(placement == .above ? .bottom : .top, Metrics.beakHeight)
        .background(
            CalloutShape(
                cornerRadius: Metrics.calloutCornerRadius,
                placement: placement,
                beakCenterX: beakCenterX,
                beakWidth: Metrics.beakWidth,
                beakHeight: Metrics.beakHeight
            )
            .fill(AppColor.cardSurface)
            .shadow(color: AppColor.shadow, radius: 18, x: 0, y: 8)
        )
    }

    // MARK: - Geometry helpers

    private func spotlightRect(for target: CGRect, in size: CGSize) -> CGRect {
        target
            .insetBy(dx: -Metrics.spotlightPadding, dy: -Metrics.spotlightPadding)
            .intersection(CGRect(origin: .zero, size: size))
    }

    private func calloutCenterX(for target: CGRect, in size: CGSize) -> CGFloat {
        let halfWidth = Metrics.calloutWidth / 2
        return min(
            max(target.midX, Metrics.screenMargin + halfWidth),
            size.width - Metrics.screenMargin - halfWidth
        )
    }

    private func calloutCenter(
        step: TourStep,
        target: CGRect,
        centerX: CGFloat
    ) -> CGPoint {
        let halfHeight = calloutSize.height / 2
        switch step.calloutPlacement {
        case .above:
            // Frame bottom (where the beak tip is) sits just above the target.
            return CGPoint(
                x: centerX,
                y: target.minY - Metrics.beakGap - halfHeight
            )
        case .below:
            return CGPoint(
                x: centerX,
                y: target.maxY + Metrics.beakGap + halfHeight
            )
        }
    }
}

/// Outer rect plus a rounded hole; with `eoFill` the hole is excluded from the fill,
/// which (as a `contentShape`) makes the hole transparent to hit-testing.
private struct SpotlightCutoutShape: Shape {
    let hole: CGRect
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(
            in: hole,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
            style: .continuous
        )
        return path
    }
}

/// A rounded-rect card with a beak on the edge facing the target, drawn as one path so the
/// fill and shadow are seamless (the native-popover look).
private struct CalloutShape: Shape {
    let cornerRadius: CGFloat
    let placement: CalloutPlacement
    let beakCenterX: CGFloat
    let beakWidth: CGFloat
    let beakHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var bodyRect = rect
        switch placement {
        case .above:
            bodyRect.size.height -= beakHeight
        case .below:
            bodyRect.origin.y += beakHeight
            bodyRect.size.height -= beakHeight
        }

        var path = Path(
            roundedRect: bodyRect,
            cornerRadius: cornerRadius,
            style: .continuous
        )

        let halfBeak = beakWidth / 2
        let cx = min(
            max(beakCenterX, bodyRect.minX + cornerRadius + halfBeak),
            bodyRect.maxX - cornerRadius - halfBeak
        )

        var beak = Path()
        switch placement {
        case .above:
            beak.move(to: CGPoint(x: cx - halfBeak, y: bodyRect.maxY))
            beak.addLine(to: CGPoint(x: cx, y: bodyRect.maxY + beakHeight))
            beak.addLine(to: CGPoint(x: cx + halfBeak, y: bodyRect.maxY))
        case .below:
            beak.move(to: CGPoint(x: cx - halfBeak, y: bodyRect.minY))
            beak.addLine(to: CGPoint(x: cx, y: bodyRect.minY - beakHeight))
            beak.addLine(to: CGPoint(x: cx + halfBeak, y: bodyRect.minY))
        }
        beak.closeSubpath()
        path.addPath(beak)
        return path
    }
}

private extension View {
    /// Masks `self`, cutting out the region drawn by `mask` (inverse of `.mask`).
    func reverseMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: .topLeading) {
                    mask().blendMode(.destinationOut)
                }
        }
    }
}
