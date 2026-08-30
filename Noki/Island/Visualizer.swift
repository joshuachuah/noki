import SwiftUI

struct Visualizer: View {
    let isPlaying: Bool
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let phaseOffsets = [0.0, 1.8, 3.7]

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1 / 20,
                paused: !isPlaying || reduceMotion
            )
        ) { timeline in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(phaseOffsets.indices, id: \.self) { index in
                    Capsule()
                        .fill(accent)
                        .frame(
                            width: 2.5,
                            height: barHeight(index: index, date: timeline.date)
                        )
                }
            }
            .frame(height: 11, alignment: .bottom)
        }
    }

    private func barHeight(index: Int, date: Date) -> CGFloat {
        guard isPlaying, !reduceMotion else { return 2.2 }
        let elapsed = date.timeIntervalSinceReferenceDate
        let wave = (sin(elapsed * 9 + phaseOffsets[index]) + 1) / 2
        return 2.2 + wave * 8.8
    }
}

