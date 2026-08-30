import SwiftUI

struct Visualizer: View {
    enum Style {
        case peek
        case expanded

        var phaseOffsets: [Double] {
            switch self {
            case .peek: [0.0, 1.8, 3.7]
            case .expanded: [0.0, 1.3, 2.6, 3.9, 5.2]
            }
        }

        var barWidth: CGFloat { self == .peek ? 2.5 : 3 }
        var spacing: CGFloat { self == .peek ? 2 : 2.5 }
        var height: CGFloat { self == .peek ? 11 : 18 }
    }

    let isPlaying: Bool
    let accent: Color
    var style: Style = .peek

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1 / 20,
                paused: !isPlaying || reduceMotion
            )
        ) { timeline in
            HStack(alignment: .bottom, spacing: style.spacing) {
                ForEach(style.phaseOffsets.indices, id: \.self) { index in
                    Capsule()
                        .fill(accent)
                        .frame(
                            width: style.barWidth,
                            height: barHeight(index: index, date: timeline.date)
                        )
                }
            }
            .frame(height: style.height, alignment: .bottom)
        }
    }

    private func barHeight(index: Int, date: Date) -> CGFloat {
        guard isPlaying, !reduceMotion else { return style.height * 0.2 }
        let elapsed = date.timeIntervalSinceReferenceDate
        let minimumHeight = style.height * 0.2
        let wave = (sin(elapsed * 9 + style.phaseOffsets[index]) + 1) / 2
        return minimumHeight + wave * style.height * 0.8
    }
}
