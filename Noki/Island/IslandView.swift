import SwiftUI

struct IslandView: View {
    @Bindable var model: IslandModel
    @Bindable var pinStore: PinStore
    let spotify: Spotify

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var size: CGSize {
        switch model.state {
        case .hidden: CGSize(width: 252, height: 32)
        case .peek: CGSize(width: 252, height: 32)
        case .expanded:
            model.nowPlaying == nil
                ? CGSize(width: 380, height: 100)
                : CGSize(width: 380, height: 220)
        }
    }

    private var cornerRadius: CGFloat {
        switch model.state {
        case .hidden: 14
        case .peek: 14
        case .expanded: model.nowPlaying == nil ? 24 : 28
        }
    }

    private var shape: IslandShape {
        IslandShape(cornerRadius: cornerRadius)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                shape
                    .fill(.black)

                content
                    .frame(width: size.width, height: size.height, alignment: .top)
                    .clipShape(shape)
            }
            .frame(width: size.width, height: size.height)
            .contentShape(shape)
            .onHover(perform: updateShapeHover)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : .spring(response: 0.38, dampingFraction: 0.7),
                value: model.state
            )

            Spacer(minLength: 0)
        }
        .frame(width: 380 + IslandShape.flareRadius * 2, height: 220)
    }

    @ViewBuilder
    private var content: some View {
        ZStack(alignment: .top) {
            if model.state == .hidden {
                IdleView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeOut(duration: 0.12).delay(0.08)),
                            removal: .opacity.animation(.easeOut(duration: 0.08))
                        )
                    )
            }

            if model.state == .peek, let nowPlaying = model.nowPlaying {
                PeekView(nowPlaying: nowPlaying, spotify: spotify)
                .transition(
                    .asymmetric(
                        insertion: .opacity.animation(.easeOut(duration: 0.12).delay(0.08)),
                        removal: .opacity.animation(.easeOut(duration: 0.08))
                    )
                )
            }

            if model.state == .expanded {
                ExpandedView(
                    nowPlaying: model.nowPlaying,
                    pins: pinStore.pins,
                    pinLoadError: pinStore.loadError,
                    spotify: spotify,
                    editPins: pinStore.openInDefaultEditor
                )
                .allowsHitTesting(model.state == .expanded)
                .transition(
                    .asymmetric(
                        insertion: .opacity.animation(.easeOut(duration: 0.18).delay(0.12)),
                        removal: .opacity.animation(.easeOut(duration: 0.08))
                    )
                )
            }
        }
    }

    /// Leaving the shape closes the Island in every state. Entering it opens
    /// the Island in Hidden and Expanded only. In Peek the Notch itself is the
    /// open target (see `IslandPanelController`), so the artwork and playback
    /// buttons at the Island's edges stay clickable.
    private func updateShapeHover(_ hovering: Bool) {
        if hovering {
            guard model.state != .peek else { return }
            if model.nowPlaying == nil { pinStore.reload() }
            model.pointerEntered()
        } else {
            model.pointerExited()
        }
    }
}

/// The Island's outline. The bottom corners are rounded like a pill. The top
/// corners flare outward into the menu bar, the way the physical Notch does,
/// so the Island reads as part of the Notch instead of a box hanging under it.
/// The flares are drawn outside `rect`, so the panel is `flareRadius` wider on
/// each side than the Island body.
///
/// Keeps the corner radius out of SwiftUI's spring while the frame resizes.
private struct IslandShape: Shape {
    static let flareRadius: CGFloat = 6

    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let flare = Self.flareRadius
        let radius = min(cornerRadius, rect.width / 2, rect.height - flare)

        // SwiftUI's `addArc` runs in a flipped coordinate space, so
        // `clockwise: false` draws clockwise on screen and vice versa.
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - flare, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.minX - flare, y: rect.minY + flare),
            radius: flare,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + flare))
        path.addArc(
            center: CGPoint(x: rect.maxX + flare, y: rect.minY + flare),
            radius: flare,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
