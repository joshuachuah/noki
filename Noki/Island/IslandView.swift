import SwiftUI

struct IslandView: View {
    @Bindable var model: IslandModel
    @Bindable var pinStore: PinStore
    let spotify: Spotify
    var onHitRegionChange: (IslandHitRegion) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var size: CGSize {
        model.state.size(hasNowPlaying: model.nowPlaying != nil)
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
            .background {
                IslandHitRegionReporter(
                    size: size,
                    cornerRadius: cornerRadius,
                    onChange: onHitRegionChange
                )
            }
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
}

/// Interpolates with the frame's spring, rather than reporting only its destination size.
private struct IslandHitRegionReporter: View, Animatable {
    nonisolated var size: CGSize
    let cornerRadius: CGFloat
    let onChange: (IslandHitRegion) -> Void

    nonisolated var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(size.width, size.height) }
        set { size = CGSize(width: newValue.first, height: newValue.second) }
    }

    private var region: IslandHitRegion {
        IslandHitRegion(
            frame: CGRect(
                x: (392 - size.width) / 2,
                y: 0,
                width: size.width,
                height: size.height
            ),
            cornerRadius: cornerRadius
        )
    }

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onChange(of: region, initial: true) { _, newRegion in
                onChange(newRegion)
            }
    }
}

/// The displayed outline in the panel's top-left coordinate space, including its flares.
struct IslandHitRegion: Equatable {
    let frame: CGRect
    let cornerRadius: CGFloat

    func contains(_ point: CGPoint) -> Bool {
        IslandShape(cornerRadius: cornerRadius).path(in: frame).contains(point)
    }
}

/// The Island's outline: rounded bottom corners and top corners that flare
/// outward like the Notch. The flares sit outside `rect`, so the panel is wider by `flareRadius` per side.
struct IslandShape: Shape {
    static let flareRadius: CGFloat = 6

    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let flare = Self.flareRadius
        let radius = min(cornerRadius, rect.width / 2, rect.height - flare)

        // SwiftUI's coordinate space is flipped, so `clockwise` here means the opposite on screen.
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
