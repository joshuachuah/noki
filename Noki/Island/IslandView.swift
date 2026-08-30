import SwiftUI

struct IslandView: View {
    @Bindable var model: IslandModel
    @Bindable var pinStore: PinStore
    let spotify: Spotify

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var size: CGSize {
        switch model.state {
        case .hidden: CGSize(width: 200, height: 32)
        case .peek: CGSize(width: 252, height: 32)
        case .expanded: CGSize(width: 540, height: 100)
        }
    }

    private var cornerRadius: CGFloat {
        switch model.state {
        case .hidden: 12
        case .peek: 14
        case .expanded: 24
        }
    }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: cornerRadius,
            bottomTrailingRadius: cornerRadius,
            topTrailingRadius: 0
        )
    }

    // Content waits for the shape to grow before fading in, but leaves
    // immediately on collapse so nothing lingers while the shape shrinks.
    private var contentAnimation: Animation {
        model.state == .expanded
            ? .easeOut(duration: 0.18).delay(0.12)
            : .easeOut(duration: 0.1)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                shape.fill(model.state == .hidden ? Color.clear : .black)

                content
                    .opacity(model.state == .hidden ? 0 : 1)
                    .animation(contentAnimation, value: model.state)
            }
            .frame(width: size.width, height: size.height)
            // Clip so Expanded content never draws past the black shape while
            // it is still shrinking down to Peek.
            .clipShape(shape)
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
        .frame(width: 550, height: 110)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .hidden:
            Color.clear
        case .peek:
            if let nowPlaying = model.nowPlaying {
                PeekView(
                    nowPlaying: nowPlaying,
                    spotify: spotify,
                    expand: model.pointerEntered
                )
            }
        case .expanded:
            ExpandedView(
                nowPlaying: model.nowPlaying,
                pins: pinStore.pins,
                pinLoadError: pinStore.loadError,
                spotify: spotify,
                editPins: pinStore.openInDefaultEditor
            )
        }
    }

    /// Hidden and Expanded use the whole visible shape as a hover target.
    /// Peek owns its three smaller targets so artwork and playback controls
    /// do not open the Island.
    private func updateShapeHover(_ hovering: Bool) {
        guard model.state != .peek else { return }

        if hovering {
            if model.nowPlaying == nil { pinStore.reload() }
            model.pointerEntered()
        } else {
            model.pointerExited()
        }
    }
}
