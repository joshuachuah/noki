import SwiftUI

/// What the Island shows when nothing is playing (or a track has been paused
/// long enough to count as idle). Mirrors `PeekView`'s layout so the two
/// slots read the same way: the left one becomes artwork and the right one
/// becomes the live visualizer the moment music starts.
struct IdleView: View {
    private let tint = Color.white.opacity(0.35)

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "moon.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 32)

            Spacer(minLength: 0)

            Visualizer(isPlaying: false, accent: tint)
                .frame(width: 11.5, height: 11)
                .frame(width: 28, height: 32)
        }
        .frame(width: 252, height: 32)
        .accessibilityHidden(true)
    }
}
